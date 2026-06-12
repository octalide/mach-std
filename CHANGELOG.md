# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `std.process.exec.capture(pathname, argv, envp, buf, cap) Result[Capture, str]`
  — run a child and collect its stdout into `buf`, draining the pipe to EOF so a
  child outproducing the buffer never blocks; always reports the full output
  length, so `len > cap` signals truncation (raw bytes, no terminator slot — a
  `len == cap` capture is complete, unlike `env.get` whose boundary is
  `ret >= cap`). Backed by a new `std.system.os.spawn_redirected(pathname,
  argv, envp, stdin_fd, stdout_fd, stderr_fd)` stdio-redirection primitive
  (fork + per-stream dup2 + exec, -1 inheriting the parent's stream; child
  exits 126 on redirect failure, 127 on exec failure) on linux and darwin,
  onto which `spawn` now collapses (#188, capture half).
- Native windows exec backend: `spawn`/`spawn_redirected`/`run`/`capture`
  over `CreateProcessA` + `WaitForSingleObject` + `GetExitCodeProcess`, with
  argv joined per the windows command-line quoting rules (a joined line over
  the 32 KiB limit fails with `E2BIG` instead of truncating), `envp` mapped
  to a CreateProcess environment block (nil inherits), and stdio redirection
  via `STARTF_USESTDHANDLES` with inheritance scoped to exactly the child's
  std handles through `PROC_THREAD_ATTRIBUTE_HANDLE_LIST` (inherit flags are
  restored after the spawn, so concurrent spawns cannot leak pipe ends into
  unrelated children; a spawn with no redirection inherits the parent's
  streams natively). The read path treats a broken anonymous pipe as EOF so
  `capture` drains cleanly. `environ()` is now populated from
  `GetEnvironmentStrings` (hidden `=X:` drive-cwd entries excluded) rather
  than always nil (#221, #188 windows half). `os.WNOHANG` is now forwarded
  portably alongside `wait`/`wait_pid`.

### Fixed

- darwin `fork()` now reads the XNU child-indicator register (rdx on
  x86_64, x1 on aarch64) and returns 0 in the child instead of the child
  PID, so `spawn`/`spawn_redirected` take the exec path in the child rather
  than duplicating the parent program (#232).
- darwin `vfork()` reads the same XNU child-indicator register as `fork()` and
  returns 0 in the child instead of the child PID, fixing the identical
  child-indicator bug in the previously plain `syscall0` wrapper (#234).

## [0.6.0] - 2026-06-12

Bug-clearing release: all three known-failing tests are fixed for real (thread
clone race, json key lookup, env PATH harness dependency), and the environment
vector is now accessible. The thread fix required a breaking `spawn` signature
change, hence the minor bump.

### Added

- `std.process.env.environ() **u8` — the captured environment vector (`_envp`),
  forwarded through every OS layer next to `getenv`; documented always-nil on
  windows until a windows environment-block reader exists (#188, accessor half).
- `std.data.json.value_key_len(v, index) usize` — byte length of an object key,
  parallel to `value_key` (#196).

### Changed

- **BREAKING**: `std.sync.thread.spawn(f: fun()) Thread` is now
  `spawn(f: fun(), t: *Thread)`. The handle is caller-owned and initialized in
  place: the child thread writes its completion flag through the handle, so the
  record must live at a stable address for the thread's lifetime — a by-value
  return handed the child the address of a dead frame and made `join` wait
  forever (#195).
- json object keys keep their byte lengths (`keys_len` parallel array);
  `value_find` compares length-bounded and key emission uses the stored length
  instead of assuming null termination. `value_key` is documented as
  non-null-terminated (#196).
- the `env: get PATH` test is harness-independent: it asserts termination and
  repeatability when PATH is inherited instead of requiring an inherited
  environment the test harness does not currently provide (#197).

### Fixed

- thread spawn/join no longer deadlocks: parent/child discrimination after
  `clone` happens entirely in registers (the child jumps straight to the
  trampoline), eliminating the shared-stack-slot race under `CLONE_VM` (#195).
- `json.value_find` matches keys again — lookups previously failed for every
  key because non-terminated key slices were compared null-terminated (#196).

## [0.5.0] - 2026-06-12

Manifest migrated to the v1.4.0 format and windows link requirements declared
once via the os overlay, plus the memory/string primitives added since 0.4.2.

### Added

- `std.memory.raw_equal(a, b: ptr, n: usize) bool` — allocation-free byte-wise memory
  comparison with documented nil contract (n==0 vacuously true; equal pointers trivially
  true; one-sided nil with n>0 is false) (#204).
- `std.memory.equal[T](a, b: *T, n: usize) bool` — typed wrapper over `raw_equal` (#204).
- `std.types.string.view_index_char(v: StrView, c: char) Result[usize, str]` — first
  occurrence of a character within a view (#204).
- `std.types.string.view_contains_char(v: StrView, c: char) bool` — membership test
  delegating to `view_index_char` (#204).
- `[os.windows] libs = ["kernel32.dll"]` os overlay — std's windows runtime link
  requirement, declared once and cascaded to every windows consumer build via the
  v1.4.0 manifest os-component overlay.

### Changed

- `mach.toml` converted to the v1.4.0 manifest schema: `dir_src`/`dir_out`/`dir_dep`
  become `src`/`dep` plus explicit `out`/`obj`/`ir`/`asm`/`tests` path templates;
  `[targets.linux]` becomes `[target.linux]`; the library `mode = "library"` /
  `entrypoint = "lib.mach"` pair becomes `[lib.std] entry = "lib.mach" kind = "static"`.
  v1.4.0 reads only this format.
- `data/toml`: internal `str_eq_n` removed; call site migrated to `memory.raw_equal`
  (behavioral match: both are byte-wise n-byte comparisons over `str = *char = *u8`) (#204).

## [0.4.3] - 2026-06-11

Patch release: process exit now terminates all threads on linux.

### Fixed

- `_start` (linux x86_64) and the linux OS-layer process-exit paths
  (`terminate`, backing `process.exec.exit`/`abort`/panic, and the spawn
  child's exec-failure exit) used `SYS_exit`, which ends only the calling
  thread — any program with a live non-main thread hung after `main`
  returned. All process exits now use `SYS_exit_group`; thread exits keep
  `SYS_exit`. darwin (`exit` ends the whole task) and windows
  (`ExitProcess`) were already correct (#205).

## [0.4.2] - 2026-06-10

Patch release: SysV stack-alignment fix in the program entrypoint.

### Fixed

- `_start` (linux and darwin x86_64) entered every callee with an 8-byte
  misaligned stack, violating the SysV call invariant — invisible to pure-Mach
  programs but a SIGSEGV for any C callee using aligned SSE accesses (#200).

## [0.4.1] - 2026-06-10

First tagged release carrying the 0.3.0 and 0.4.0 work (neither was tagged);
`main` advances from 0.2.5 straight to 0.4.1.

### Fixed
- Corrected the expected length in the `ip: ipv4_format` test — a single-octet
  address such as `127.0.0.1` formats to 9 bytes, not 7. The function was
  correct; only the test assertion was wrong.

### Known Issues
These tests fail or hang under `mach test` and are tracked for follow-up. All
three are gaps in modules added during the 0.4.x rework (after 0.2.5), not
regressions:
- `thread: spawn and join` / `thread: is_done after join` deadlock — the clone
  parent/child discrimination is a shared-memory race ([#195](https://github.com/octalide/mach-std/issues/195)).
- `json: value_find on object` never matches — object keys are stored as
  non-null-terminated source slices but compared with `str_equals` ([#196](https://github.com/octalide/mach-std/issues/196)).
- `env: get PATH returns positive length` — the std code is correct; `mach test`
  execs the test binary with an empty environment ([#197](https://github.com/octalide/mach-std/issues/197)).

## [0.4.0] - 2026-03-10

### Added
- Multi-target OS layer with darwin (x86_64, aarch64) and windows (x86_64) backends
- Socket primitives in the OS layer (sock_create, sock_bind, sock_listen, sock_accept, sock_connect, sock_sendto, sock_recvfrom, sock_shutdown, sock_setopt)
- OS-level random_fill primitive (getrandom on linux, getentropy on darwin, RtlGenRandom on windows)
- Thread primitives for darwin (bsdthread_create, ulock) and windows (CreateThread, WaitOnAddress)
- aarch64 atomic backend (ldaxr/stlxr)
- New modules: chrono, encoding (hex, base64), format, io (buffer, reader, writer), log, math, process (args, env, exec), rand (xoshiro256**)
- New collection types: bitset, deque, heap, set, sort
- Page allocator, char type, utf8 module, json parser, crypto/hash (sha256, sha512)
- Platform-specific runtime modules for linux, darwin, and windows

### Changed
- Restructured OS layer: extracted constants into per-ISA files, added shared.mach for cross-platform values, proper forwarding chains through ISA → OS → os.mach
- Removed non-portable symbols from os.mach surface (syscall wrappers, CLOCK_*, wait flags, EINTR_MAX_RETRIES, huge page sizes)
- Rewrote crypto/rand to use os.random_fill — eliminated OS-specific backend
- Rewrote net/tcp, net/udp, net/dns to use OS layer socket primitives — eliminated OS-specific backends
- Eliminated thread globals on all platforms (stack-based parameter passing on linux, lpParameter on windows)
- Updated core types, allocator, collections, memory, print, and filesystem modules

### Removed
- Legacy platform/ abstraction layer (replaced by system/os/)
- Superseded modules: fmt, stream, time, text/ascii, text/builder, text/buffer_writer, types/int, io/bytebuf

## [0.3.0] - 2025-11-18

### Added
- `std.collections` with new `Slice` type for safer array/slice handling
- Added `std.os` and `std.arch` modules and implementations for platform/architecture detection
- Introduced readonly pointers.

### Changed
- Complete rework of most modules to be up to date with latest Mach language features including readonly pointers, the removal of slices, and the new native `str` type.
- Complete rework of the fundamental structure of the standard library.
- Too many to reasonably count.

### Fixed
- Several bugs across all modules.

## [0.2.5] - 2025-11-17

### Fixed
- Corrected import and syntax errors in `semver.mach`
- Fixed `Path` cloning function to properly initialize `Path` struct from cloned `String`
  - NOTE: This fix addresses an issue where the previous implementation *correctly* cast a `String` to a `Path`. `Path` is an alias for `String`, so this should be allowed, but was causing sema errors. Patch for now.

## [0.2.4] - 2025-11-17

### Added
- Added `Semver` type and parsing functions in `src/types/semver.mach`

## [0.2.3] - 2025-11-17

### Changed
- Removed `list_new` function in favor of direct `List` initialization with error handling via `Option`.

## [0.2.2] - 2025-11-17

### Changed
- Migrated the dedicated compiler modules into the main `mach` repository for separation of concerns.

### Fixed
- Stabilized `List` initialization and deallocation to avoid dangling state during collection reuse.

## [0.2.1] - 2025-11-15

### Fixed
- Updated OS conditional checks to use '$mach.build.target.os' for platform-specific imports

## [0.2.0] - 2025-11-15

### Changed
- Moved runtime logic to new system/runtime.mach file and updated imports accordingly

## [0.1.1] - 2025-11-15

### Fixed
- Removed unnecessary dereference operator in realtime_timespec function for windows
- Added missing import for std.types.size and updated function signature for get_system_time_as_file_time for windows
- Standardized import formatting and added missing syscall constants for darwin

## [0.1.0] - 2025-11-15

### Added
- Initial release of mach-std as a standalone standard library
- Core type system with List, Option, Result, and String types
- Platform-specific runtime support for Linux, Darwin, and Windows
- System modules including memory management, time, and environment handling
- I/O modules for console, filesystem, and path operations
- Text processing utilities (ASCII, parsing)
- Data serialization support (JSON, TOML)
- Cryptographic hashing functionality
- Language tooling modules (lexer, parser, AST, compiler driver)
- Cross-platform system call abstractions
- Memory manipulation functions (memset, memcpy)
- Runtime entry points and panic mechanisms for all supported platforms

### Changed
- Migrated from main mach repository to dedicated mach-std repository
- Standardized string type usage to `String` across the codebase
- Refactored function naming for consistency (e.g., `length` to `len`)
- Updated to use instance method syntax for string formatting
- Improved error handling patterns with Result and Option types
- Enhanced platform-specific implementations for better consistency

### Fixed
- String handling in format functions with proper pointer dereferencing
- Environment variable retrieval to use direct file reading on Linux
- UTF-16 to UTF-8 conversion for Windows argument handling
- Conditional compilation directives for platform-specific code

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

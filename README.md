# mach-std build (cmach)

This Makefile builds the standard library using the `cmach` compiler from the sibling `mach-c` repository.

## prerequisites
- `mach-c` built at `../mach-c/bin/cmach` (or set `CMACH` to your path)

## build
```bash
# from mach-std directory
make
```
Artifacts:
- Static library: `out/lib/libmachstd.a`
- Objects: `out/obj/**/*.o`

## options
- `OPT` (default `2`): optimization level (0–3)
- `CMACH`: path to the compiler (default `../mach-c/bin/cmach`)

## clean
```bash
make clean
```

## link example
When building your program with `cmach`, pass `-I src -M std=src` to resolve `std.*` modules and link with `out/lib/libmachstd.a`:
```bash
# compile your app to object
../mach-c/bin/cmach build app.mach --emit-obj -O2 -I src -M std=src -o app.o
# link with the std library
cc -o app app.o out/lib/libmachstd.a
```
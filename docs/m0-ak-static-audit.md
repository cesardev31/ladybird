# M0 Static Audit — `AK` at Pinned Commit `d297a26ac4eabaa58030b82bb57a0ccc27767c3f`

Status: **static read-only audit** (2026-11-25). No builds, no toolchain downloads, no upstream C++ edits.

## 1. `.note.cairn` ABI Version (`0.3` vs `0.15`) & Smoke Scope

- `../cairn/user/user.ld` emits `.note.cairn` with `SHORT(0) SHORT(3)` (`0.3`).
- `../cairn/libs/abi/lib.tarn:106` defines `compatible(major, minor) = (major == ABI_MAJOR && minor <= ABI_MINOR)` with `ABI_MAJOR = 0`, `ABI_MINOR = 15`. Thus `0.3` is accepted by the loader (`3 <= 15`).
- **Contract rule**: Do **not** blindly copy `0.3` into future workers without justification. Each worker's `.note.cairn` must declare the **actual minimum ABI minor version** of the contracts it uses (e.g. `SYS_EXIT`/`SYS_VM_MAP`/`SYS_VM_UNMAP` are `v0.1+`, whereas `PROC_SPAWN_IMAGE` or IPC permits require `v0.4+`/`v0.5+`+).
- **Honest smoke status**: `cairn_native_smoke.elf` has **only** been compiled and inspected on the host (`ET_EXEC`, `entry=0x400000`, `PT_NOTE CAIRN\0 00000300`, `0` undefined symbols). It has **not** yet proved guest startup, `SYS_VM_MAP`/write/`SYS_VM_UNMAP`, quota denial, or exit status in QEMU.

## 2. Upstream Compiler Flags & Toolchain Requirements (`AK`)

Verified directly in `Meta/CMake/compile_options.cmake` and `AK/CMakeLists.txt`:
- **C++ Standard**: C++23 (`CMAKE_CXX_STANDARD 23`, `CMAKE_CXX_STANDARD_REQUIRED ON`, `CMAKE_CXX_EXTENSIONS OFF`).
- **Exceptions**: Disabled (`-fno-exceptions` in `Meta/CMake/compile_options.cmake:118`).
- **Generated Config Headers** (must be generated into a build include dir before compiling any `AK/*.cpp`):
  - `AK/Debug.h` from `AK/Debug.h.in` (`#cmakedefine01` flags -> `0`).
  - `AK/Backtrace.h` from `AK/Backtrace.h.in` (`#undef Backtrace_FOUND` when backtrace is absent).

## 3. Upstream Dependencies of `AK` (`AK/CMakeLists.txt` & `vcpkg.json`)

`vcpkg.json` pins `"builtin-baseline": "944dee83774536dd280cf459f41989584b9ef86a"`. `AK/CMakeLists.txt` links/includes:
- `simdutf::simdutf` (included directly in `AK/StringView.cpp:18` via `#include <simdutf.h>`).
- `FastFloat::fast_float` (`fast-float` in `vcpkg.json`).
- `zmij::zmij`.
- `mimalloc`.
- `LLVM_LIBC_INCLUDE_DIR/llvm-libc`.
- Synchronization files on non-Windows: `ConditionVariablePOSIX.cpp`, `MutexPOSIX.cpp`, `RWLockPOSIX.cpp`.

## 4. Error Classification Discipline for the Future M0 Spike

When running the narrow M0 `AK` compile spike (`AK/StringView.cpp` or a minimal `AK` unit) under an authorized `heavy` window, errors must be classified accurately — **never** misattributing missing headers/config to a compiler gap:
1. **Generated config headers**: missing `AK/Debug.h` / `AK/Backtrace.h`.
2. **Freestanding C++23 stdlib headers**: `-ffreestanding` provides compiler headers (`<stdint.h>`, `<stddef.h>`) but **not** `libc++` C++23 headers (`<type_traits>`, `<concepts>`, `<span>`, `<cstring>`, etc.).
3. **External `AK` dependencies**: `simdutf.h`, `fast_float`, `zmij`, `mimalloc`, `llvm-libc`.
4. **Real OS/runtime symbol gaps**: `pthread_mutex_*` / `malloc` / `free` / `mem*` (`nm -u`).

*Scope note*: Any narrow M0 spike measures only the targeted `AK` translation unit(s) — it does **not** represent full `AK` or `LibWeb` support.

## 5. Measured M0 Compile Spike Results (2026-11-25)

Command executed under authorized `heavy` window (`nice -n 10`, `tools/heavy.py`, isolated `build/phase-m0-ak-spike`, zero macOS SDK headers, `-DAK_OS_CAIRN=1`):
```sh
M0_OUT_DIR=build/phase-m0-ak-spike nice -n 10 python3 tools/heavy.py sh /Users/safases/Documents/proyectos/tarn-lng/ladybird-cairn/cairn_port/m0_ak_spike.sh
```

Using Homebrew LLVM `23.1.6` (`clang++` + OS-independent `libc++` headers under `Apache-2.0 WITH LLVM-exception`) with freestanding `cairn_port/libcxx-config/__config_site` (`_LIBCPP_HAS_THREADS=0`, `_LIBCPP_HAS_FILESYSTEM=0`, `_LIBCPP_HAS_LOCALIZATION=0`, `_LIBCPP_HAS_WIDE_CHARACTERS=0`, `_LIBCPP_HAS_RANDOM_DEVICE=0`, `_LIBCPP_HAS_MONOTONIC_CLOCK=0`, `_LIBCPP_HAS_UNICODE=0`) and minimal C declaration headers (`cairn_port/include/{unistd.h,sys/types.h,string.h,stdlib.h,stdio.h,wchar.h}`):

1. **`AK/Assertions.cpp` -> `Assertions.o` (COMPILED)**:
   - `nm -u`: `AK::vout(FILE*, StringView, TypeErasedFormatParams&, bool)` (from `AK/Format.cpp`), `w ak_assertion_handler`, `fputs`, `isatty`, `snprintf`, `stderr`.
2. **`AK/Error.cpp` -> `Error.o` (COMPILED)**:
   - `nm -u`: **0 undefined symbols**.
3. **`AK/StringView.cpp` & `AK/Utf8View.cpp`**:
   - Passed all `AK` and `libc++` headers; stopped cleanly at `fatal error: 'simdutf.h' file not found`.
4. **Link Plan for First `AK` Object Set (`Assertions.o` + `Error.o`)**:
   - Provide real freestanding implementations in `cairn_port/shim/` for `fputs`/`stderr` (mapped to Cairn `SYS_CONSOLE_WRITE` or bounded diagnostic buffer), `isatty` (returns `0` for non-TTY worker), `snprintf` (freestanding bounded formatter), plus `AK/Format.cpp` (or next `simdutf` single-header/amalgamated pin with exact commit/hash/license audit) before linking a static `x86_64-none-elf` test binary against `user/user.ld`.
   - **Honest scope**: Two `AK` objects compiled on host (`Assertions.o`, `Error.o`); **not** full `AK`, **not** linked ELF yet, and **not** guest-tested in QEMU.

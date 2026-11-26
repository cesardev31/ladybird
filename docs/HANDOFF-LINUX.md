# Linux Migration Handoff — `ladybird-cairn` (Native Cairn Port)

Date: 2026-11-25
Goal: **Native Cairn OS port of Ladybird** (`user/user.ld`, ADR 0022 syscalls, ADR 0048 memory quotas, Cairn IPC/SHM) — **never** `linuxd` or Linux ABI emulation.

---

## 1. Exact Repository & Branch State

### `ladybird-cairn` (this repo)
- **`origin`**: `https://github.com/cesardev31/ladybird.git`
- **`upstream`**: `https://github.com/LadybirdBrowser/ladybird.git`
- **Branch**: `cairn/native-port` branched from pinned `master` commit `d297a26ac4eabaa58030b82bb57a0ccc27767c3f`
- **Upstream C++ files modified**: **None** (all adaptations live in `cairn_port/`, `docs/`, and `NOTICE.md`).
- **Own files in `ladybird-cairn`**:
  - `NOTICE.md` (verbatim `BSD-2-Clause` `LICENSE` from `cesardev31/ladybird` at `d297a26`)
  - `docs/cairn-port-README.md`
  - `docs/adr/0001-ladybird-native-cairn-port.md`
  - `docs/port-plan.md`
  - `docs/m0-ak-static-audit.md`
  - `docs/HANDOFF-LINUX.md` (this file)
  - `cairn_port/m0_ak_spike.sh`
  - `cairn_port/libcxx-config/__config_site` (`Apache-2.0 WITH LLVM-exception`)
  - `cairn_port/include/{unistd.h,sys/types.h,string.h,stdlib.h,stdio.h,wchar.h}`

### `cairn` (sibling repo, `../cairn`)
- **NB0a (`libs/browser_core/`)**: `5/5` host unit tests passed (`tools/test-libs.sh browser_core`), `0` `unsafe`. Preserved as Cairn's pure-Tarn URL/origin/UTF-8/policy foundation.
- **Native C smoke (`libs/browser_core/c_parser_proto/`)**: `cairn_native_smoke.elf` compiled and inspected on host (`ET_EXEC`, `entry=0x400000`, `PT_NOTE CAIRN\0 00000300`, `0` undefined symbols). **Not** yet executed in QEMU.
- **Superseded exploration docs**: `docs/adr/0103-browser-c-parsers-and-js-isolation.md`, `docs/phase-nb0b-html-css-plan.md`, `docs/design/native-browser-engine-feasibility.md` (preserved, marked `superseded / exploration`).

---

## 2. M0 `AK` Compile Spike Status (Honest Evidence)

Tested on macOS host with Homebrew LLVM `23.1.6` (`clang++` + OS-independent `libc++` headers, **zero macOS SDK headers**, `-DAK_OS_CAIRN=1`, `--target=x86_64-none-elf -std=c++23 -ffreestanding -nostdlib -nostdinc++ -fno-exceptions -fno-builtin -mno-red-zone`):

- **`AK/Assertions.cpp` -> `Assertions.o` (COMPILED)**:
  - `nm -u`: `_ZN2AK4voutEP11_CAIRN_FILENS_10StringViewERNS_22TypeErasedFormatParamsEb` (`AK::vout`), weak `ak_assertion_handler`, `fputs`, `isatty`, `snprintf`, `stderr`.
- **`AK/Error.cpp` -> `Error.o` (COMPILED)**:
  - `nm -u`: **0 undefined symbols**.
- **`AK/StringView.cpp` & `AK/Utf8View.cpp` (STOPPED AT EXTERNAL DEP)**:
  - Passed all `AK` and `libc++` headers; stopped cleanly at `fatal error: 'simdutf.h' file not found`.
- **Not yet done**: `simdutf` not vendored/pinned yet, `cairn_port/shim/` C symbols not implemented yet, no linked `AK` ELF yet, no QEMU guest test yet.

---

## 3. Reproducible Linux Setup (No Homebrew Paths)

**Important**: Installed `libc++` headers do **not** travel in git. On macOS, `m0_ak_spike.sh` defaulted to `/usr/local/opt/llvm/bin/clang++` and `/usr/local/opt/llvm/include/c++/v1` (LLVM `23.1.6`). **Linux reproducibility has NOT been tested yet**; on Linux, install `clang` + `lld` + `libc++-dev` (LLVM `libc++` headers, `Apache-2.0 WITH LLVM-exception`) and pass `CAIRN_CXX` and `CAIRN_LIBCXX_INC` explicitly (never use `/usr/include` glibc headers):

```sh
# Example on Debian/Ubuntu/Arch with libc++-dev installed (untested on Linux):
CAIRN_CXX=clang++ \
CAIRN_LIBCXX_INC=/usr/include/c++/v1 \
M0_OUT_DIR=../cairn/build/phase-m0-ak-spike \
nice -n 10 python3 ../cairn/tools/heavy.py sh ./cairn_port/m0_ak_spike.sh
```

Note: If the Linux distro's `libc++` version differs from LLVM `23.1.6`, compare `cairn_port/libcxx-config/__config_site` against `/usr/include/c++/v1/__config_site` (especially `_LIBCPP_HARDENING_MODE_DEFAULT` and `_LIBCPP_ASSERTION_SEMANTIC_DEFAULT`) before running.

---

## 4. Toolchain, Versions & Licenses

- **Ladybird**: `d297a26ac4eabaa58030b82bb57a0ccc27767c3f` (`BSD-2-Clause`).
- **LLVM `libc++` headers**: `Apache-2.0 WITH LLVM-exception` (tested with `23.1.6` on host; OS-independent headers only via `-nostdinc++ -isystem ...`).
- **`cairn_port/` shims**: Original Cairn port scaffolding (`unistd.h`, `sys/types.h`, `string.h`, `stdlib.h`, `stdio.h`, `wchar.h`), exposing only minimal declarations without fake POSIX/pthread implementations.
- **No binaries, build caches, or secrets** are tracked or included.

---

## 5. Next Steps on Linux

1. Verify `m0_ak_spike.sh` on Linux with `CAIRN_CXX=clang++` and `CAIRN_LIBCXX_INC=/usr/include/c++/v1` (confirm `Assertions.o` and `Error.o` compile cleanly).
2. Audit and pin `simdutf` (exact release tag, SHA-256, `Apache-2.0` / `MIT` license notice in `NOTICE.md`) to unblock `AK/StringView.cpp` and `AK/Utf8View.cpp`.
3. Implement minimal freestanding `cairn_port/shim/` (`fputs`/`stderr` -> `SYS_CONSOLE_WRITE`, `isatty` -> `0`, bounded `snprintf`, `malloc`/`free` arena over `SYS_VM_MAP`), link a static `x86_64-none-elf` `AK` smoke ELF with `../cairn/user/user.ld`, and test in QEMU under Cairn's quota/sandbox.
4. Continue incrementally: `AK` -> `LibCore` (`EventLoopImplementationCairn`) + `LibIPC` -> `LibGfx` (CPU) -> `LibJS` (no JIT) -> `LibWeb` + Cairn `apps/browser`.

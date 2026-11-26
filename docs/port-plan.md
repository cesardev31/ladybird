# `ladybird-cairn` Port Plan — Incremental Milestones

All milestones target Cairn's native ELF ABI (`user/user.ld`) with zero `linuxd`/Linux emulation. No builds or upstream downloads occur without explicit `heavy` authorization.

## Remotes, Pinning & Safe Population Strategy

- **`origin`**: `https://github.com/cesardev31/ladybird.git` (owner fork, default branch `master`)
- **`upstream`**: `https://github.com/LadybirdBrowser/ladybird.git`
- **Pinned `master` SHA** (verified 2026-11-25): `d297a26ac4eabaa58030b82bb57a0ccc27767c3f`
- **Maintainable Branch Strategy**: Keep Cairn adaptation commits on a dedicated branch (e.g. `cairn/native-port`) branched from the pinned `upstream`/`origin` `master` commit, never a zero-history fork.
- **Safe Population of `ladybird-cairn`** (preserving existing Cairn docs without `reset`/`clean` or overwriting upstream):
  1. Cairn-specific docs live at `docs/cairn-port-README.md`, `docs/adr/0001-ladybird-native-cairn-port.md`, `docs/port-plan.md`, and `NOTICE.md` (avoiding `README.md` collision with upstream).
  2. When authorized to fetch history:
     - `git remote add origin https://github.com/cesardev31/ladybird.git`
     - `git remote add upstream https://github.com/LadybirdBrowser/ladybird.git`
     - Temporarily stash or back up the 4 untracked Cairn docs (`docs/cairn-port-README.md`, `docs/adr/0001-ladybird-native-cairn-port.md`, `docs/port-plan.md`, `NOTICE.md`), `git fetch origin master` (at pinned SHA `d297a26ac4eabaa58030b82bb57a0ccc27767c3f`), `git checkout -b cairn/native-port origin/master`, and restore the 4 Cairn docs without touching any upstream file.
     - No `git commit` or `git push` until root reviews and authorizes.

## Baseline Platform Proof (In `../cairn`)
- `../cairn/libs/browser_core/c_parser_proto/cairn_native_smoke.c` + `build_native_smoke.sh`: validates `cairn_init` stack alignment, `.note.cairn`, `SYS_VM_MAP`/`SYS_VM_UNMAP`/`SYS_EXIT`, and 0 undefined symbols.

## Secondary Orientation Map & Verified `d297a26` Adaptation Seams

- **Secondary Reference**: `https://deepwiki.com/LadybirdBrowser/ladybird` (last indexed `11 June 2026`, commit `abfd5a`) was used strictly as a secondary orientation map (Multi-Process Architecture, Build System & Code Generation, `AK`, `LibCore`/`LibGfx`, `LibJS`, `LibWeb`, `LibWebView`) — **not** as an authority for APIs, licenses, or support.
- **Discrepancies vs Our Pinned Tree (`d297a26ac4eabaa58030b82bb57a0ccc27767c3f`)**:
  - Commit mismatch (`abfd5a` vs `d297a26`); every file path and build flag must be verified directly in `ladybird-cairn`.
  - At `d297a26`, `Services/` contains `Compositor`, `Hub`, `ImageDecoder`, `AudioServer`, `MediaServer`, `ProcessReaper`, and `RendererSandbox.{h,*cpp}` (while `Libraries/` includes `LibWeb`, `LibWebView`, `LibRequests`, `LibHTTP`, `LibCompositing`, `LibSandbox`, plus `RustAllocator`/`RustDemangle.rs`/`RustPanic.rs`).
- **Verified Upstream Adaptation Seams (`d297a26`)**:
  - **Event Loop**: `Libraries/LibCore/EventLoopImplementation.{h,cpp}` (sibling to `EventLoopImplementationUnix.*` / `EventLoopImplementationWindows.*`) -> target for `EventLoopImplementationCairn`.
  - **IPC**: `Libraries/LibIPC/` (`Connection.{h,cpp}`, `Encoder`/`Decoder`, `Attachment.{h,cpp}`, `FfiConnection.h`) -> target for Cairn IPC/SHM transport.
  - **Sandbox**: `Services/RendererSandbox.h` (sibling to `RendererSandboxLinux.cpp` / `RendererSandboxUnimplemented.cpp`) -> target for Cairn capability/MMU/quota confinement.

## M0: `AK` Native Compile Spike
1. See [m0-ak-static-audit.md](m0-ak-static-audit.md) for the static audit of `AK/CMakeLists.txt`, `Meta/CMake/compile_options.cmake` (C++23, `-fno-exceptions`), generated config headers (`AK/Debug.h`, `AK/Backtrace.h`), and external deps (`simdutf`, `fast-float`, `zmij`, `mimalloc`, `llvm-libc`).
2. Prepared spike script: `cairn_port/m0_ak_spike.sh` (generates `AK/Debug.h` & `AK/Backtrace.h` from `.in` templates and compiles unmodified `AK/{Assertions,Error,StringView,Utf8View}.cpp` with `clang++ --target=x86_64-none-elf -std=c++23 -ffreestanding -nostdlib -fno-exceptions -mno-red-zone`, capturing diagnostics and `nm -u` into `build/phase-m0-ak-spike/m0_ak_spike.log`).
3. **Gate M0**: Documented `nm -u` symbol & header gap inventory for the narrow `AK` target (not claimed as full `AK` or `LibWeb` support).

## M1: `LibCore` Minimal Event Loop + `LibIPC` over Cairn IPC/SHM
1. Adapt `LibCore` timers/event loop to Cairn `SYS_TIME_NS` (monotonic) and Cairn IPC `REPLY_RECV` / notifications (no POSIX `epoll`/`socketpair`/`fork`).
2. **Gate M1**: Two isolated native Cairn processes exchange a typed `LibIPC` ping/pong message under Cairn's kernel quota.

## M2: `LibGfx` CPU Rasterization -> Cairn `fb.Canvas`
1. Audit `LibGfx` (and whether `Skia` CPU-only rasterizer builds without ANGLE/OpenGL/fontconfig).
2. Render a test rect/text/bitmap into a shared `fb.Canvas` buffer displayed by a Cairn Tarn window (`surface_proto`).
3. **Gate M2**: Host/QEMU pixel-hash or visual golden match.

## M3: `LibJS` Interpreter-Only Spike
1. Compile `LibJS` without JIT (respecting Cairn W^X / no `PROT_EXEC`).
2. Wire heap ceiling (ADR 0048 quota + allocator cap) and execution cancellation/timeout.
3. **Gate M3**: Isolated worker evaluates deterministic JS expressions and aborts cleanly on infinite loop / OOM.

## M4: `LibWeb` (`WebContent`) + Cairn-Mediated `apps/browser`
1. Isolate `WebContent` with zero ambient FS/net/compositor capabilities.
2. Mediate HTTP/TLS/URL/origin through Cairn (`../cairn/libs/browser_core`, `libs/tls`, `libs/pki`, `libs/http`).
3. **Gate M4**: Local HTML+CSS(+JS) fixture rendered inside Cairn's real `apps/browser` window in QEMU.

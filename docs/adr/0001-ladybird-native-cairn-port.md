# ADR 0001 — Native Cairn Port of Ladybird (`ladybird-cairn`)

Status: **proposed** (2026-11-25).

## Context

Owner decision (2026-11-25) selected **Ladybird** (`https://github.com/LadybirdBrowser/ladybird`) as the browser engine to port natively to Cairn OS in a separate sibling repository (`ladybird-cairn`), dropping the alternative parser-assembly (`Hubbub+LibCSS+QuickJS`) and custom-layout routes.

## Decision

1. **Separate Repository & Maintainable Upstream Strategy**:
   - `ladybird-cairn` is an independent local git repository (not a worktree) that pins an exact upstream `LadybirdBrowser/ladybird` commit SHA and maintains Cairn platform adaptations cleanly.
   - Upstream core code is **not** copied into `../cairn`.
2. **Native Cairn Target (No `linuxd`, No Hidden Linux ABI)**:
   - Every port target compiles to Cairn's native ELF format (`../cairn/user/user.ld`, `cairn_init`, `.note.cairn`) using explicit, audited native C/C++ runtime shims over Cairn's ADR 0022 syscalls (`SYS_VM_MAP`, `SYS_VM_UNMAP`, `SYS_TIME_NS`, `SYS_GETRANDOM`, `SYS_EXIT`, IPC/SHM).
   - `.note.cairn` versioning: `user/user.ld` emits `0.3` (accepted by `ABI 0.15` since `minor <= 15`), but each worker's note must justify the actual minimum ABI minor version of the contracts it uses rather than blindly copying `0.3`.
   - Where native `libc` / C++23 runtime (`libc++`, `-fno-exceptions`, `malloc`/`free` over `SYS_VM_MAP`) is required, it must be explicit, freestanding, and Cairn-native.
3. **Capability, MMU & Quota Mapping (No Sandbox Weakening)**:
   - Ladybird's multi-process architecture (`WebContent`, `RequestServer`, `ImageDecoder`, `LibIPC`) maps to Cairn's MMU-isolated processes and ADR 0048 hierarchical memory quotas.
   - `WebContent` receives **zero** ambient filesystem, network, or compositor capabilities.
   - Network/TLS/origin policy remains mediated by Cairn (`../cairn/libs/browser_core`, `libs/tls`, `libs/pki`, `libs/http`).
   - Cairn's own Tarn UI (`apps/browser` via `surface_proto` + `desktop_shell/chrome.tarn` + `fb.Canvas`) presents rendered output and forwards input events; Ladybird's Qt/AppKit UI is not ported.
4. **CPU-First Graphics & W^X**:
   - Prioritize CPU/software rasterization into Cairn `fb.Canvas` / SHM surfaces if upstream `LibGfx`/Skia supports a CPU-only build without OpenGL/ANGLE.
   - Cairn ABI v0 has no `PROT_EXEC` in `SYS_VM_MAP`; all worker heaps remain `RW-` (W^X enforced; interpreter mode only for `LibJS` in initial milestones).

## Runtime & Dependency Inventory (To Be Measured in M0 Spike)

The following surfaces are **unmeasured until the M0 `AK` spike** compiles against Cairn's native target:
- **C++20/23 Runtime**: `new`/`delete`, `<atomic>`, `<type_traits>`, exceptions/RTTI vs `-fno-exceptions`, `libc++` headers.
- **C Runtime**: `malloc`/`calloc`/`realloc`/`free` (over `SYS_VM_MAP`), `memcpy`/`memmove`/`memset`/`memcmp`, `snprintf`/`vsnprintf`, `strtod`, `math.h`, `abort`/`assert`.
- **Concurrency / IPC**: Whether `AK` can be built single-threaded or requires mutex/futex/pthread stubs; mapping `LibIPC` to Cairn IPC/SHM.
- **External Deps (`LibGfx` / `LibWeb`)**: `Skia`, `ICU`, `HarfBuzz` — exact CMake flags and minimal dependency closure to be audited at the pinned upstream commit.

## Licensing & Notice Obligations

- **Ladybird Core**: `BSD-2-Clause` (`https://github.com/LadybirdBrowser/ladybird/blob/master/LICENSE`).
- **Transitive Dependencies**: e.g. `Skia` (`BSD-3-Clause`), `ANGLE` (`BSD-3-Clause`), `ICU` (`ICU License`), `HarfBuzz` (`Old-MIT`), `[AUDIT-PENDING: full list & exact LICENSE texts at pinned commit]`.
- **Important**: Separating `ladybird-cairn` into a sibling repository does **not** eliminate license obligations when linking or distributing binaries with Cairn. All required copyright, permission, and third-party notices must be preserved verbatim in `NOTICE.md` and distribution artifacts.

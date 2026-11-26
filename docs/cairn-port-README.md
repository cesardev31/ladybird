# `ladybird-cairn` — Native Cairn Port of Ladybird

Separate repository for porting the **Ladybird** browser engine (`https://github.com/LadybirdBrowser/ladybird`, **BSD-2-Clause**) natively to **Cairn OS** (`../cairn`).

## Core Principles

1. **Native Cairn Only**: Targets Cairn's native ELF ABI (`user/user.ld`, ADR 0022 syscalls, ADR 0048 memory quotas, Cairn IPC/SHM) — **never** `linuxd` or hidden Linux ABI emulation.
2. **Maintainable Patch / Branch Strategy**: Upstream Ladybird source is pinned by exact commit SHA and adapted via minimal, auditable patches/shims rather than copying Ladybird's core into `../cairn`.
3. **Preserved NB0a**: `../cairn/libs/browser_core` (restricted URL, WHATWG UTF-8, offline Document) is preserved as Cairn's pure-Tarn URL/origin/policy foundation.
4. **Cairn UI & Capability Sandbox**: Cairn's own Tarn UI (`apps/browser` over `surface_proto`, `desktop_shell/chrome.tarn`, `fb.Canvas`) wraps the isolated `WebContent` worker without weakening Cairn's capability/MMU/quota sandbox.

## Status

- **Preparation phase** (plan + ADR + license/notice scaffolding).
- No upstream checkout, no commits, no remotes, and no builds/tests executed yet (`heavy` window pending).

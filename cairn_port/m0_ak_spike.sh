#!/bin/sh
# M0 narrow upstream AK compile spike (DO NOT RUN without explicit heavy window).
# Compiles unmodified upstream AK sources for Cairn's native x86_64-none-elf target
# (no Linux ABI, no upstream C++ edits) to measure C++23 stdlib, dep, and symbol gaps.
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
LB_ROOT=$(cd "$HERE/.." && pwd)
CAIRN_ROOT=${CAIRN_ROOT:-"$(cd "$LB_ROOT/../cairn" && pwd)"}
OUT_DIR=${M0_OUT_DIR:-"$CAIRN_ROOT/build/phase-m0-ak-spike"}
GEN_INC="$OUT_DIR/gen-include"

mkdir -p "$GEN_INC/AK"

# Generate CMake-configured headers from upstream .in templates (all debug flags = 0, no Backtrace).
sed -E 's/^#[[:space:]]*cmakedefine01[[:space:]]+([A-Za-z0-9_]+)/#define \1 0/' \
    "$LB_ROOT/AK/Debug.h.in" > "$GEN_INC/AK/Debug.h"
sed -E 's/^#[[:space:]]*cmakedefine[[:space:]]+Backtrace_FOUND/\/\* #undef Backtrace_FOUND \*\//' \
    "$LB_ROOT/AK/Backtrace.h.in" > "$GEN_INC/AK/Backtrace.h"

LOG="$OUT_DIR/m0_ak_spike.log"
: > "$LOG"

# Upstream flags from Meta/CMake/compile_options.cmake: C++23, -fno-exceptions.
# Cairn native freestanding flags: x86_64-none-elf, -ffreestanding -nostdlib -fno-builtin -mno-red-zone.
# Uses Homebrew LLVM 23.1.6 clang++ + OS-independent libc++ headers (Apache-2.0 WITH LLVM-exception),
# with freestanding __config_site and zero macOS SDK headers.
CXX=${CAIRN_CXX:-/usr/local/opt/llvm/bin/clang++}
LIBCXX_INC=${CAIRN_LIBCXX_INC:-/usr/local/opt/llvm/include/c++/v1}
CXXFLAGS="--target=x86_64-none-elf -std=c++23 -ffreestanding -nostdlib -nostdinc++ -fno-exceptions -fno-builtin -fno-pic -fno-pie -fno-stack-protector -mno-red-zone -Os -DAK_OS_CAIRN=1 -isystem $HERE/libcxx-config -isystem $LIBCXX_INC -isystem $HERE/include -I$GEN_INC -I$LB_ROOT"

for src in AK/Assertions.cpp AK/Error.cpp AK/StringView.cpp AK/Utf8View.cpp; do
    obj="$OUT_DIR/$(basename "$src" .cpp).o"
    echo "=== compiling $src ===" | tee -a "$LOG"
    if "$CXX" $CXXFLAGS -c "$LB_ROOT/$src" -o "$obj" >>"$LOG" 2>&1; then
        echo "OK: $src -> $obj" | tee -a "$LOG"
        echo "--- nm -u $obj ---" >>"$LOG"
        nm -u "$obj" >>"$LOG" 2>&1 || true
    else
        echo "FAIL: $src (see $LOG)" | tee -a "$LOG"
    fi
done

echo "M0 spike log: $LOG"

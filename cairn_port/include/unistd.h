#pragma once
/* Minimal Cairn freestanding shim for AK/Platform.h PAGE_SIZE discovery. */
#define _SC_PAGESIZE 30
#define STDERR_FILENO 2

#ifdef __cplusplus
extern "C" {
#endif

static inline long sysconf(int name) {
    return (name == _SC_PAGESIZE) ? 4096L : -1L;
}

int isatty(int fd);

#ifdef __cplusplus
}
#endif

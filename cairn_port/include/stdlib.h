#pragma once
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct { int quot; int rem; } div_t;
typedef struct { long quot; long rem; } ldiv_t;
typedef struct { long long quot; long long rem; } lldiv_t;

div_t div(int numer, int denom);
ldiv_t ldiv(long numer, long denom);
lldiv_t lldiv(long long numer, long long denom);

void* malloc(size_t size);
void* calloc(size_t count, size_t size);
void* realloc(void* ptr, size_t size);
void free(void* ptr);
__attribute__((noreturn)) void abort(void);
double strtod(const char* nptr, char** endptr);
float strtof(const char* nptr, char** endptr);
long strtol(const char* nptr, char** endptr, int base);
unsigned long strtoul(const char* nptr, char** endptr, int base);
long long strtoll(const char* nptr, char** endptr, int base);
unsigned long long strtoull(const char* nptr, char** endptr, int base);

#ifdef __cplusplus
}
#endif

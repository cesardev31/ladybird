#pragma once
#include <stdarg.h>
#include <stddef.h>

#define EOF (-1)

#ifdef __cplusplus
extern "C" {
#endif

typedef struct _CAIRN_FILE FILE;
extern FILE* stderr;
extern FILE* stdout;

int snprintf(char* buf, size_t size, const char* fmt, ...);
int vsnprintf(char* buf, size_t size, const char* fmt, va_list ap);
int fprintf(FILE* stream, const char* fmt, ...);
int fputc(int c, FILE* stream);
int fputs(const char* s, FILE* stream);
size_t fwrite(const void* ptr, size_t size, size_t nmemb, FILE* stream);
int fflush(FILE* stream);

#ifdef __cplusplus
}
#endif

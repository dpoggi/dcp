#include <stdio.h>

#if defined(_MSC_VER) || defined(__MINGW64__)
#define NOMINMAX
#define VC_EXTRALEAN
#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#else
#include <stdlib.h>
#include <time.h>

// CLOCK_MONOTONIC must be defined on non-Windows systems
#if !defined(CLOCK_MONOTONIC)
#error Unsupported runtime
#endif  // !defined(CLOCK_MONOTONIC)
#endif  // defined(_MSC_VER) || defined(__MINGW64__)

int main(void)
{
    unsigned long long timestamp;

#if defined(_WIN64)
    timestamp = (unsigned long long)GetTickCount64();
#elif defined(_WIN32)
    timestamp = (unsigned long long)GetTickCount();
#else
    struct timespec tp;
    if (clock_gettime(CLOCK_MONOTONIC, &tp) != 0) {
        perror("clock_gettime");
        exit(EXIT_FAILURE);
    }
    timestamp = ((unsigned long long)tp.tv_sec * 1000ULL) + ((unsigned long long)tp.tv_nsec / 1000000ULL);
#endif

    printf("%llu\n", timestamp);
}

#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

#if defined(_MSC_VER) || defined(__MINGW64__)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#include <Windows.h>
#elif (defined(__APPLE__) && defined(__MACH__)) || defined(__GLIBC__)
// Only macOS and Linux supported in this branch - CLOCK_MONOTONIC_RAW
// and ignoring the return value of clock_gettime are non-standard
#include <time.h>
#else
#error Unsupported runtime
#endif

int main(void)
{
    uint64_t timestamp;

#if defined(_WIN64)
    timestamp = (uint64_t)GetTickCount64();
#elif defined(_WIN32)
    timestamp = (uint64_t)GetTickCount();
#else
    struct timespec tp;
    (void)clock_gettime(CLOCK_MONOTONIC_RAW, &tp);

    timestamp =
        ((uint64_t)tp.tv_sec * UINT64_C(1000)) +
        ((uint64_t)tp.tv_nsec / UINT64_C(1000000));
#endif

    printf("%" PRIu64 "\n", timestamp);
}

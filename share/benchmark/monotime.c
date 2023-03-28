#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

#if defined(_MSC_VER) || defined(__MINGW64__)
#define NOMINMAX
#define VC_EXTRALEAN
#define WIN32_LEAN_AND_MEAN

#include <Windows.h>
#else
#include <stdlib.h>
#include <time.h>

// CLOCK_MONOTONIC_RAW or CLOCK_MONOTONIC must be defined on non-Windows systems
#if defined(CLOCK_MONOTONIC_RAW)
#define MONOCLOCK CLOCK_MONOTONIC_RAW
#elif defined(CLOCK_MONOTONIC)
#define MONOCLOCK CLOCK_MONOTONIC
#warning CLOCK_MONOTONIC_RAW unavailable, falling back to CLOCK_MONOTONIC
#else
#error Unsupported runtime
#endif
#endif  // defined(_MSC_VER) || defined(__MINGW64__)

int main(void)
{
    uint64_t timestamp;

#if defined(_WIN64)
    timestamp = (uint64_t)GetTickCount64();
#elif defined(_WIN32)
    timestamp = (uint64_t)GetTickCount();
#else
    struct timespec tp;
    if (clock_gettime(MONOCLOCK, &tp) != 0) {
        perror("clock_gettime");
        exit(EXIT_FAILURE);
    }

    timestamp =
        (uint64_t)tp.tv_sec * UINT64_C(1000) +
        (uint64_t)tp.tv_nsec / UINT64_C(1000000);
#endif

    printf("%" PRIu64 "\n", timestamp);
}

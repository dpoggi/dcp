#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

#ifdef _WIN32
#include <Windows.h>
#else
#include <time.h>
#endif  // _WIN32

// Check because CLOCK_MONOTONIC_RAW and ignoring the return value of
// clock_gettime are non-standard
#if !(defined(__GLIBC__) || defined(__MACH__) || defined(_WIN32))
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

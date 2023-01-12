#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

#ifdef _WIN32
#include <Windows.h>
#else
#include <stdlib.h>
#include <time.h>
#endif  // _WIN32

int main(void)
{
    uint64_t timestamp;

#if defined(_WIN64)
    timestamp = (uint64_t)GetTickCount64();
#elif defined(_WIN32)
    timestamp = (uint64_t)GetTickCount();
#else
    struct timespec tp;
    if (clock_gettime(CLOCK_MONOTONIC, &tp) != 0) {
        perror("clock_gettime");
        exit(EXIT_FAILURE);
    }

    timestamp =
        ((uint64_t)tp.tv_sec * UINT64_C(1000)) +
        ((uint64_t)tp.tv_nsec / UINT64_C(1000000));
#endif

    printf("%" PRIu64 "\n", timestamp);
}

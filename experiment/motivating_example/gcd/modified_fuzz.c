#include <stdint.h>
#include <limits.h>
#include "modified.h"

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
    if (size < 8)
        return 0;

    int32_t a = ((int32_t *)data)[0];
    int32_t b = ((int32_t *)data)[1];

    // skip cases that would cause undefined behavior
    if ((a == INT_MIN && b == -1) || b == 0)
        return 0;

    int result = gcd(a, b);

    return 0;
}

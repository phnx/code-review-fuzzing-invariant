#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include "original_1.h"

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
    if (size < 1)
        return 0;

    unsigned int n = data[0];

    unsigned long result = factorial(n);

    if (n <= 12 && result < 0)
    {
        fprintf(stderr, "Error: factorial(%u) returned negative value: %d\n", n, result);
        abort();
    }

    return 0;
}

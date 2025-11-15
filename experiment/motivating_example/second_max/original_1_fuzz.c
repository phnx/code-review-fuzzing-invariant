#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include "original_1.h"

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
    if (size < sizeof(int))
        return 0;

    size_t len = size / sizeof(int);
    int *arr = (int *)malloc(len * sizeof(int));
    if (!arr)
        return 0;

    for (size_t i = 0; i < len; ++i)
    {
        arr[i] = ((int *)data)[i];
    }

    second_max(len, arr);

    free(arr);
    return 0;
}

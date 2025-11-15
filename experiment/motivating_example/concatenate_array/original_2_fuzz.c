#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "original_2.h"

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
    if (size < 8)
        return 0;

    size_t size1 = (data[0] % 19) + 1;
    size_t size2 = (data[1] % 19) + 1;

    size_t needed = sizeof(uint32_t) * (size1 + size2) + 2;
    if (size < needed)
        return 0;

    const uint32_t *values = (const uint32_t *)(data + 2);

    int *arr1 = (int *)malloc(size1 * sizeof(int));
    for (size_t i = 0; i < size1; ++i)
    {
        arr1[i] = (int)values[i];
    }

    int *arr2 = (int *)malloc(size2 * sizeof(int));
    for (size_t i = 0; i < size2; ++i)
    {
        arr2[i] = (int)values[size1 + i];
    }

    int *result = concatenate_array(arr1, size1, arr2, size2);

    free(arr1);
    free(arr2);
    free(result);

    return 0;
}

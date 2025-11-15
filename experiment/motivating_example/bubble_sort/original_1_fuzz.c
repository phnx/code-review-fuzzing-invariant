#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "original_1.h"

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
    if (size < sizeof(int))
        return 0;

    size_t arr_size = size / sizeof(int);
    if (arr_size > 1024)
        return 0;

    int *arr = (int *)malloc(arr_size * sizeof(int));
    if (!arr)
        return 0;

    memcpy(arr, data, arr_size * sizeof(int));

    bubble_sort(arr, arr_size);

    free(arr);

    return 0;
}

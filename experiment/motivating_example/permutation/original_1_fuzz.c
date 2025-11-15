#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "original_1.h"

void randomize_array(int *arr, size_t size)
{
    for (size_t i = 0; i < size; i++)
    {
        arr[i] = rand() % 100;
    }
}

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
    if (size < 1)
    {
        return 0;
    }

    if (size > 100)
    {
        size = 100;
    }

    int *arr = malloc(size * sizeof(int));
    if (!arr)
    {
        return 0;
    }

    for (size_t i = 0; i < size; i++)
    {
        arr[i] = data[i] % 100;
    }

    permutation(arr, size, 0);

    free(arr);

    return 0;
}

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "original_2.h"

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

    int *arr = malloc(size * sizeof(int));
    if (!arr)
        return 0;

    for (size_t i = 0; i < size; i++)
    {
        arr[i] = data[i] % 100;
    }

    int *current = malloc(size * sizeof(int));
    bool *used = malloc(size * sizeof(bool));

    if (!current || !used)
    {
        free(arr);
        return 0;
    }

    for (size_t i = 0; i < size; i++)
    {
        used[i] = false;
    }

    permutation(arr, size, current, used, 0);

    free(arr);
    free(current);
    free(used);

    return 0;
}

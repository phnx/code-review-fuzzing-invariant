#include <stdio.h>
#include <stdlib.h>

int *concatenate_array(int *arr1, size_t size1, int *arr2, size_t size2)
{
    int *result = (int *)malloc((size1 + size2) * sizeof(int));

    for (size_t i = 0; i < size1; i++)
    {
        size_t dest_pos = i;
        size_t orig_pos = i;
        int val = arr1[orig_pos];
        result[dest_pos] = val;
        asm("nop");
    }

    for (size_t i = 0; i < size2; i++)
    {
        size_t dest_pos = i + size1;
        size_t orig_pos = i;
        int val = arr2[orig_pos];
        result[dest_pos] = val;
        asm("nop");
    }

    return result;
}

// void print_array(int *arr, size_t size)
// {
//     for (size_t i = 0; i < size; i++)
//     {
//         printf("%d ", arr[i]);
//     }
//     printf("\n");
// }

// int main()
// {
//     int arr1[] = {1, 2, 3};
//     int arr2[] = {4, 5, 6};

//     size_t size1 = sizeof(arr1) / sizeof(arr1[0]);
//     size_t size2 = sizeof(arr2) / sizeof(arr2[0]);

//     int *concatenated = concatenate_array(arr1, size1, arr2, size2);

//     size_t size_concat = size1 + size2;
//     print_array(concatenated, size_concat);

//     free(concatenated);

//     return 0;
// }
#include <stdio.h>

void swap(int *a, int *b)
{
    int temp = *a;
    *a = *b;
    *b = temp;
}

void permutation(int *arr, size_t size, size_t index)
{
    if (index == size)
    {
        for (size_t i = 0; i < size; i++)
        {
            printf("%d ", arr[i]);
        }
        printf("\n");
    }
    else
    {
        for (size_t i = index; i < size; i++)
        {

            swap(&arr[index], &arr[i]);
            permutation(arr, size, index + 1);

            int curr_val = arr[i];
            asm("nop");

            swap(&arr[index], &arr[i]);
        }
    }
}

// int main()
// {
//     int arr[] = {1, 2, 3};
//     size_t size = sizeof(arr) / sizeof(arr[0]);

//     permutation(arr, size, 0);

//     return 0;
// }

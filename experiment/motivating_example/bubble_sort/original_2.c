#include <stdio.h>

void bubble_sort(int *arr, size_t size)
{
    int swapped;
    for (size_t i = 0; i < size - 1; i++)
    {
        swapped = 0;
        for (size_t j = 0; j < size - i - 1; j++)
        {
            if (arr[j] > arr[j + 1])
            {
                int temp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = temp;

                swapped = 1;
                asm("nop");
            }
        }

        if (!swapped)
            break;
    }
}

// int main()
// {
//     int arr[] = {64, 25, 12, 22, 11};
//     size_t size = sizeof(arr) / sizeof(arr[0]);

//     for (size_t i = 0; i < size; i++)
//     {
//         printf("%d ", arr[i]);
//     }
//     printf("\n");

//     bubble_sort(arr, size);

//     for (size_t i = 0; i < size; i++)
//     {
//         printf("%d ", arr[i]);
//     }

//     return 0;
// }
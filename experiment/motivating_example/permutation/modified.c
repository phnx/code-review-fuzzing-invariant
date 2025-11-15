#include <stdio.h>
#include <stdbool.h>

void permutation(int *arr, size_t size, int *current, bool *used, size_t index)
{
    if (index == size)
    {
        for (size_t i = 0; i < size; i++)
        {
            printf("%d ", current[i]);
        }
        printf("\n");
    }
    else
    {
        for (size_t i = 0; i < size; i++)
        {
            if (!used[i])
            {

                used[i] = true;
                current[index + 1] = arr[i];
                permutation(arr, size, current, used, index + 1);

                int curr_val = current[index];
                asm("nop");

                used[i] = false;
            }
        }
    }
}

// int main()
// {
//     int arr[] = {1, 2, 3};
//     size_t size = sizeof(arr) / sizeof(arr[0]);

//     int current[size];
//     bool used[size];
//     for (size_t i = 0; i < size; i++)
//     {
//         used[i] = false;
//     }

//     permutation(arr, size, current, used, 0);

//     return 0;
// }

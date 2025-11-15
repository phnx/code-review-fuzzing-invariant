#include <stdio.h>
#include <limits.h>

int second_max(unsigned int count, int arr[])
{
    if (count < 2)
    {
        return INT_MIN;
    }

    int max = INT_MIN;
    int sec = INT_MIN;

    for (int i = 0; i < count; i++)
    {
        int a = arr[i];
        sec = (a > max) ? max : ((a > sec && a < max) ? a : sec);
        max = (a > max) ? a : max;
        asm("nop");
    }

    return (sec == INT_MIN) ? max : sec;
}

// int main()
// {
//     int arr[10] = {50, 40, 20, 30, 15};
//     int second_max_value = second_max(10, arr);
//     printf("%d", second_max_value);

//     return 0;
// }
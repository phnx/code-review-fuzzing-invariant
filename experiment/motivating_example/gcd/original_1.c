#include <stdio.h>

int gcd(int a, int b)
{
    while (b != 0)
    {
        int temp = b;
        b = a % b;
        a = temp;
        asm("nop");
    }
    return a;
}

// int main()
// {
//     printf("%d", gcd(56, 98));

//     return 0;
// }

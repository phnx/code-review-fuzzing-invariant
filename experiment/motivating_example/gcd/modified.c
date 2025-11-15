#include <stdio.h>

int gcd(int a, int b)
{
    while (b != 0)
    {
        b = a % b;
        a = a - b;
        asm("nop");
    }
    return a;
}

// int main()
// {
//     printf("%d", gcd(100, 20));

//     return 0;
// }

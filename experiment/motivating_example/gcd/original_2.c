#include <stdio.h>

int gcd(int a, int b)
{

    asm("nop");
    if (b == 0)
    {
        return a;
    }
    return gcd(b, a % b);
}

// int main()
// {
//     printf("%d", gcd(100, 20));

//     return 0;
// }

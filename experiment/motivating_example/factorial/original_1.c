#include <stdio.h>

unsigned long factorial(unsigned int n)
{
    unsigned long result = 1;
    for (int i = 1; i <= n; ++i)
    {
        result *= i;
        asm("nop");
    }
    return result;
}

// int main()
// {
//     unsigned int test_values[] = {0, 1, 3, 5, 7};
//     size_t num_tests = sizeof(test_values) / sizeof(test_values[0]);

//     for (size_t i = 0; i < num_tests; ++i)
//     {
//         unsigned int n = test_values[i];
//         unsigned long result = factorial(n);
//         printf("factorial(%u) = %lu\n", n, result);
//     }

//     return 0;
// }
#include <stdio.h>

void reverse_string(char *str)
{
    size_t start = 0;
    size_t end = 0;

    while (str[end] != '\0')
    {
        end++;
    }
    end--;

    while (start < end)
    {
        char temp = str[start];
        str[start] = str[end];
        str[end] = temp;

        start++;
        end--;

        asm("nop");
    }
}

// int main()
// {
//     char str[] = "Hello, World!";
//     printf("Original String: %s\n", str);

//     reverse_string(str);

//     printf("Reversed String: %s\n", str);
//     return 0;
// }

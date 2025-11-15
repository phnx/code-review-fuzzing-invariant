#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "original_1.h"

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
    if (size == 0)
        return 0;

    char *str = (char *)malloc(size + 1);
    if (str == NULL)
        return 0;

    memcpy(str, data, size);
    str[size] = '\0';

    reverse_string(str);
    free(str);

    return 0;
}

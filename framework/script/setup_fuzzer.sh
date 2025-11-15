#!/bin/bash

# DEFAULT LIBFUZZER
export LIB_FUZZING_ENGINE=""
export CC="clang"
export CXX="clang++"

if [ "$FUZZING_TOOL" = "aflplusplus" ]; then
    export LIB_FUZZING_ENGINE="/program/AFLplusplus/libAFLDriver.a"
    export CC="/program/AFLplusplus/afl-clang-fast"
    export CXX="/program/AFLplusplus/afl-clang-fast++"
elif [ "$FUZZING_TOOL" = "honggfuzz" ]; then
    export LIB_FUZZING_ENGINE="/program/honggfuzz/includes/libhfuzz/libhfuzz.a"
    export CC="/program/honggfuzz/hfuzz_cc/hfuzz-clang"
    export CXX="/program/honggfuzz/hfuzz_cc/hfuzz-clang++"
fi

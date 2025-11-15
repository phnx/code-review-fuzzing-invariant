# !/bin/bash

# TODO split fuzz/coverage binary if performance is affected

# BFC
cd $BFC_REPOSITORY_PATH

# copy driver
cp /workdir/fuzz_format_sas7bdat.c $BFC_REPOSITORY_PATH/src/fuzz/fuzz_format_sas7bdat.c

# build coverage target
echo "build BFC coverage target"

# add -Wno-strict-prototypes for clang-15
export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping -fsanitize=fuzzer-no-link -Wno-implicit-const-int-float-conversion -Wno-strict-prototypes -pthread"
export CXXFLAGS=$CFLAGS

# update LIB_FUZZING_ENGINE flag for compilation
if [ "$FUZZING_TOOL" = "libfuzzer" ]; then
    export LIB_FUZZING_ENGINE="/usr/lib/llvm/lib/clang/15.0.7/lib/linux/libclang_rt.fuzzer-x86_64.a"
fi

./autogen.sh
./configure --enable-static

LDFLAGS="-fsanitize=fuzzer -pthread"  make fuzz_format_sas7bdat  

# update binary targets
cp fuzz_format_sas7bdat $BFC_TARGET

# generate corpus
make generate_corpus
./generate_corpus

echo "build BFC coverage target completed"


# BIC
cd $BIC_REPOSITORY_PATH

# copy driver
cp /workdir/fuzz_format_sas7bdat.c $BIC_REPOSITORY_PATH/src/fuzz/fuzz_format_sas7bdat.c

# build coverage target
echo "build BIC coverage target"

# add -Wno-strict-prototypes for clang-15
export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping -fsanitize=fuzzer-no-link -Wno-implicit-const-int-float-conversion -Wno-strict-prototypes -pthread"
export CXXFLAGS=$CFLAGS

# update LIB_FUZZING_ENGINE flag for compilation
if [ "$FUZZING_TOOL" = "libfuzzer" ]; then
    export LIB_FUZZING_ENGINE="/usr/lib/llvm/lib/clang/15.0.7/lib/linux/libclang_rt.fuzzer-x86_64.a"
fi

./autogen.sh
./configure --enable-static

LDFLAGS="-fsanitize=fuzzer -pthread"  make fuzz_format_sas7bdat  

# update binary targets
cp fuzz_format_sas7bdat $BIC_TARGET


echo "build BIC coverage target completed"

# move initial corpus
cd $BFC_REPOSITORY_PATH
set +e
cp corpus/sas7bdat*/test-case-* $INITIAL_SEED_PATH
set -e
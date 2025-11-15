# !/bin/bash

# TODO split fuzz/coverage binary if performance is affected

# BFC
cd $BFC_REPOSITORY_PATH

# copy driver - omit for BFC as it can introduce other failures
# cp /workdir/fuzz_data_producer.c $BFC_REPOSITORY_PATH/tests/fuzz/fuzz_data_producer.c
# cp /workdir/fuzz_data_producer.h $BFC_REPOSITORY_PATH/tests/fuzz/fuzz_data_producer.h
# cp /workdir/fuzz_helpers.h $BFC_REPOSITORY_PATH/tests/fuzz/fuzz_helpers.h
# cp /workdir/stream_decompress.c $BFC_REPOSITORY_PATH/tests/fuzz/stream_decompress.c

# build coverage target
echo "build BFC coverage target"

# declare ZSTD_d_stableOutBuffer to support new driver
export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping -DZSTD_d_stableOutBuffer=0"
export CXXFLAGS=$CFLAGS

# update LIB_FUZZING_ENGINE flag for compilation
if [ "$FUZZING_TOOL" = "libfuzzer" ]; then
    export LIB_FUZZING_ENGINE="/usr/lib/llvm/lib/clang/15.0.7/lib/linux/libclang_rt.fuzzer-x86_64.a"
fi

cd tests/fuzz
python3 ./fuzz.py build stream_decompress --enable-fuzzer

# update target
cp $BFC_REPOSITORY_PATH/tests/fuzz/stream_decompress $BFC_TARGET

echo "build BFC coverage target completed"

# BIC
cd $BIC_REPOSITORY_PATH

# copy driver
cp /workdir/fuzz_data_producer.c $BIC_REPOSITORY_PATH/tests/fuzz/fuzz_data_producer.c
cp /workdir/fuzz_data_producer.h $BIC_REPOSITORY_PATH/tests/fuzz/fuzz_data_producer.h
cp /workdir/fuzz_helpers.h $BIC_REPOSITORY_PATH/tests/fuzz/fuzz_helpers.h
cp /workdir/stream_decompress.c $BIC_REPOSITORY_PATH/tests/fuzz/stream_decompress.c

# build coverage target
echo "build BIC coverage target"

# declare ZSTD_d_stableOutBuffer to support new driver
export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping -DZSTD_d_stableOutBuffer=0"
export CXXFLAGS=$CFLAGS

# update LIB_FUZZING_ENGINE flag for compilation
if [ "$FUZZING_TOOL" = "libfuzzer" ]; then
    export LIB_FUZZING_ENGINE="/usr/lib/llvm/lib/clang/15.0.7/lib/linux/libclang_rt.fuzzer-x86_64.a"
fi

cd tests/fuzz
python3 ./fuzz.py build stream_decompress --enable-fuzzer

# update target
cp $BIC_REPOSITORY_PATH/tests/fuzz/stream_decompress $BIC_TARGET
echo "build BIC coverage target completed"

# generate initial corpus
cd $BFC_REPOSITORY_PATH/tests/fuzz
set  +e
make seedcorpora
unzip $BFC_REPOSITORY_PATH/tests/fuzz/corpora/simple_decompress_seed_corpus.zip -d $INITIAL_SEED_PATH
set -e
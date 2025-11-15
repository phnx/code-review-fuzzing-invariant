# !/bin/bash

# TODO split fuzz/coverage binary if performance is affected

# BFC
cd $BFC_REPOSITORY_PATH

# copy driver
cp /workdir/fuzzer_connect.c $BFC_REPOSITORY_PATH/fuzzer/fuzzer_connect.c
cp /workdir/CMakeLists.txt $BFC_REPOSITORY_PATH/CMakeLists.txt


# build coverage target
echo "build BFC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping -pthread "
export CXXFLAGS=$CFLAGS

cmake -Dsctp_build_programs=0 -Dsctp_debug=1 -Dsctp_invariants=1 -Dsctp_build_fuzzer=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo .
make -j$(nproc)

cd fuzzer

# only build fuzzer_connect driver
$CC $CFLAGS -DFUZZING_STAGE=0 -I . -I ../usrsctplib/ -c fuzzer_connect.c -o fuzzer_connect.o
if [ "$FUZZING_TOOL" = "libfuzzer" ]; then
    $CXX $CXXFLAGS -fsanitize=fuzzer -o $BFC_TARGET fuzzer_connect.o ../usrsctplib/libusrsctp.a
else
    # linking with aflplusplus or honggfuzz emits error without asan
    $CXX $CXXFLAGS -fsanitize=address -o $BFC_TARGET fuzzer_connect.o $LIB_FUZZING_ENGINE ../usrsctplib/libusrsctp.a
fi


echo "build BFC coverage target completed"


# BIC
cd $BIC_REPOSITORY_PATH

# copy driver
cp /workdir/fuzzer_connect.c $BIC_REPOSITORY_PATH/fuzzer/fuzzer_connect.c
cp /workdir/CMakeLists.txt $BIC_REPOSITORY_PATH/CMakeLists.txt


# build coverage target
echo "build BIC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping -pthread "
export CXXFLAGS=$CFLAGS

cmake -Dsctp_build_programs=0 -Dsctp_debug=1 -Dsctp_invariants=1 -Dsctp_build_fuzzer=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo .
make -j$(nproc)

cd fuzzer

# only build fuzzer_connect driver
$CC $CFLAGS -DFUZZING_STAGE=0 -I . -I ../usrsctplib/ -c fuzzer_connect.c -o fuzzer_connect.o
if [ "$FUZZING_TOOL" = "libfuzzer" ]; then
    $CXX $CXXFLAGS -fsanitize=fuzzer -o $BIC_TARGET fuzzer_connect.o ../usrsctplib/libusrsctp.a
else
    # linking with aflplusplus or honggfuzz emits error without asan
    $CXX $CXXFLAGS -fsanitize=address -o $BIC_TARGET fuzzer_connect.o $LIB_FUZZING_ENGINE ../usrsctplib/libusrsctp.a
fi


echo "build BIC coverage target completed"



# generate initial corpus
cp $BFC_REPOSITORY_PATH/fuzzer/CORPUS_CONNECT/* $INITIAL_SEED_PATH
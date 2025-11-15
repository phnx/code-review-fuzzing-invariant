# !/bin/bash

# build dependency
cd /workdir/libpcap/
CC=clang CXX=clang++ ./configure
make -j$(nproc)


# TODO split fuzz/coverage binary if performance is affected


# BFC
cd $BFC_REPOSITORY_PATH

# copy driver
cp /workdir/FuzzTarget.cpp $BFC_REPOSITORY_PATH/Tests/Fuzzers/FuzzTarget.cpp

# build coverage target
echo "build BFC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

./configure-fuzzing.sh --libpcap-static-lib-dir /workdir/libpcap/
make clean
make -j$(nproc) fuzzers

# update target and other libs
cp $BFC_REPOSITORY_PATH/Tests/Fuzzers/Bin/FuzzTarget $BFC_BINARY_PATH/FuzzTarget
cp $(ldd $BFC_BINARY_PATH/FuzzTarget | cut -d" " -f3) $BFC_BINARY_PATH
cp $BFC_BINARY_PATH/FuzzTarget $BFC_TARGET

echo "BFC target completed"

# BIC
cd $BIC_REPOSITORY_PATH

# copy driver
cp /workdir/FuzzTarget.cpp $BIC_REPOSITORY_PATH/Tests/Fuzzers/FuzzTarget.cpp

# build coverage target
echo "build BIC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

./configure-fuzzing.sh --libpcap-static-lib-dir /workdir/libpcap/
make clean
make -j$(nproc) fuzzers

# update target and other libs
cp $BIC_REPOSITORY_PATH/Tests/Fuzzers/Bin/FuzzTarget $BIC_BINARY_PATH/FuzzTarget
cp $(ldd $BIC_BINARY_PATH/FuzzTarget | cut -d" " -f3) $BIC_BINARY_PATH
cp $BIC_BINARY_PATH/FuzzTarget $BIC_TARGET

echo "BIC target completed"

# collect initial corpus
cp /workdir/tcpdump/tests/*.pcap $INITIAL_SEED_PATH

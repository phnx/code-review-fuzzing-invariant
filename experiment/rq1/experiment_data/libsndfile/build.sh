# !/bin/bash

# TODO split fuzz/coverage binary if performance is affected


# BIC
# not enable magma fix for BIC
echo "Build Magma BIC"

cd $BIC_REPOSITORY_PATH

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

./autogen.sh
./configure --disable-shared --enable-ossfuzzers
make -j$(nproc) clean
make -j$(nproc) ossfuzz/sndfile_fuzzer

mv ossfuzz/sndfile_fuzzer $BIC_TARGET

echo "Build Magma BIC completed"

# BFC
echo "Build Magma BFC"

cd $BFC_REPOSITORY_PATH

# enable magma fix for BFC
export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping -DMAGMA_ENABLE_FIXES"
export CXXFLAGS=$CFLAGS

./autogen.sh
./configure --disable-shared --enable-ossfuzzers
make -j$(nproc) clean
make -j$(nproc) ossfuzz/sndfile_fuzzer

mv ossfuzz/sndfile_fuzzer $BFC_TARGET

echo "Build Magma BFC completed"
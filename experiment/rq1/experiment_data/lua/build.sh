# !/bin/bash

# TODO split fuzz/coverage binary if performance is affected


# BIC
# not enable magma fix for BIC

echo "Build Magma BIC"

cd $BIC_REPOSITORY_PATH

# enable asm for c99
export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping -fasm"
export CXXFLAGS=$CFLAGS

make -j$(nproc) clean
make -j$(nproc) liblua.a

cp liblua.a "$BIC_BINARY_PATH/"
make -j$(nproc) lua
mv lua "$BIC_TARGET"

echo "Build Magma BIC completed"

# BFC
echo "Build Magma BFC"

cd $BFC_REPOSITORY_PATH

# enable magma fix for BFC
# enable asm for c99
export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping -fasm -DMAGMA_ENABLE_FIXES=1"
export CXXFLAGS=$CFLAGS

make -j$(nproc) clean
make -j$(nproc) liblua.a

cp liblua.a "$BFC_BINARY_PATH/"
make -j$(nproc) lua
mv lua "$BFC_TARGET"


echo "Build Magma BFC completed"
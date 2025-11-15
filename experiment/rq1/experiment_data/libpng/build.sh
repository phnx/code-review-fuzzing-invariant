# !/bin/bash

# TODO split fuzz/coverage binary if performance is affected


# BIC
# not set magma fix for BIC
echo "Build Magma BIC"

cd $BIC_REPOSITORY_PATH

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

autoreconf -f -i
./configure --with-libpng-prefix=MAGMA_ --disable-shared
make -j$(nproc) clean
make -j$(nproc) libpng16.la

cp .libs/libpng16.a "$BIC_BINARY_PATH"

# build libpng_read_fuzzer.
$CXX $CXXFLAGS -std=c++11 -fsanitize=fuzzer -include cstdlib -I. \
     contrib/oss-fuzz/libpng_read_fuzzer.cc \
     -o $BIC_TARGET \
     $LDFLAGS .libs/libpng16.a $LIBS $LIB_FUZZING_ENGINE -lz

echo "Build Magma BIC completed"

# BFC
echo "Build Magma BFC"

cd $BFC_REPOSITORY_PATH

# enable magma fix for BFC
export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping -DMAGMA_ENABLE_FIXES"
export CXXFLAGS=$CFLAGS

autoreconf -f -i
./configure --with-libpng-prefix=MAGMA_ --disable-shared
make -j$(nproc) clean
make -j$(nproc) libpng16.la

cp .libs/libpng16.a "$BFC_BINARY_PATH"

# build libpng_read_fuzzer.
$CXX $CXXFLAGS -std=c++11 -fsanitize=fuzzer -include cstdlib -I. \
     contrib/oss-fuzz/libpng_read_fuzzer.cc \
     -o $BFC_TARGET \
     $LDFLAGS .libs/libpng16.a $LIBS $LIB_FUZZING_ENGINE -lz

echo "Build Magma BFC completed"


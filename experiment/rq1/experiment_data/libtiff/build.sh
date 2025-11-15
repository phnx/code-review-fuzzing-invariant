# !/bin/bash

# TODO split fuzz/coverage binary if performance is affected


# BIC
# not enable magma fix for BIC
echo "Build Magma BIC"

cd $BIC_REPOSITORY_PATH

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

WORK="$BIC_REPOSITORY_PATH/work"
rm -rf "$WORK"
mkdir -p "$WORK"
mkdir -p "$WORK/lib" "$WORK/include"

./autogen.sh
./configure --disable-shared --prefix="$WORK"
make -j$(nproc) clean
make -j$(nproc)
make install

cp "$WORK/bin/tiffcp" "$BIC_BINARY_PATH"
$CXX $CXXFLAGS -std=c++11 -fsanitize=fuzzer -I$WORK/include \
    $BIC_REPOSITORY_PATH/contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc -o $BIC_TARGET \
    $WORK/lib/libtiffxx.a $WORK/lib/libtiff.a -lz -ljpeg -ljbig -Wl,-Bstatic -llzma -Wl,-Bdynamic \
    $LDFLAGS $LIBS $LIB_FUZZING_ENGINE

echo "Build Magma BIC completed"

# BFC
echo "Build Magma BFC"

cd $BFC_REPOSITORY_PATH

# enable magma fix for BFC
export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping -DMAGMA_ENABLE_FIXES"
export CXXFLAGS=$CFLAGS

WORK="$BFC_REPOSITORY_PATH/work"
rm -rf "$WORK"
mkdir -p "$WORK"
mkdir -p "$WORK/lib" "$WORK/include"

./autogen.sh
./configure --disable-shared --prefix="$WORK"
make -j$(nproc) clean
make -j$(nproc)
make install

cp "$WORK/bin/tiffcp" "$BFC_BINARY_PATH"
$CXX $CXXFLAGS -std=c++11 -fsanitize=fuzzer -I$WORK/include \
    $BFC_REPOSITORY_PATH/contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc -o $BFC_TARGET \
    $WORK/lib/libtiffxx.a $WORK/lib/libtiff.a -lz -ljpeg -ljbig -Wl,-Bstatic -llzma -Wl,-Bdynamic \
    $LDFLAGS $LIBS $LIB_FUZZING_ENGINE

echo "Build Magma BFC completed"

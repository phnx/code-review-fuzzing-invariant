# !/bin/bash

# dependency
export DEPS="/deps"
rm -rf "$DEPS"
mkdir -p "$DEPS"
mkdir -p "$DEPS/lib" "$DEPS/include"

pushd "/workdir/freetype2"
./autogen.sh
./configure --prefix="$DEPS" --disable-shared PKG_CONFIG_PATH="$DEPS/lib/pkgconfig"
make -j$(nproc) clean
make -j$(nproc)
make install

# TODO split fuzz/coverage binary if performance is affected

# BIC

# not enable magma fix for BIC
echo "Build Magma BIC"

mkdir -p $BIC_REPOSITORY_PATH/build
cd $BIC_REPOSITORY_PATH/build
rm -rf *

EXTRA=""
test -n "$AR" && EXTRA="$EXTRA -DCMAKE_AR=$AR"
test -n "$RANLIB" && EXTRA="$EXTRA -DCMAKE_RANLIB=$RANLIB"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

# NOTE check -DICONV_LIBRARIES="/usr/lib/x86_64-linux-gnu/libc.so" \
cmake "$BIC_REPOSITORY_PATH" \
  $EXTRA \
  -DCMAKE_BUILD_TYPE=debug \
  -DBUILD_SHARED_LIBS=OFF \
  -DFONT_CONFIGURATION=generic \
  -DBUILD_GTK_TESTS=OFF \
  -DBUILD_QT5_TESTS=OFF \
  -DBUILD_CPP_TESTS=OFF \
  -DENABLE_LIBPNG=ON \
  -DENABLE_LIBTIFF=ON \
  -DENABLE_LIBJPEG=ON \
  -DENABLE_SPLASH=ON \
  -DENABLE_UTILS=ON \
  -DWITH_Cairo=ON \
  -DENABLE_CMS=none \
  -DENABLE_LIBCURL=OFF \
  -DENABLE_GLIB=OFF \
  -DENABLE_GOBJECT_INTROSPECTION=OFF \
  -DENABLE_QT5=OFF \
  -DENABLE_LIBCURL=OFF \
  -DWITH_NSS3=OFF \
  -DFREETYPE_INCLUDE_DIRS="$DEPS/include/freetype2" \
  -DFREETYPE_LIBRARY="$DEPS/lib/libfreetype.a" \
  -DICONV_LIBRARIES="/usr/lib/x86_64-linux-gnu/libc.so" \
  -DCMAKE_EXE_LINKER_FLAGS_INIT="$LIBS"
make -j$(nproc) poppler poppler-cpp pdfimages pdftoppm
EXTRA=""

cp "$BIC_REPOSITORY_PATH/build/utils/"{pdfimages,pdftoppm} "$BIC_BINARY_PATH"/
$CXX $CXXFLAGS -std=c++11 -fsanitize=fuzzer -I"$BIC_REPOSITORY_PATH/build/cpp" -I"$BIC_REPOSITORY_PATH/cpp" \
    "/magma/targets/poppler/src/pdf_fuzzer.cc" -o "$BIC_TARGET" \
    "$BIC_REPOSITORY_PATH/build/cpp/libpoppler-cpp.a" "$BIC_REPOSITORY_PATH/build/libpoppler.a" \
    "$DEPS/lib/libfreetype.a" $LDFLAGS $LIBS $LIB_FUZZING_ENGINE -ljpeg -lz \
    -lopenjp2 -lpng -ltiff -llcms2 -lm -lpthread -pthread

echo "Build Magma BIC completed"

# BFC

mkdir -p $BFC_REPOSITORY_PATH/build
cd $BFC_REPOSITORY_PATH/build
rm -rf *

EXTRA=""
test -n "$AR" && EXTRA="$EXTRA -DCMAKE_AR=$AR"
test -n "$RANLIB" && EXTRA="$EXTRA -DCMAKE_RANLIB=$RANLIB"

# enable magma fix for BFC
export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping -DMAGMA_ENABLE_FIXES"
export CXXFLAGS=$CFLAGS

cmake "$BFC_REPOSITORY_PATH" \
  $EXTRA \
  -DCMAKE_BUILD_TYPE=debug \
  -DBUILD_SHARED_LIBS=OFF \
  -DFONT_CONFIGURATION=generic \
  -DBUILD_GTK_TESTS=OFF \
  -DBUILD_QT5_TESTS=OFF \
  -DBUILD_CPP_TESTS=OFF \
  -DENABLE_LIBPNG=ON \
  -DENABLE_LIBTIFF=ON \
  -DENABLE_LIBJPEG=ON \
  -DENABLE_SPLASH=ON \
  -DENABLE_UTILS=ON \
  -DWITH_Cairo=ON \
  -DENABLE_CMS=none \
  -DENABLE_LIBCURL=OFF \
  -DENABLE_GLIB=OFF \
  -DENABLE_GOBJECT_INTROSPECTION=OFF \
  -DENABLE_QT5=OFF \
  -DENABLE_LIBCURL=OFF \
  -DWITH_NSS3=OFF \
  -DFREETYPE_INCLUDE_DIRS="$DEPS/include/freetype2" \
  -DFREETYPE_LIBRARY="$DEPS/lib/libfreetype.a" \
  -DICONV_LIBRARIES="/usr/lib/x86_64-linux-gnu/libc.so" \
  -DCMAKE_EXE_LINKER_FLAGS_INIT="$LIBS"
make -j$(nproc) poppler poppler-cpp pdfimages pdftoppm
EXTRA=""

cp "$BFC_REPOSITORY_PATH/build/utils/"{pdfimages,pdftoppm} "$BFC_BINARY_PATH"/
$CXX $CXXFLAGS -std=c++11 -fsanitize=fuzzer -I"$BFC_REPOSITORY_PATH/build/cpp" -I"$BFC_REPOSITORY_PATH/cpp" \
    "/magma/targets/poppler/src/pdf_fuzzer.cc" -o "$BFC_TARGET" \
    "$BFC_REPOSITORY_PATH/build/cpp/libpoppler-cpp.a" "$BFC_REPOSITORY_PATH/build/libpoppler.a" \
    "$DEPS/lib/libfreetype.a" $LDFLAGS $LIBS $LIB_FUZZING_ENGINE -ljpeg -lz \
    -lopenjp2 -lpng -ltiff -llcms2 -lm -lpthread -pthread

echo "Build Magma BFC completed"

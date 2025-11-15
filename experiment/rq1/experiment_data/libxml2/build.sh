# !/bin/bash

# TODO split fuzz/coverage binary if performance is affected


# BIC
# not enable magma fix for BIC

echo "Build Magma BIC"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

cd "$BIC_REPOSITORY_PATH"

./autogen.sh \
	--with-http=no \
	--with-python=no \
	--with-lzma=yes \
	--with-threads=no \
	--disable-shared
make -j$(nproc) clean
make -j$(nproc) all

cp xmllint "$BIC_BINARY_PATH"

# TODO enable multiple targets fuzzing
for fuzzer in libxml2_xml_read_memory_fuzzer libxml2_xml_reader_for_file_fuzzer; do
  $CXX $CXXFLAGS -std=c++11 -fsanitize=fuzzer -Iinclude/ -I"$TARGET/src/" \
      "/magma/targets/libxml2/src/$fuzzer.cc" -o "$BIC_BINARY_PATH/$fuzzer" \
      .libs/libxml2.a $LDFLAGS $LIBS $LIB_FUZZING_ENGINE -lz -llzma
done

# select highest coverage target
cp $BIC_BINARY_PATH/report_libxml2_xml_read_memory_fuzzer $BIC_TARGET

echo "Build Magma BIC completed"

# BFC
echo "Build Magma BFC"

# enable magma fix for BFC
export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping -DMAGMA_ENABLE_FIXES"
export CXXFLAGS=$CFLAGS

cd "$BFC_REPOSITORY_PATH"

./autogen.sh \
	--with-http=no \
	--with-python=no \
	--with-lzma=yes \
	--with-threads=no \
	--disable-shared
make -j$(nproc) clean
make -j$(nproc) all

cp xmllint "$BFC_BINARY_PATH"

# TODO enable multiple targets fuzzing
for fuzzer in libxml2_xml_read_memory_fuzzer libxml2_xml_reader_for_file_fuzzer; do
  $CXX $CXXFLAGS -std=c++11 -fsanitize=fuzzer -Iinclude/ -I"$TARGET/src/" \
      "/magma/targets/libxml2/src/$fuzzer.cc" -o "$BFC_BINARY_PATH/$fuzzer" \
      .libs/libxml2.a $LDFLAGS $LIBS $LIB_FUZZING_ENGINE -lz -llzma
done

# select highest coverage target
cp $BFC_BINARY_PATH/report_libxml2_xml_read_memory_fuzzer $BFC_TARGET


echo "Build Magma BFC completed"

# !/bin/bash

# TODO split fuzz/coverage binary if performance is affected

# BFC
cd $BFC_REPOSITORY_PATH

# copy driver
cp /workdir/libxml2_xml_reader_for_file_fuzzer.cc $BFC_REPOSITORY_PATH/libxml2_xml_reader_for_file_fuzzer.cc
cp /workdir/fuzzer_temp_file.h $BFC_REPOSITORY_PATH/fuzzer_temp_file.h

# build coverage target
echo "build BFC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS


./autogen.sh
./configure --with-http=no
make clean
make -j$(nproc) all

# link one fuzzer
$CXX $CXXFLAGS -std=c++11 -fsanitize=fuzzer  -Iinclude/ \
      $BFC_REPOSITORY_PATH/libxml2_xml_reader_for_file_fuzzer.cc -o $BFC_TARGET \
      $LIB_FUZZING_ENGINE .libs/libxml2.a -lz -llzma

echo "BFC target completed"

# BIC
cd $BIC_REPOSITORY_PATH

# copy driver
cp /workdir/libxml2_xml_reader_for_file_fuzzer.cc $BIC_REPOSITORY_PATH/libxml2_xml_reader_for_file_fuzzer.cc
cp /workdir/fuzzer_temp_file.h $BIC_REPOSITORY_PATH/fuzzer_temp_file.h

# build coverage target
echo "build BFC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

./autogen.sh
./configure --with-http=no
make clean
make -j$(nproc) all

# link one fuzzer
$CXX $CXXFLAGS -std=c++11 -fsanitize=fuzzer  -Iinclude/ \
      $BIC_REPOSITORY_PATH/libxml2_xml_reader_for_file_fuzzer.cc -o $BIC_TARGET \
      $LIB_FUZZING_ENGINE .libs/libxml2.a -lz -llzma

echo "BIC target completed"

# collect initial corpus
cp -r $BFC_REPOSITORY_PATH/test/* $INITIAL_SEED_PATH

# collect dictionary
export INITIAL_DICTIONARY="/workdir/xml.dict"

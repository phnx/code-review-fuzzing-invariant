# !/bin/bash


# build pre-requisite libxml2 for both BIC and BFC
cd /workdir/libxml2
./autogen.sh \
    --without-debug \
    --without-ftp \
    --without-http \
    --without-legacy \
    --without-python

make -j$(nproc)


# BFC
cd $BFC_REPOSITORY_PATH

sed -i 's/-Wall//g' ./CMakeLists.txt
sed -i 's/-Werror//g' ./CMakeLists.txt

# copy driver
cp /workdir/libarchive_fuzzer.cc $BFC_REPOSITORY_PATH/libarchive_fuzzer.cc

# build coverage target
echo "build BFC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

mkdir build2
cd build2
cmake ../
make

$CXX $CXXFLAGS -I../libarchive \
    ../libarchive_fuzzer.cc -o $BFC_TARGET \
    -fsanitize=fuzzer ./libarchive/libarchive.a \
    $LIB_FUZZING_ENGINE -lcrypto -lacl -llzma -llz4 -lbz2 -lz -lzstd /workdir/libxml2/.libs/libxml2.a

echo "BFC coverage target completed"

# BIC
cd $BIC_REPOSITORY_PATH

sed -i 's/-Wall//g' ./CMakeLists.txt
sed -i 's/-Werror//g' ./CMakeLists.txt

# copy driver
cp /workdir/libarchive_fuzzer.cc $BIC_REPOSITORY_PATH/libarchive_fuzzer.cc

# build coverage target
echo "build BIC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

mkdir build2
cd build2
cmake ../
make

$CXX $CXXFLAGS -I../libarchive \
    ../libarchive_fuzzer.cc -o $BIC_TARGET \
    -fsanitize=fuzzer ./libarchive/libarchive.a \
    $LIB_FUZZING_ENGINE -lcrypto -lacl -llzma -llz4 -lbz2 -lz -lzstd /workdir/libxml2/.libs/libxml2.a

echo "BIC coverage target completed"

# collect initial corpus
unzip $BFC_REPOSITORY_PATH/contrib/oss-fuzz/corpus.zip -d $INITIAL_SEED_PATH

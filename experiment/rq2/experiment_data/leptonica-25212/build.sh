# !/bin/bash

# TODO split fuzz/coverage binary if performance is affected

# BFC
cd $BFC_REPOSITORY_PATH

# copy driver - just in case
cp /workdir/pix4_fuzzer.cc $BFC_REPOSITORY_PATH/prog/fuzzing/pix4_fuzzer.cc

# build coverage target
echo "build BFC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION"
export CXXFLAGS=$CFLAGS

./autogen.sh
./configure \
  --enable-static \
  --disable-shared \
  --with-libpng \
  --with-zlib \
  --with-jpeg \
  --with-libwebp \
  --with-libtiff 


# build local fuzzers
# automatically use LIB_FUZZING_ENGINE if set
make fuzzers

# update target
cp pix4_fuzzer $BFC_TARGET

echo "build BFC completed"


# BIC
cd $BIC_REPOSITORY_PATH

# copy driver - just in case
cp /workdir/pix4_fuzzer.cc $BIC_REPOSITORY_PATH/prog/fuzzing/pix4_fuzzer.cc

# build coverage target
echo "build BIC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION"
export CXXFLAGS=$CFLAGS

./autogen.sh
./configure \
  --enable-static \
  --disable-shared \
  --with-libpng \
  --with-zlib \
  --with-jpeg \
  --with-libwebp \
  --with-libtiff 


# build local fuzzers
# automatically use LIB_FUZZING_ENGINE if set
make fuzzers

# update target
cp pix4_fuzzer $BIC_TARGET

echo "build BIC completed"

# collect initial corpus
unzip $BFC_REPOSITORY_PATH/prog/fuzzing/general_corpus.zip -d $INITIAL_SEED_PATH

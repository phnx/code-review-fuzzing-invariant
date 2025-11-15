# !/bin/bash

# BFC
cd $BFC_REPOSITORY_PATH

# copy driver
cp /workdir/grk_decompress_fuzzer.cpp ./tests/fuzzers/grk_decompress_fuzzer.cpp

# build coverage target
echo "build BFC coverage target"
mkdir build
cd build

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

cmake .. -DGRK_BUILD_CODEC=OFF -DBUILD_SHARED_LIBS=OFF -DGRK_BUILD_THIRDPARY=ON
make clean -s
make -j$(nproc) -s
cd ..

echo "link BFC coverage target"
# build_google_oss_fuzzers.sh - run in grok root
$CXX $CXXFLAGS -fsanitize=fuzzer -std=c++11 -I./src/lib/jp2 -I./build/src/lib/jp2 \
        ./tests/fuzzers/grk_decompress_fuzzer.cpp $* -o $BFC_TARGET \
        $LIB_FUZZING_ENGINE ./build/bin/libgrokj2k.a -lm -lpthread


echo "build BFC coverage target completed"

# BIC
cd $BIC_REPOSITORY_PATH

# copy driver
cp /workdir/grk_decompress_fuzzer.cpp ./tests/fuzzers/grk_decompress_fuzzer.cpp

# build coverage target
echo "build BIC coverage target"
mkdir build
cd build

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

cmake .. -DGRK_BUILD_CODEC=OFF -DBUILD_SHARED_LIBS=OFF -DGRK_BUILD_THIRDPARY=ON
make clean -s
make -j$(nproc) -s
cd ..


echo "link BIC fuzz target"
# build_google_oss_fuzzers.sh - run in grok root
$CXX $CXXFLAGS -fsanitize=fuzzer -std=c++11 -I./src/lib/jp2 -I./build/src/lib/jp2 \
        ./tests/fuzzers/grk_decompress_fuzzer.cpp $* -o $BIC_TARGET \
        $LIB_FUZZING_ENGINE ./build/bin/libgrokj2k.a -lm -lpthread


echo "build BIC coverage target completed"

# collect initial corpus
cp $BFC_REPOSITORY_PATH/grok/data/input/conformance/*.jp2 $INITIAL_SEED_PATH
cp $BFC_REPOSITORY_PATH/grok/data/input/conformance/*.j2k $INITIAL_SEED_PATH
cp $BFC_REPOSITORY_PATH/grok/data/input/nonregression/*.jp2 $INITIAL_SEED_PATH
cp $BFC_REPOSITORY_PATH/grok/data/input/nonregression/*.j2k $INITIAL_SEED_PATH

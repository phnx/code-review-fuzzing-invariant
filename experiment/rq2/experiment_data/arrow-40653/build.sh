# !/bin/bash


# dependency
# oss-fuzz: Install Boost headers
# (
#  cd /workdir/boost_1_85_0/
#  CFLAGS="" CXXFLAGS="" ./bootstrap.sh
#  CFLAGS="" CXXFLAGS="" ./b2 headers
#  cp -R boost/ /usr/include/
# )


# BFC
rm -rf /workdir/arrow_build
mkdir -p /workdir/arrow_build

cd /workdir/arrow_build
ARROW=$BFC_REPOSITORY_PATH/cpp

# copy driver
cp /workdir/file_fuzz.cc $BFC_REPOSITORY_PATH/cpp/src/arrow/ipc/file_fuzz.cc

# build coverage target
echo "build BFC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS
# export ASAN_OPTIONS="detect_leaks=0"


cmake ${ARROW} -GNinja \
    -DCMAKE_BUILD_TYPE=Debug \
    -DARROW_DEPENDENCY_SOURCE=BUNDLED \
    -DBOOST_SOURCE=SYSTEM \
    -DCMAKE_C_FLAGS="${CFLAGS}" \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
    -DARROW_EXTRA_ERROR_CONTEXT=off \
    -DARROW_JEMALLOC=off \
    -DARROW_MIMALLOC=off \
    -DARROW_FILESYSTEM=off \
    -DARROW_PARQUET=on \
    -DARROW_BUILD_SHARED=off \
    -DARROW_BUILD_STATIC=on \
    -DARROW_BUILD_TESTS=off \
    -DARROW_BUILD_INTEGRATION=off \
    -DARROW_BUILD_BENCHMARKS=off \
    -DARROW_BUILD_EXAMPLES=off \
    -DARROW_BUILD_UTILITIES=off \
    -DARROW_TEST_LINKAGE=static \
    -DPARQUET_BUILD_EXAMPLES=off \
    -DPARQUET_BUILD_EXECUTABLES=off \
    -DPARQUET_REQUIRE_ENCRYPTION=off \
    -DARROW_WITH_BROTLI=on \
    -DARROW_WITH_BZ2=off \
    -DARROW_WITH_LZ4=off \
    -DARROW_WITH_SNAPPY=on \
    -DARROW_WITH_ZLIB=on \
    -DARROW_WITH_ZSTD=on \
    -DARROW_USE_GLOG=off \
    -DARROW_USE_ASAN=off \
    -DARROW_USE_UBSAN=off \
    -DARROW_USE_TSAN=off \
    -DARROW_FUZZING=on

cmake --build .
cp -a debug/* $BFC_BINARY_PATH

# update BFC fuzz target
cp $BFC_BINARY_PATH/arrow-ipc-file-fuzz $BFC_TARGET

echo "build BFC coverage target completed"

# BIC
rm -rf /workdir/arrow_build
mkdir -p /workdir/arrow_build

cd /workdir/arrow_build
ARROW=$BIC_REPOSITORY_PATH/cpp

# copy driver
cp /workdir/file_fuzz.cc $BIC_REPOSITORY_PATH/cpp/src/arrow/ipc/file_fuzz.cc

# build coverage target
echo "build BIC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS
# export ASAN_OPTIONS="detect_leaks=0"


cmake ${ARROW} -GNinja \
    -DCMAKE_BUILD_TYPE=Debug \
    -DARROW_DEPENDENCY_SOURCE=BUNDLED \
    -DBOOST_SOURCE=SYSTEM \
    -DCMAKE_C_FLAGS="${CFLAGS}" \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
    -DARROW_EXTRA_ERROR_CONTEXT=off \
    -DARROW_JEMALLOC=off \
    -DARROW_MIMALLOC=off \
    -DARROW_FILESYSTEM=off \
    -DARROW_PARQUET=on \
    -DARROW_BUILD_SHARED=off \
    -DARROW_BUILD_STATIC=on \
    -DARROW_BUILD_TESTS=off \
    -DARROW_BUILD_INTEGRATION=off \
    -DARROW_BUILD_BENCHMARKS=off \
    -DARROW_BUILD_EXAMPLES=off \
    -DARROW_BUILD_UTILITIES=off \
    -DARROW_TEST_LINKAGE=static \
    -DPARQUET_BUILD_EXAMPLES=off \
    -DPARQUET_BUILD_EXECUTABLES=off \
    -DPARQUET_REQUIRE_ENCRYPTION=off \
    -DARROW_WITH_BROTLI=on \
    -DARROW_WITH_BZ2=off \
    -DARROW_WITH_LZ4=off \
    -DARROW_WITH_SNAPPY=on \
    -DARROW_WITH_ZLIB=on \
    -DARROW_WITH_ZSTD=on \
    -DARROW_USE_GLOG=off \
    -DARROW_USE_ASAN=off \
    -DARROW_USE_UBSAN=off \
    -DARROW_USE_TSAN=off \
    -DARROW_FUZZING=on

cmake --build .
cp -a debug/* $BIC_BINARY_PATH

# update BIC fuzz target
cp $BIC_BINARY_PATH/arrow-ipc-file-fuzz $BIC_TARGET

echo "build BIC coverage target completed"

# generate initial corpus
set +e
bash $BFC_REPOSITORY_PATH/cpp/build-support/fuzzing/generate_corpuses.sh $BFC_BINARY_PATH
unzip $BFC_BINARY_PATH/arrow-ipc-file-fuzz_seed_corpus.zip -d $INITIAL_SEED_PATH
set -e
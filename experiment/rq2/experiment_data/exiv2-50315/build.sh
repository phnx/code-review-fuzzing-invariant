# !/bin/bash

# TODO split fuzz/coverage binary if performance is affected

# BFC
cd $BFC_REPOSITORY_PATH

# copy driver
cp /workdir/fuzz-read-print-write.cpp ./fuzz/fuzz-read-print-write.cpp

# build coverage target
echo "build BFC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS
CXXFLAGS="${CXXFLAGS} -fno-sanitize=float-divide-by-zero"

mkdir -p build
cd build

# NOTE exclude -DEXIV2_TEAM_OSS_FUZZ=ON when not using -DLIB_FUZZING_ENGINE="${LIB_FUZZING_ENGINE}"
if [ "$FUZZING_TOOL" = "aflplusplus" ] || [ "$FUZZING_TOOL" = "honggfuzz" ]; then
    cmake \
        -DEXIV2_ENABLE_PNG=ON \
        -DEXIV2_ENABLE_WEBREADY=ON \
        -DEXIV2_ENABLE_CURL=OFF \
        -DEXIV2_ENABLE_BMFF=ON \
        -DEXIV2_TEAM_WARNINGS_AS_ERRORS=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_CXX_COMPILER="${CXX}" \
        -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
        -DEXIV2_BUILD_FUZZ_TESTS=ON \
        -DEXIV2_TEAM_OSS_FUZZ=ON \
        -DLIB_FUZZING_ENGINE="${LIB_FUZZING_ENGINE}" \
        ..
else
    cmake \
        -DEXIV2_ENABLE_PNG=ON \
        -DEXIV2_ENABLE_WEBREADY=ON \
        -DEXIV2_ENABLE_CURL=OFF \
        -DEXIV2_ENABLE_BMFF=ON \
        -DEXIV2_TEAM_WARNINGS_AS_ERRORS=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_CXX_COMPILER="${CXX}" \
        -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
        -DEXIV2_BUILD_FUZZ_TESTS=ON \
        ..
fi
make -j$(nproc)

# update target
cp ./bin/fuzz-read-print-write $BFC_BINARY_PATH
cp $BFC_BINARY_PATH/fuzz-read-print-write $BFC_TARGET

# BIC
cd $BIC_REPOSITORY_PATH

# copy driver
cp /workdir/fuzz-read-print-write.cpp ./fuzz/fuzz-read-print-write.cpp

# build coverage target
echo "build BIC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS
CXXFLAGS="${CXXFLAGS} -fno-sanitize=float-divide-by-zero"

mkdir -p build
cd build

# NOTE exclude -DEXIV2_TEAM_OSS_FUZZ=ON when not using -DLIB_FUZZING_ENGINE="${LIB_FUZZING_ENGINE}"
if [ "$FUZZING_TOOL" = "aflplusplus" ] || [ "$FUZZING_TOOL" = "honggfuzz" ]; then
    cmake \
        -DEXIV2_ENABLE_PNG=ON \
        -DEXIV2_ENABLE_WEBREADY=ON \
        -DEXIV2_ENABLE_CURL=OFF \
        -DEXIV2_ENABLE_BMFF=ON \
        -DEXIV2_TEAM_WARNINGS_AS_ERRORS=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_CXX_COMPILER="${CXX}" \
        -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
        -DEXIV2_BUILD_FUZZ_TESTS=ON \
        -DEXIV2_TEAM_OSS_FUZZ=ON \
        -DLIB_FUZZING_ENGINE="${LIB_FUZZING_ENGINE}" \
        ..
else
    cmake \
        -DEXIV2_ENABLE_PNG=ON \
        -DEXIV2_ENABLE_WEBREADY=ON \
        -DEXIV2_ENABLE_CURL=OFF \
        -DEXIV2_ENABLE_BMFF=ON \
        -DEXIV2_TEAM_WARNINGS_AS_ERRORS=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_CXX_COMPILER="${CXX}" \
        -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
        -DEXIV2_BUILD_FUZZ_TESTS=ON \
        ..
fi

make -j$(nproc)

# update target
cp ./bin/fuzz-read-print-write $BIC_BINARY_PATH
cp $BIC_BINARY_PATH/fuzz-read-print-write $BIC_TARGET


# collect initial corpus
for f in $(find $BFC_REPOSITORY_PATH/test/data -type f -size -20k); do
    s=$(sha1sum "$f" | awk '{print $1}')
    cp $f $INITIAL_SEED_PATH/$s
done

# collect dictionary
export INITIAL_DICTIONARY="/workdir/fuzz-read-print-write.dict"
cp $BFC_REPOSITORY_PATH/fuzz/exiv2.dict $INITIAL_DICTIONARY

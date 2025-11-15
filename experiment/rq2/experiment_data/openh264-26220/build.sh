# !/bin/bash

# TODO split fuzz/coverage binary if performance is affected

# BFC
cd $BFC_REPOSITORY_PATH

# copy driver
cp /workdir/decoder_fuzzer.cpp $BFC_REPOSITORY_PATH/decoder_fuzzer.cpp

# build coverage target
echo "build BFC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

make -j$(nproc) ARCH=$ARCHITECTURE USE_ASM=Yes BUILDTYPE=Debug libraries


# update linking flag for libfuzzer
if [ "$FUZZING_TOOL" = "libfuzzer" ]; then
    $CXX $CXXFLAGS -fsanitize=fuzzer  \
        -o $BFC_TARGET -I./codec/api/svc \
        -I./codec/console/common/inc -I./codec/common/inc -L. \
        $LIB_FUZZING_ENGINE $BFC_REPOSITORY_PATH/decoder_fuzzer.cpp libopenh264.a
else
    $CXX $CXXFLAGS \
        -o $BFC_TARGET -I./codec/api/svc \
        -I./codec/console/common/inc -I./codec/common/inc -L. \
        $LIB_FUZZING_ENGINE $BFC_REPOSITORY_PATH/decoder_fuzzer.cpp libopenh264.a -pthread
fi

echo "build BFC coverage target completed"


# BIC
cd $BIC_REPOSITORY_PATH

# copy driver
cp /workdir/decoder_fuzzer.cpp $BIC_REPOSITORY_PATH/decoder_fuzzer.cpp

# build coverage target
echo "build BIC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

make -j$(nproc) ARCH=$ARCHITECTURE USE_ASM=Yes BUILDTYPE=Debug libraries


# update linking flag for libfuzzer
if [ "$FUZZING_TOOL" = "libfuzzer" ]; then
    $CXX $CXXFLAGS -fsanitize=fuzzer  \
        -o $BIC_TARGET -I./codec/api/svc \
        -I./codec/console/common/inc -I./codec/common/inc -L. \
        $LIB_FUZZING_ENGINE $BIC_REPOSITORY_PATH/decoder_fuzzer.cpp libopenh264.a
else
    $CXX $CXXFLAGS \
        -o $BIC_TARGET -I./codec/api/svc \
        -I./codec/console/common/inc -I./codec/common/inc -L. \
        $LIB_FUZZING_ENGINE $BIC_REPOSITORY_PATH/decoder_fuzzer.cpp libopenh264.a -pthread
fi

echo "build BIC coverage target completed"


# generate initial corpus
cd /workdir 
corpus-replicator -o corpus video_h264_264_libx264.yml video
mv corpus/*.264 $INITIAL_SEED_PATH
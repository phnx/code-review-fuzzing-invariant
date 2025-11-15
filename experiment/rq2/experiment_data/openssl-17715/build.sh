# !/bin/bash

# TODO split fuzz/coverage binary if performance is affected

# BFC
cd $BFC_REPOSITORY_PATH

# copy driver
cp /workdir/x509.c $BFC_REPOSITORY_PATH/fuzz/x509.c
cp /workdir/fuzzer.h $BFC_REPOSITORY_PATH/fuzz/fuzzer.h
cp /workdir/rand.inc $BFC_REPOSITORY_PATH/fuzz/rand.inc

# build coverage target
echo "build BFC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

if [ "$FUZZING_TOOL" = "libfuzzer" ]; then
    # set libfuzzer lib path
    ./config --debug enable-fuzz-libfuzzer \
        -DPEDANTIC -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION \
        no-shared enable-tls1_3 enable-rc5 enable-md2 \
        enable-ec_nistp_64_gcc_128 enable-ssl3 enable-ssl3-method \
        enable-nextprotoneg enable-weak-ssl-ciphers \
        --with-fuzzer-lib=/usr/lib/llvm/lib/clang/15.0.7/lib/linux/libclang_rt.fuzzer-x86_64.a \
        $CFLAGS -fsanitize=fuzzer-no-link  -fno-sanitize=alignment
    
else
    # set aflplusplus or honggfuzz lib path
    ./config --debug enable-fuzz-libfuzzer \
        -DPEDANTIC -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION \
        no-shared enable-tls1_3 enable-rc5 enable-md2 \
        enable-ec_nistp_64_gcc_128 enable-ssl3 enable-ssl3-method \
        enable-nextprotoneg enable-weak-ssl-ciphers \
        --with-fuzzer-lib=$LIB_FUZZING_ENGINE \
        $CFLAGS -fno-sanitize=alignment
fi

LDCMD=$CXX make -j$(nproc)


# only use x509 fuzzer - based on bugoss findings
cp $BFC_REPOSITORY_PATH/fuzz/x509 $BFC_TARGET

echo "build BFC coverage target completed"


# BIC
cd $BIC_REPOSITORY_PATH

# copy driver
cp /workdir/x509.c $BIC_REPOSITORY_PATH/fuzz/x509.c
cp /workdir/fuzzer.h $BIC_REPOSITORY_PATH/fuzz/fuzzer.h
cp /workdir/rand.inc $BIC_REPOSITORY_PATH/fuzz/rand.inc

echo "build BIC coverage target completed"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

if [ "$FUZZING_TOOL" = "libfuzzer" ]; then
    # set libfuzzer lib path
    ./config --debug enable-fuzz-libfuzzer \
        -DPEDANTIC -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION \
        no-shared enable-tls1_3 enable-rc5 enable-md2 \
        enable-ec_nistp_64_gcc_128 enable-ssl3 enable-ssl3-method \
        enable-nextprotoneg enable-weak-ssl-ciphers \
        --with-fuzzer-lib=/usr/lib/llvm/lib/clang/15.0.7/lib/linux/libclang_rt.fuzzer-x86_64.a \
        $CFLAGS -fsanitize=fuzzer-no-link -fno-sanitize=alignment
    
else
    # set aflplusplus or honggfuzz lib path
    ./config --debug enable-fuzz-libfuzzer \
        -DPEDANTIC -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION \
        no-shared enable-tls1_3 enable-rc5 enable-md2 \
        enable-ec_nistp_64_gcc_128 enable-ssl3 enable-ssl3-method \
        enable-nextprotoneg enable-weak-ssl-ciphers \
        --with-fuzzer-lib=$LIB_FUZZING_ENGINE \
        $CFLAGS -fno-sanitize=alignment
fi

LDCMD=$CXX make -j$(nproc)

# only use x509 fuzzer - based on bugoss findings
cp $BIC_REPOSITORY_PATH/fuzz/x509 $BIC_TARGET


echo "build BIC coverage target completed"


# generate initial corpus and dictionary
cp $BFC_REPOSITORY_PATH/fuzz/corpora/x509/* $INITIAL_SEED_PATH
cp $BFC_REPOSITORY_PATH/fuzz/oids.txt /workdir/x509.dict
export INITIAL_DICTIONARY="/workdir/x509.dict"
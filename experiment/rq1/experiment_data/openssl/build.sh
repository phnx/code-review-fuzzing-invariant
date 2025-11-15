# !/bin/bash

# TODO split fuzz/coverage binary if performance is affected


# BIC
# not enable magma fix for BIC

echo "Build Magma BIC"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

cd "$BIC_REPOSITORY_PATH"

CONFIGURE_FLAGS=""
if [[ $CFLAGS = *sanitize=memory* ]]; then
  CONFIGURE_FLAGS="no-asm"
fi

# the config script supports env var LDLIBS instead of LIBS
export LDLIBS="$LIBS"

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
    # set aflplusplus lib path
    ./config --debug enable-fuzz-libfuzzer \
        -DPEDANTIC -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION \
        no-shared enable-tls1_3 enable-rc5 enable-md2 \
        enable-ec_nistp_64_gcc_128 enable-ssl3 enable-ssl3-method \
        enable-nextprotoneg enable-weak-ssl-ciphers \
        --with-fuzzer-lib=$LIB_FUZZING_ENGINE \
        $CFLAGS -fno-sanitize=alignment
fi
make -j$(nproc) clean
LDCMD=$CXX make -j$(nproc)

# TODO enable multiple targets fuzzing
fuzzers=$(find fuzz -executable -type f '!' -name \*.py '!' -name \*-test '!' -name \*.pl)
for f in $fuzzers; do
    fuzzer=$(basename $f)
    cp $f "$BIC_BINARY_PATH"
done


# select highest coverage target
cp $BIC_BINARY_PATH/cmp $BIC_TARGET

echo "Build Magma BIC completed"

# BFC
echo "Build Magma BFC"

cd $BFC_REPOSITORY_PATH
export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping -DMAGMA_ENABLE_FIXES"
export CXXFLAGS=$CFLAGS


cd "$BFC_REPOSITORY_PATH"

CONFIGURE_FLAGS=""
if [[ $CFLAGS = *sanitize=memory* ]]; then
  CONFIGURE_FLAGS="no-asm"
fi

# the config script supports env var LDLIBS instead of LIBS
export LDLIBS="$LIBS"

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
    # set aflplusplus lib path
    ./config --debug enable-fuzz-libfuzzer \
        -DPEDANTIC -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION \
        no-shared enable-tls1_3 enable-rc5 enable-md2 \
        enable-ec_nistp_64_gcc_128 enable-ssl3 enable-ssl3-method \
        enable-nextprotoneg enable-weak-ssl-ciphers \
        --with-fuzzer-lib=$LIB_FUZZING_ENGINE \
        $CFLAGS -fno-sanitize=alignment
fi
make -j$(nproc) clean
LDCMD=$CXX make -j$(nproc)

# TODO enable multiple targets fuzzing
fuzzers=$(find fuzz -executable -type f '!' -name \*.py '!' -name \*-test '!' -name \*.pl)
for f in $fuzzers; do
    fuzzer=$(basename $f)
    cp $f "$BFC_BINARY_PATH"
done

# select highest coverage target
cp $BFC_BINARY_PATH/cmp $BFC_TARGET

echo "Build Magma BFC completed"

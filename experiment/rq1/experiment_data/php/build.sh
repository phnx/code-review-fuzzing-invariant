# !/bin/bash

# dependency
export ONIG_CFLAGS="-I/workdir/oniguruma/src"
export ONIG_LIBS="-L/workdir/oniguruma/src/.libs -l:libonig.a"

# build oniguruma and link statically
pushd /workdir/oniguruma
autoreconf -vfi
./configure --disable-shared
make -j$(nproc)
popd



# TODO split fuzz/coverage binary if performance is affected

# BIC
# not enable magma fix for BIC

echo "Build Magma BIC"

cd $BIC_REPOSITORY_PATH

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

# PHP's zend_function union is incompatible with the object-size sanitizer
export EXTRA_CFLAGS="$CFLAGS -fno-sanitize=object-size"
export EXTRA_CXXFLAGS="$CXXFLAGS -fno-sanitize=object-size"

if [ "$FUZZING_TOOL" = "aflplusplus" ] || [ "$FUZZING_TOOL" = "honggfuzz" ]; then
    export CXXFLAGS="$CFLAGS  -stdlib=libc++"
    export LDFLAGS="-lstdc++"
fi

./buildconf
./configure \
    --disable-all \
    --enable-option-checking=fatal \
    --enable-fuzzer \
    --enable-exif \
    --enable-phar \
    --enable-intl \
    --enable-mbstring \
    --without-pcre-jit \
    --disable-phpdbg \
    --disable-cgi \
    --with-pic \
    CXXFLAGS="$CXXFLAGS -std=c++17" \
    LDFLAGS="-lstdc++"

make -j$(nproc) clean
make -j$(nproc)

# TODO enable multiple targets fuzzing
FUZZERS="php-fuzz-json php-fuzz-exif php-fuzz-mbstring php-fuzz-unserialize php-fuzz-parser"
for fuzzerName in $FUZZERS; do
	cp sapi/fuzzer/$fuzzerName "$BIC_BINARY_PATH/${fuzzerName/php-fuzz-/}"
done

# select highest coverage target
cp $BIC_BINARY_PATH/exif $BIC_TARGET

echo "Build Magma BIC completed"

# BFC

echo "Build Magma BFC"

cd $BFC_REPOSITORY_PATH

# enable magma fix for BFC
export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping -DMAGMA_ENABLE_FIXES"
export CXXFLAGS=$CFLAGS

# PHP's zend_function union is incompatible with the object-size sanitizer
export EXTRA_CFLAGS="$CFLAGS -fno-sanitize=object-size"
export EXTRA_CXXFLAGS="$CXXFLAGS -fno-sanitize=object-size"

if [ "$FUZZING_TOOL" = "aflplusplus" ] || [ "$FUZZING_TOOL" = "honggfuzz" ]; then
    export CXXFLAGS="$CFLAGS  -stdlib=libc++ "
    export LDFLAGS="-lstdc++"
fi

./buildconf
./configure \
    --disable-all \
    --enable-option-checking=fatal \
    --enable-fuzzer \
    --enable-exif \
    --enable-phar \
    --enable-intl \
    --enable-mbstring \
    --without-pcre-jit \
    --disable-phpdbg \
    --disable-cgi \
    --with-pic \
    CXXFLAGS="$CXXFLAGS -std=c++17" \
    LDFLAGS="-lstdc++"

make -j$(nproc) clean
make -j$(nproc)

# TODO enable multiple targets fuzzing
FUZZERS="php-fuzz-json php-fuzz-exif php-fuzz-mbstring php-fuzz-unserialize php-fuzz-parser"
for fuzzerName in $FUZZERS; do
	cp sapi/fuzzer/$fuzzerName "$BFC_BINARY_PATH/${fuzzerName/php-fuzz-/}"
done


# select highest coverage target
cp $BFC_BINARY_PATH/exif $BFC_TARGET


echo "Build Magma BFC completed"

# initial corpus
cd $BFC_REPOSITORY_PATH
sapi/cli/php sapi/fuzzer/generate_unserialize_dict.php
sapi/cli/php sapi/fuzzer/generate_parser_corpus.php

for fuzzerName in `ls sapi/fuzzer/corpus`; do
    mkdir -p "$INITIAL_SEED_PATH/${fuzzerName}"
    cp sapi/fuzzer/corpus/${fuzzerName}/* "$INITIAL_SEED_PATH/${fuzzerName}/"
done

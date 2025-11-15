# !/bin/bash

# TODO split fuzz/coverage binary if performance is affected

# BFC
cd $BFC_REPOSITORY_PATH

# copy driver - just in case
cp /workdir/magic_fuzzer.cc $BFC_REPOSITORY_PATH/magic_fuzzer.cc

# build coverage target
echo "build BFC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

sed -i 's/\-O/\-O0/g' src/Makefile.std

autoreconf -i
./configure --enable-static
make V=1 all

# use embeded fuzzer
$CC $CFLAGS -DHAVE_CONFIG_H -Wall -fsanitize=fuzzer -std=c11 -I./src -I. \
        -o $BFC_TARGET $BFC_REPOSITORY_PATH/fuzz/magic_fuzzer.c \
        $LIB_FUZZING_ENGINE ./src/.libs/libmagic.a  -llzma -lbz2 -lzstd -lz

cp ./magic/magic.mgc $BFC_BINARY_PATH


echo "build BFC coverage target completed"

# BIC
cd $BIC_REPOSITORY_PATH

# copy driver
cp /workdir/magic_fuzzer.cc $BIC_REPOSITORY_PATH/magic_fuzzer.cc

# build coverage target
echo "build BIC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

sed -i 's/\-O/\-O0/g' src/Makefile.std

autoreconf -i
./configure --enable-static
make V=1 all

# use embeded fuzzer
$CC $CFLAGS -DHAVE_CONFIG_H -Wall -fsanitize=fuzzer -std=c11 -I./src -I. \
        -o $BIC_TARGET $BIC_REPOSITORY_PATH/fuzz/magic_fuzzer.c \
        $LIB_FUZZING_ENGINE ./src/.libs/libmagic.a  -llzma -lbz2 -lzstd -lz

cp ./magic/magic.mgc $BIC_BINARY_PATH/

# collect initial corpus
cp $BFC_REPOSITORY_PATH/tests/*.testfile $INITIAL_SEED_PATH
find $BFC_REPOSITORY_PATH/pocs/ -type f -print0 | xargs -0 -I % mv -f % $INITIAL_SEED_PATH
cp -r $BFC_REPOSITORY_PATH/binary-samples/* $INITIAL_SEED_PATH


echo "build BIC coverage target completed"

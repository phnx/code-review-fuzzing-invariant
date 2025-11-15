# !/bin/bash


# BFC
cd $BFC_REPOSITORY_PATH

# copy driver
cp /workdir/fuzz_htp.c $BFC_REPOSITORY_PATH/test/fuzz/fuzz_htp.c
cp /workdir/fuzz_htp.h $BFC_REPOSITORY_PATH/test/fuzz/fuzz_htp.h

# build coverage target
echo "build BFC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

sed -i 's/OLEVEL=2/OLEVEL=0/g' configure.ac 

sh autogen.sh
./configure
make

# update linking flag for libfuzzer
if [ "$FUZZING_TOOL" = "libfuzzer" ]; then
    $CC $CFLAGS -fsanitize=fuzzer -I. -c test/fuzz/fuzz_htp.c -o fuzz_htp.o
    $CC $CFLAGS -I. -c test/test.c -o test.o
    $CXX $CXXFLAGS -fsanitize=fuzzer fuzz_htp.o test.o -o $BFC_TARGET ./htp/.libs/libhtp.a $LIB_FUZZING_ENGINE -lz -llzma
else
    $CC $CFLAGS -I. -c test/fuzz/fuzz_htp.c -o fuzz_htp.o
    $CC $CFLAGS -I. -c test/test.c -o test.o
    $CXX $CXXFLAGS fuzz_htp.o test.o -o $BFC_TARGET ./htp/.libs/libhtp.a $LIB_FUZZING_ENGINE -lz -llzma
fi

echo "build BFC coverage target completed"


# BIC
cd $BIC_REPOSITORY_PATH

# copy driver
cp /workdir/fuzz_htp.c $BIC_REPOSITORY_PATH/test/fuzz/fuzz_htp.c
cp /workdir/fuzz_htp.h $BIC_REPOSITORY_PATH/test/fuzz/fuzz_htp.h

# build coverage target
echo "build BIC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS
 
sed -i 's/OLEVEL=2/OLEVEL=0/g' configure.ac 

sh autogen.sh
./configure
make

# update linking flag for libfuzzer
if [ "$FUZZING_TOOL" = "libfuzzer" ]; then
    $CC $CFLAGS -fsanitize=fuzzer -I. -c test/fuzz/fuzz_htp.c -o fuzz_htp.o
    $CC $CFLAGS -I. -c test/test.c -o test.o
    $CXX $CXXFLAGS -fsanitize=fuzzer fuzz_htp.o test.o -o $BIC_TARGET ./htp/.libs/libhtp.a $LIB_FUZZING_ENGINE -lz -llzma
else
    $CC $CFLAGS -I. -c test/fuzz/fuzz_htp.c -o fuzz_htp.o
    $CC $CFLAGS -I. -c test/test.c -o test.o
    $CXX $CXXFLAGS fuzz_htp.o test.o -o $BIC_TARGET ./htp/.libs/libhtp.a $LIB_FUZZING_ENGINE -lz -llzma
fi

echo "build BIC coverage target completed"

# generate initial corpus
cp test/files/*.t $INITIAL_SEED_PATH

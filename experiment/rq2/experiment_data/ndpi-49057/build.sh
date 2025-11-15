# !/bin/bash

# build dependencies
cd /workdir

tar -xvzf libpcap-1.9.1.tar.gz
cd libpcap-1.9.1
CC=clang CXX=clang++ ./configure --disable-shared
make -j$(nproc)
make install
cd ..

cd json-c
mkdir build
cd build
CC=clang CXX=clang++ cmake -DBUILD_SHARED_LIBS=OFF ..
make install

# TODO split fuzz/coverage binary if performance is affected


# BFC
cd $BFC_REPOSITORY_PATH

# copy driver
cp /workdir/fuzz_process_packet.c $BFC_REPOSITORY_PATH/fuzz/fuzz_process_packet.c

# build coverage target
echo "build BFC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

./autogen.sh
./configure --enable-fuzztargets
make

# update target
cp $BFC_REPOSITORY_PATH/fuzz/fuzz_process_packet $BFC_TARGET

echo "BFC target completed"

# BIC
cd $BIC_REPOSITORY_PATH

# copy driver
cp /workdir/fuzz_process_packet.c $BIC_REPOSITORY_PATH/fuzz/fuzz_process_packet.c

# build coverage target
echo "build BIC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

./autogen.sh
./configure --enable-fuzztargets
make

# update target
cp $BIC_REPOSITORY_PATH/fuzz/fuzz_process_packet $BIC_TARGET

echo "BIC target completed"

# collect initial corpus
cd $BFC_REPOSITORY_PATH
make -C fuzz fuzz_ndpi_reader_seed_corpus.zip
set +e
unzip $BFC_REPOSITORY_PATH/fuzz/fuzz_ndpi_reader_seed_corpus.zip -d $INITIAL_SEED_PATH
set -e
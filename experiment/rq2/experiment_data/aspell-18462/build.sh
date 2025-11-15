# !/bin/bash

# TODO split fuzz/coverage binary if performance is affected

# does not work with libfuzzer - fuzzing does not execute

# BFC
cd "$BFC_REPOSITORY_PATH"


# copy driver
cp /workdir/aspell_fuzzer.cpp $BFC_REPOSITORY_PATH/aspell-fuzz/decoder_fuzzer.cpp

cd "$BFC_REPOSITORY_PATH/aspell-fuzz"

# build coverage target
echo "build BFC coverage target"

export OUT=/workdir/tmp/bin/bfc
export SRC=$BFC_REPOSITORY_PATH
export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

rm -rf $OUT
mkdir -p $OUT

# add dl link
sed -i 's/export LIBS="-lpthread"/export LIBS="-ldl -lpthread"/g' ossfuzz.sh
./ossfuzz.sh

# update binary
cp /workdir/tmp/bin/bfc/aspell_fuzzer $BFC_BINARY_PATH
cp $BFC_BINARY_PATH/aspell_fuzzer $BFC_TARGET

echo "build BFC coverage target completed"


# BIC
cd "$BIC_REPOSITORY_PATH"


# copy driver
cp /workdir/aspell_fuzzer.cpp $BIC_REPOSITORY_PATH/aspell-fuzz/decoder_fuzzer.cpp

cd "$BIC_REPOSITORY_PATH/aspell-fuzz"

# build coverage target
echo "build BIC coverage target"

export OUT=/workdir/tmp/bin/bic
export SRC=$BIC_REPOSITORY_PATH
export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

rm -rf $OUT
mkdir -p $OUT

# add dl link
sed -i 's/export LIBS="-lpthread"/export LIBS="-ldl -lpthread"/g' ossfuzz.sh
./ossfuzz.sh

# update binary
cp /workdir/tmp/bin/bic/aspell_fuzzer $BIC_BINARY_PATH
cp $BIC_BINARY_PATH/aspell_fuzzer $BIC_TARGET


echo "build BIC coverage target completed"


# generate initial corpus
cp $BFC_REPOSITORY_PATH/aspell-fuzz/aspell_fuzzer_corpus/* $INITIAL_SEED_PATH


# extra for aspell: src not in repo path
git config --global --add safe.directory '*'  
python3 /script/watcher/extract-commit-changes.py $BIC_REPOSITORY_PATH/aspell > $BIC_COMMIT_CHANGES

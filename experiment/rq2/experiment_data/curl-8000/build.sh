# !/bin/bash

# TODO split fuzz/coverage binary if performance is affected

# does not work with libfuzzer - fuzzing does not execute

# BFC
cd "$BFC_REPOSITORY_PATH"

# copy driver
cp /workdir/curl_fuzzer.cc "$BFC_REPOSITORY_PATH/curl-fuzzer/"
cd "$BFC_REPOSITORY_PATH/curl-fuzzer/"

# build coverage target
echo "build BFC coverage target"

export OUT=/workdir/tmp/bin/bfc
export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

rm -rf $OUT
mkdir -p $OUT

# update src path
sed -i 's|install_curl.sh /src/curl ${INSTALLDIR}|install_curl.sh ${BFC_REPOSITORY_PATH}/curl ${INSTALLDIR}|g' ossfuzz.sh
./ossfuzz.sh

# update target
cp $OUT/curl_fuzzer $BFC_BINARY_PATH
cp $BFC_BINARY_PATH/curl_fuzzer $BFC_TARGET

echo "build BFC coverage target completed"


# BIC
cd "$BIC_REPOSITORY_PATH"

# copy driver
cp /workdir/curl_fuzzer.cc "$BIC_REPOSITORY_PATH/curl-fuzzer/"
cd "$BIC_REPOSITORY_PATH/curl-fuzzer/"

# build coverage target
echo "build BIC coverage target"

export OUT=/workdir/tmp/bin/bic
export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

rm -rf $OUT
mkdir -p $OUT

# update src path
sed -i 's|install_curl.sh /src/curl ${INSTALLDIR}|install_curl.sh ${BIC_REPOSITORY_PATH}/curl ${INSTALLDIR}|g' ossfuzz.sh
./ossfuzz.sh

# update target
cp $OUT/curl_fuzzer $BIC_BINARY_PATH
cp $BIC_BINARY_PATH/curl_fuzzer $BIC_TARGET

echo "build BIC coverage target completed"

# generate initial corpus
unzip /workdir/tmp/bin/bfc/curl_fuzzer_seed_corpus.zip -d $INITIAL_SEED_PATH
export INITIAL_DICTIONARY="/workdir/tmp/bin/bfc/http.dict"

# extra for curl: src not in repo path
git config --global --add safe.directory '*'  
python3 /script/watcher/extract-commit-changes.py $BIC_REPOSITORY_PATH/curl > $BIC_COMMIT_CHANGES

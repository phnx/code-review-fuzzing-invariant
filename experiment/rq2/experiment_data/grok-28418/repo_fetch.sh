# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone https://github.com/GrokImageCompression/grok.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# BIC
git -C $BIC_REPOSITORY_PATH fetch origin 93e6af95ec46bbba5e112a1fbdbdb6a1294d61d8 && \
git -C $BIC_REPOSITORY_PATH checkout 93e6af95ec46bbba5e112a1fbdbdb6a1294d61d8

# BFC
git -C $BFC_REPOSITORY_PATH fetch origin 4903b806b22727f8683812a703158c3a785afbbd && \
git -C $BFC_REPOSITORY_PATH checkout 4903b806b22727f8683812a703158c3a785afbbd

# seed corpus
git clone https://github.com/GrokImageCompression/grok-test-data.git $BFC_REPOSITORY_PATH/grok/data

# fuzz driver
# download target
wget https://github.com/sdevlab/BugOss/raw/refs/heads/master/artifacts/grok-28418/grk_decompress_fuzzer.cpp \
    -O /workdir/grk_decompress_fuzzer.cpp
    
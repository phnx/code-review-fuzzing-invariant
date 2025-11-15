# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone https://github.com/facebook/zstd.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# BIC
git -C $BIC_REPOSITORY_PATH fetch origin 0ed07f6dfe942627e7724e5b910e23ec3cd8ece8 && \
git -C $BIC_REPOSITORY_PATH checkout 0ed07f6dfe942627e7724e5b910e23ec3cd8ece8

# BFC
git -C $BFC_REPOSITORY_PATH fetch origin f17ac423b21fffdc2918daafe41a5eae0478b249 && \
git -C $BFC_REPOSITORY_PATH checkout f17ac423b21fffdc2918daafe41a5eae0478b249

# fuzz driver
# download target and header
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/zstd-21970/fuzz_data_producer.c \
    -O /workdir/fuzz_data_producer.c

wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/zstd-21970/fuzz_data_producer.h \
    -O /workdir/fuzz_data_producer.h

wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/zstd-21970/fuzz_helpers.h \
    -O /workdir/fuzz_helpers.h

wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/zstd-21970/stream_decompress.c \
    -O /workdir/stream_decompress.c

# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone https://github.com/openssl/openssl.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# BIC
git -C $BIC_REPOSITORY_PATH fetch origin 4baee2d72e0c82bfd6de085df23a1bdc6af887ba && \
git -C $BIC_REPOSITORY_PATH checkout 4baee2d72e0c82bfd6de085df23a1bdc6af887ba

# BFC
git -C $BFC_REPOSITORY_PATH fetch origin 6922740facabcc1d1509cd9e72dd837a60a91d2c && \
git -C $BFC_REPOSITORY_PATH checkout 6922740facabcc1d1509cd9e72dd837a60a91d2c

# fuzz driver
# download header and target
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/openssl-17715/fuzzer.h \
    -O /workdir/fuzzer.h
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/openssl-17715/rand.inc \
    -O /workdir/rand.inc
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/openssl-17715/x509.c \
    -O /workdir/x509.c

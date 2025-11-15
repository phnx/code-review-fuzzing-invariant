# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone https://github.com/DanBloomberg/leptonica.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# BIC
git -C $BIC_REPOSITORY_PATH fetch origin 8fc49016cf44ecbbab28979442e2781bd064584e && \
git -C $BIC_REPOSITORY_PATH checkout 8fc49016cf44ecbbab28979442e2781bd064584e

# BFC
git -C $BFC_REPOSITORY_PATH fetch origin 46b8f565f244641b53090d1f06b633c7dc6d366b && \
git -C $BFC_REPOSITORY_PATH checkout 46b8f565f244641b53090d1f06b633c7dc6d366b

# fuzz driver
# download target
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/leptonica-25212/pix4_fuzzer.cc \
    -O /workdir/pix4_fuzzer.cc

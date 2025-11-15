# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone https://github.com/sctplab/usrsctp.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# BIC
git -C $BIC_REPOSITORY_PATH fetch origin 05bea46702687f26a81c41c3fb1fd1dd3d9c0aa1 && \
git -C $BIC_REPOSITORY_PATH checkout 05bea46702687f26a81c41c3fb1fd1dd3d9c0aa1

# BFC
git -C $BFC_REPOSITORY_PATH fetch origin 1a7de8f9d8a419b358faa219ee0d75ae14ddd5f7 && \
git -C $BFC_REPOSITORY_PATH checkout 1a7de8f9d8a419b358faa219ee0d75ae14ddd5f7

# fuzz driver
# download target and cmakelist
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/usrsctp-18080/fuzzer_connect.c \
    -O /workdir/fuzzer_connect.c

wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/usrsctp-18080/CMakeLists.txt \
    -O /workdir/CMakeLists.txt

# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone https://github.com/OISF/libhtp.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# BIC
git -C $BIC_REPOSITORY_PATH fetch origin 3c6555078ec30e0baa4855ec69d55a22fc8d3589 && \
git -C $BIC_REPOSITORY_PATH checkout 3c6555078ec30e0baa4855ec69d55a22fc8d3589

# BFC
git -C $BFC_REPOSITORY_PATH fetch origin 203beeef05f8c7bedd4692b35cf2fbe38c9330b8 && \
git -C $BFC_REPOSITORY_PATH checkout 203beeef05f8c7bedd4692b35cf2fbe38c9330b8

# fuzz driver
# download target and header
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/libhtp-17198/fuzz_htp.c \
    -O /workdir/fuzz_htp.c

wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/libhtp-17198/fuzz_htp.h \
    -O /workdir/fuzz_htp.h
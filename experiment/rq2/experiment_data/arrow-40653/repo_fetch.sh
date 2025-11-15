# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone https://github.com/apache/arrow.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# BIC
git -C $BIC_REPOSITORY_PATH fetch origin 3c5b62c116733e434508a8673c2d466776b27eed && \
git -C $BIC_REPOSITORY_PATH checkout 3c5b62c116733e434508a8673c2d466776b27eed

# BFC
git -C $BFC_REPOSITORY_PATH fetch origin 421733475385300004093f13b451f5f382ff365c && \
git -C $BFC_REPOSITORY_PATH checkout 421733475385300004093f13b451f5f382ff365c

# dependency
# oss-fuzz: temporarily use manual installation over the outdated libboost-dev package
# cd /workdir
# wget https://archives.boost.io/release/1.85.0/source/boost_1_85_0.tar.bz2 \
#     -O /workdir/boost_1_85_0.tar.bz2 && tar /workdir/boost_1_85_0.tar.bz2


# fuzz driver
# download target
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/arrow-40653/file_fuzz.cc \
    -O /workdir/file_fuzz.cc
    
# dataset
git clone https://github.com/apache/arrow-testing.git $BFC_REPOSITORY_PATH/testing
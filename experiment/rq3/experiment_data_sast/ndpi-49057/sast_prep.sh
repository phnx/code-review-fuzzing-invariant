#!/bin/bash

# clone target repo
rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/ntop/nDPI.git $BIC_REPOSITORY_PATH 

# install and build dependencies
apt-get install -y make autoconf automake autogen pkg-config libtool flex bison zip libpcap-dev

# checkout BIC
git -C $BIC_REPOSITORY_PATH checkout 2edfaeba4ada90ca8771a44132d2b9cc85e45570

# pre-compilation steps
cd $BIC_REPOSITORY_PATH
./autogen.sh
./configure
make clean

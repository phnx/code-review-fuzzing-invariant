#!/bin/bash

# clone target repo
rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/WizardMac/ReadStat.git $BIC_REPOSITORY_PATH 

# install and build dependencies
apt-get install -y make autoconf automake gettext libtool zip zlib1g-dev 

# checkout BIC
git -C $BIC_REPOSITORY_PATH checkout 1de4f389a8ffb07775cb1d99e33cbfa7e96bccf2

# pre-compilation steps
cd $BIC_REPOSITORY_PATH

# add -Wno-strict-prototypes for clang-15
export CFLAGS="-g -O0 -Wno-implicit-const-int-float-conversion -Wno-strict-prototypes -pthread"
export CXXFLAGS=$CFLAGS

./autogen.sh
./configure --disable-shared


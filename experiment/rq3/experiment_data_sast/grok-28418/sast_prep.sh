#!/bin/bash

# clone target repo
rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/GrokImageCompression/grok.git $BIC_REPOSITORY_PATH 

# install and build dependencies
echo "no deps needed"

# checkout BIC
git -C $BIC_REPOSITORY_PATH fetch origin 93e6af95ec46bbba5e112a1fbdbdb6a1294d61d8 && \
git -C $BIC_REPOSITORY_PATH checkout 93e6af95ec46bbba5e112a1fbdbdb6a1294d61d8


# pre-compilation steps
cd $BIC_REPOSITORY_PATH
mkdir build
cd build
CMAKE_POLICY_VERSION_MINIMUM=3.5 cmake .. -DGRK_BUILD_CODEC=OFF -DBUILD_SHARED_LIBS=OFF -DGRK_BUILD_THIRDPARY=ON
make clean


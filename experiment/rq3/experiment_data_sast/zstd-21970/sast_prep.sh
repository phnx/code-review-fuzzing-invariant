#!/bin/bash

# clone target repo
rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/facebook/zstd.git $BIC_REPOSITORY_PATH 

# install and build dependencies
apt-get install -y zip

# checkout BIC
git -C $BIC_REPOSITORY_PATH checkout 0ed07f6dfe942627e7724e5b910e23ec3cd8ece8

# pre-compilation steps
cd $BIC_REPOSITORY_PATH


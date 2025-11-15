#!/bin/bash

# clone target repo
rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/seladb/PcapPlusPlus.git $BIC_REPOSITORY_PATH 

# install and build dependencies
apt-get install -y gcc g++ make cmake flex bison zip libpcap-dev

# checkout BIC
git -C $BIC_REPOSITORY_PATH checkout 50aab202d24331ef35b9eff68d96ef9f97baf6a1

# pre-compilation steps
cd $BIC_REPOSITORY_PATH
./configure-linux.sh --default

#!/bin/bash

# clone target repo
rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/libarchive/libarchive.git $BIC_REPOSITORY_PATH 

# install and build dependencies
apt-get install -y make autoconf automake libtool pkg-config \
	    libbz2-dev liblzo2-dev liblzma-dev liblz4-dev libz-dev \
	        libssl-dev libacl1-dev libattr1-dev lrzip \
		    liblz4-tool lzop zstd lcab genisoimage jlha-utils rar default-jdk zip

# checkout BIC
git -C $BIC_REPOSITORY_PATH checkout 52efa50c69653029687bfc545703b7340b7a51e2

# pre-compilation steps
cd $BIC_REPOSITORY_PATH
build/autogen.sh
./configure

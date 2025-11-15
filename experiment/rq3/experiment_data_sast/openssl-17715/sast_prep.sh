#!/bin/bash

# clone target repo
rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/openssl/openssl.git $BIC_REPOSITORY_PATH 

# install and build dependencies
apt-get install -y libstdc++-9-dev

# checkout BIC
git -C $BIC_REPOSITORY_PATH checkout 4baee2d72e0c82bfd6de085df23a1bdc6af887ba

# pre-compilation steps
cd $BIC_REPOSITORY_PATH
./config no-shared enable-tls1_3 enable-rc5 enable-md2 \
	        enable-ec_nistp_64_gcc_128 enable-ssl3 enable-ssl3-method \
		        enable-nextprotoneg enable-weak-ssl-ciphers 
    

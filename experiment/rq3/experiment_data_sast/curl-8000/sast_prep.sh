#!/bin/bash

# clone target repo
rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/curl/curl.git $BIC_REPOSITORY_PATH 

# install and build dependencies
apt-get -y install zip

# checkout BIC
git -C $BIC_REPOSITORY_PATH checkout dd7521bcc1b7a6fcb53c31f9bd1192fcc884bd56

# pre-compilation steps
cd $BIC_REPOSITORY_PATH
./buildconf
./configure

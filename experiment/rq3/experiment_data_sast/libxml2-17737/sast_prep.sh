#!/bin/bash

# clone target repo
rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://gitlab.gnome.org/GNOME/libxml2.git $BIC_REPOSITORY_PATH 

# install and build dependencies
apt-get install -y make autoconf automake libtool pkg-config
    
# checkout BIC
git -C $BIC_REPOSITORY_PATH checkout 1fbcf4098ba2aefe241de8d7ceb229b995d8daec

# pre-compilation steps
cd $BIC_REPOSITORY_PATH
./autogen.sh
./configure --with-http=no
make clean

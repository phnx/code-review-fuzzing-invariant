#!/bin/bash

# clone target repo
rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/harfbuzz/harfbuzz.git $BIC_REPOSITORY_PATH 

# install and build dependencies
apt-get install -y pkg-config ragel gtk-doc-tools libfreetype6-dev libglib2.0-dev libcairo2-dev
pip3 install meson==0.56.0 ninja

# checkout BIC
git -C $BIC_REPOSITORY_PATH checkout 8708b9e081192786c027bb7f5f23d76dbe5c19e8

# pre-compilation steps
cd $BIC_REPOSITORY_PATH
meson build

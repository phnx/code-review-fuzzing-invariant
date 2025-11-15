#!/bin/bash

# clone target repo
rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/cisco/openh264.git $BIC_REPOSITORY_PATH 

# install and build dependencies
apt-get install -y libstdc++-9-dev nasm subversion ffmpeg

# checkout BIC
git -C $BIC_REPOSITORY_PATH checkout effb3931c7c67f34b167fe6e0a93253bf075f78c

# pre-compilation steps
cd $BIC_REPOSITORY_PATH


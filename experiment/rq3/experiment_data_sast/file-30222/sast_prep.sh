#!/bin/bash

# clone target repo
rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/file/file.git $BIC_REPOSITORY_PATH 

# install and build dependencies
apt-get install -y \
	    make \
	        autoconf \
		    automake \
		        libtool \
			    shtool \
        libbz2-dev \
        libzstd-dev
    
# checkout BIC
git -C $BIC_REPOSITORY_PATH checkout 6de3683de955277c4be4be350ec683b3203d3f31

# pre-compilation steps
cd $BIC_REPOSITORY_PATH
autoreconf -i
./configure --enable-static


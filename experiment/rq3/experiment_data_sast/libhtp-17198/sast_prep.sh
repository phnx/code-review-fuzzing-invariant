#!/bin/bash

# clone target repo
rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/OISF/libhtp.git $BIC_REPOSITORY_PATH 

# install and build dependencies
apt-get install -y \
	    make \
	        autoconf \
		    automake \
		        libtool \
			    zlib1g-dev \
			        liblzma-dev
    
# checkout BIC
git -C $BIC_REPOSITORY_PATH checkout 3c6555078ec30e0baa4855ec69d55a22fc8d3589

# pre-compilation steps
cd $BIC_REPOSITORY_PATH
sh autogen.sh
./configure

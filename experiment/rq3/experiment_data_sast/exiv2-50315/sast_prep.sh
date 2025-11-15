#!/bin/bash

# clone target repo
rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/Exiv2/exiv2.git $BIC_REPOSITORY_PATH 

# install and build dependencies
apt-get install -y \
	    ccache \
	        libexpat1-dev \
		    zlib1g-dev \
		        libssh-dev \
			    libcurl4-openssl-dev \
			        libxml2-utils \
				    libbz2-dev \
				        liblzma-dev \
					    libzstd-dev \
					        liblz4-dev
    
# checkout BIC
git -C $BIC_REPOSITORY_PATH checkout 10a62b23500954abf7eb2cc3e577bebb21bb0b72

# pre-compilation steps
cd $BIC_REPOSITORY_PATH
rm -rf build
mkdir -p build
cd build
CMAKE_POLICY_VERSION_MINIMUM=3.5 cmake -DCMAKE_BUILD_TYPE=Release ..


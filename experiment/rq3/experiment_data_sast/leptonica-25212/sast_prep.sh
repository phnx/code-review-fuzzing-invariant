#!/bin/bash

# clone target repo
rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/DanBloomberg/leptonica.git $BIC_REPOSITORY_PATH 

# install and build dependencies
apt-get install -y \
	    pkg-config \
	        libzstd-dev \
		    libjbig-dev \
		        libjpeg-turbo8-dev \
			    libpng-dev \
			        libwebp-dev \
				    libtiff-dev \
				        zlib1g-dev \
					    zip
# checkout BIC
git -C $BIC_REPOSITORY_PATH checkout 8fc49016cf44ecbbab28979442e2781bd064584e

# pre-compilation steps
cd $BIC_REPOSITORY_PATH
./autogen.sh
./configure \
	  --enable-static \
	    --disable-shared \
	      --with-libpng \
	        --with-zlib \
		  --with-jpeg \
		    --with-libwebp \
		      --with-libtiff 

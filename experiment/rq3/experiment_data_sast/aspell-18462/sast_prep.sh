#!/bin/bash

# clone target repo
rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/gnuaspell/aspell.git $BIC_REPOSITORY_PATH 

# install and build dependencies
apt-get -y install \
	    automake \
	        autopoint \
		    bzip2 \
		        gettext \
			    libtool \
			        texinfo \
				    wget \
				        zip

# checkout BIC
git -C $BIC_REPOSITORY_PATH checkout e0646f9b063b23754951f1254f1ecb7af8ca36f3

# pre-compilation steps
cd $BIC_REPOSITORY_PATH
./autogen
./configure --disable-static 


#!/bin/bash

# clone target repo
rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/sctplab/usrsctp.git $BIC_REPOSITORY_PATH 

# install and build dependencies
echo "no deps"

# checkout BIC
git -C $BIC_REPOSITORY_PATH checkout 05bea46702687f26a81c41c3fb1fd1dd3d9c0aa1

# pre-compilation steps
cd $BIC_REPOSITORY_PATH
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/usrsctp-18080/CMakeLists.txt \
	    -O ./CMakeLists.txt
export CFLAGS=" -Wno-unused-but-set-variable"
export CXXFLAGS=$CFLAGS
CMAKE_POLICY_VERSION_MINIMUM=3.5 cmake -Dsctp_build_programs=0 -Dsctp_debug=1 -Dsctp_invariants=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo .

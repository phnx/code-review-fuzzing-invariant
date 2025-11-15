#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y make vim git wget curl # for example program
# apt-get install -y binutils-dev autotools-dev automake zlib1g-dev default-jre texlive-base # for kvasir and daikon
apt-get install -y software-properties-common automake build-essential zlib1g-dev libtool # for building subject
apt-get install -y python3-pip

# required by honggfuzz
apt-get install -y libunwind-dev libblocksruntime-dev

# update to llvm-15
source /script/update-llvm.sh

# install in-house dependency
pip install --requirement /script/requirements.txt

# cmake latest version
pip install cmake --upgrade
ln /usr/local/bin/cmake /usr/bin/cmake 

export CC=clang
export CXX=clang++

# chmod +x start-fuzzing.sh
# chmod +x start-mining-invariants.sh

# DIG requirement
apt-get install -y libc6 emacs-nox openjdk-17-jdk

# upgrade python3.10 for DIG
source /script/update-python.sh
python3.10 -m pip install z3-solver beartype pycparser sympy

# install DIG, DIG will exclusively use python3.10 - run these command during program setup
# git clone https://github.com/dynaroars/dig.git /program/dig
# cd /program/dig/EXTERNAL_FILES
# tar xf CIVL-1.22_5854.tgz ; ln -sf CIVL-1.22_5854/ civl
# cp dot_sarl ~/.sarl   # NEED TO MANUALLY PUT IN Z3 VERSION

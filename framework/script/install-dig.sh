#!/bin/bash

cd /program
git clone https://github.com/dynaroars/dig.git
cd dig
git checkout v2.0.2b


# DIG dependencies
apt-get install -y libc6 emacs-nox openjdk-17-jdk

# upgrade python3.10 for DIG
source /script/update-python.sh
python3.10 -m pip install z3-solver beartype pycparser sympy

# do once to setup dig
cd /program/dig/EXTERNAL_FILES
tar xf CIVL-1.22_5854.tgz ; ln -sf CIVL-1.22_5854/ civl
cp dot_sarl ~/.sarl   # NEED TO MANUALLY PUT IN Z3 VERSION
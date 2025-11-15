#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# solve a potential version conflict issue
pip3 install --ignore-installed pyyaml

# Flawfinder
VERSION=2.0.19
pip3 install flawfinder==$VERSION
flawfinder --version  # test installation


# CodeQL v2.20.4
cd /program
# ubuntu
wget https://github.com/github/codeql-action/releases/download/codeql-bundle-v2.20.4/codeql-bundle-linux64.tar.gz
tar -xvzf codeql-bundle-linux64.tar.gz
rm codeql-bundle-linux64.tar.gz

# add codeql directory to PATH
export PATH="/program/codeql:$PATH"
codeql resolve qlpacks # test installation

# CodeChecker 
VERSION=6.24.4
pip3 install codechecker==$VERSION
CodeChecker version # test installation

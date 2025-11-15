# !/bin/bash
export DEBIAN_FRONTEND=noninteractive

add-apt-repository -y ppa:deadsnakes/ppa

apt-get -y install python3.10 python3.10-dev python3.10-venv

# install pip for python 3.10
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

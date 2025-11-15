# !/bin/bash

apt-get update && \
    apt-get install -y libstdc++-9-dev nasm subversion ffmpeg

# use python 3.10 pip
/usr/local/bin/pip install corpus-replicator
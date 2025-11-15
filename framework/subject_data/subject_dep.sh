#!/bin/bash
# example subject dependency script, taken from rq2:libhtp

apt-get update && \
    apt-get install -y \
        make \
        autoconf \
        automake \
        libtool \
        zlib1g-dev \
        liblzma-dev
#!/bin/bash

# final command to build BIC, to be operated by SAST
cd $BIC_REPOSITORY_PATH
LDFLAGS="-pthread" make

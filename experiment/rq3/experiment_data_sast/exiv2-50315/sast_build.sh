#!/bin/bash

# final command to build BIC, to be operated by SAST
cd $BIC_REPOSITORY_PATH/build
CMAKE_POLICY_VERSION_MINIMUM=3.5 cmake --build .

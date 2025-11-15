#!/bin/bash

# final command to build BIC, to be operated by SAST
cd /workdir/arrow_build
CMAKE_POLICY_VERSION_MINIMUM=3.5 cmake --build .

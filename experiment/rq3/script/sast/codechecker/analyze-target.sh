#!/bin/bash

export TARGET=$1
export SAST=codechecker

export SAST_PREP_SCRIPT=/experiment_data_sast/$TARGET/sast_prep.sh
export SAST_BUILD_SCRIPT=/experiment_data_sast/$TARGET/sast_build.sh
export BIC_REPOSITORY_PATH=/experiment/repo/bic

cd /workdir

# clean up result path
export BIC_SAST_WARNING_PATH=/experiment_data_sast/$TARGET/sast/$SAST/result
rm -rf $BIC_SAST_WARNING_PATH
mkdir -p $BIC_SAST_WARNING_PATH

# clean up repository
rm -rf /experiment/repo
mkdir -p /experiment/repo
source $SAST_PREP_SCRIPT

# run tools 
# only analyze BIC
cd $BIC_REPOSITORY_PATH
chmod +x $SAST_BUILD_SCRIPT
CodeChecker check -j$(nproc) --build "$SAST_BUILD_SCRIPT" --enable-all -o=./reports --clean 
CodeChecker parse ./reports --trim-path-prefix=/experiment/repo/bic -e=json -o=$BIC_SAST_WARNING_PATH/result.json
# CodeChecker parse ./reports -e=json -o=$BIC_SAST_WARNING_PATH/result.json

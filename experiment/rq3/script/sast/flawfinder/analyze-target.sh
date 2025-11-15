#!/bin/bash

export TARGET=$1
export SAST=flawfinder

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
python3 /script/sast/flawfinder/convert_subject_encoding.py $BIC_REPOSITORY_PATH
cd $BIC_REPOSITORY_PATH
flawfinder --sarif . > $BIC_SAST_WARNING_PATH/result.sarif

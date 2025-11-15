#!/bin/bash


# LOAD FRAMEWORK CONFIGURATIONS
# SWAP CONFIG FILE TO CHANGE TIMEOUT
mv /script/framework_config.env /experiment_data/framework_config.env
cp /experiment_data/framework_config_rq1.env /script/framework_config.env

set -a
source /script/framework_config.env
set +a



# FETCH
# PARAMETERS
export BFC_REPOSITORY_PATH=/experiment/repo/bfc
export BIC_REPOSITORY_PATH=/experiment/repo/bic
source /experiment_data/$TARGET/repo_fetch.sh

# install project-specific dependencies
source /experiment_data/$TARGET/subject_dep.sh


# APPLY MAGMA PATCH AND GENERATE BREAKPOINTS
source /experiment_data/$TARGET/magma_patches.sh > /experiment_data/$TARGET/target_commit_info/patch_result
cat /experiment_data/$TARGET/target_commit_info/patch_result

mkdir -p /experiment_data/$TARGET/target_commit_info/breakpoint_variables
python3 /script/watcher/extract-patched-changes-fixed-bps.py \
    --repository_path $BIC_REPOSITORY_PATH \
    --output_breakpoint_file /experiment_data/$TARGET/target_commit_info/bic_breakpoints 

cp /experiment_data/$TARGET/target_commit_info/bic_breakpoints /experiment_data/$TARGET/target_commit_info/bfc_breakpoints


# BUILD
# UPDATE FUZZER
set -a
source /script/setup_fuzzer.sh
set +a

# PARAMETERS
export BFC_BINARY_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/bin/bfc
export BIC_BINARY_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/bin/bic
export BFC_TARGET=$BFC_BINARY_PATH/target
export BIC_TARGET=$BIC_BINARY_PATH/target
export INITIAL_SEED_PATH=/experiment_data/$TARGET/initial_seeds
mkdir -p $INITIAL_SEED_PATH
# TARGETS CAN BE MODIFIED IF PERFORMANCE IS CONCERNING
mkdir -p $BFC_BINARY_PATH
mkdir -p $BIC_BINARY_PATH
source /experiment_data/$TARGET/build.sh

# MAGMA SEEDS
source /experiment_data/$TARGET/seed.sh

# FUZZING
# FUZZING PARAMETERS
export BIC_INPUT_QUEUE_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/final_corpus
mkdir -p $BIC_INPUT_QUEUE_PATH
source /script/watcher/fuzz.sh $BIC_TARGET $INITIAL_SEED_PATH $BIC_INPUT_QUEUE_PATH

cd /workdir 

# DEBUG
# EXECUTION TRACE PARAMETERS - AUTO VARS
# BFC - CLEAN VERSION
export EXECUTION_TARGET=$BFC_TARGET
export REPOSITORY_PATH=$BFC_REPOSITORY_PATH
export FINAL_CORPUS_PATH=$BIC_INPUT_QUEUE_PATH
export TARGET_BREAKPOINTS=/experiment_data/$TARGET/target_commit_info/bfc_breakpoints
export BFC_DEBUG_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/bfc_debug
export DEBUG_PATH=$BFC_DEBUG_PATH
source /script/watcher/execution-debug-auto-var.sh

# BIC - BUGGY VERSION
export EXECUTION_TARGET=$BIC_TARGET
export REPOSITORY_PATH=$BIC_REPOSITORY_PATH
export FINAL_CORPUS_PATH=$BIC_INPUT_QUEUE_PATH
export TARGET_BREAKPOINTS=/experiment_data/$TARGET/target_commit_info/bic_breakpoints
export BIC_DEBUG_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/bic_debug
export DEBUG_PATH=$BIC_DEBUG_PATH
source /script/watcher/execution-debug-auto-var.sh

# EXECUTION TRACE AND LIKELY INVARIANT MINING
# TRACE GENERATION AND LIKELY INVARIANT PARAMETERS
export BFC_TRACE_OUTPUT_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/bfc_trace
export BFC_INVARIANT_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/bfc_invariant
export BIC_TRACE_OUTPUT_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/bic_trace
export BIC_INVARIANT_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/bic_invariant
python3 /script/analyzer/generate_trace_and_invariant_auto_var_thread_sync.py \
    --bfc_debug_output_path $BFC_DEBUG_PATH/result \
    --bfc_trace_output_path $BFC_TRACE_OUTPUT_PATH \
    --bfc_invariant_output_path $BFC_INVARIANT_PATH \
    --bic_debug_output_path $BIC_DEBUG_PATH/result \
    --bic_trace_output_path $BIC_TRACE_OUTPUT_PATH \
    --bic_invariant_output_path $BIC_INVARIANT_PATH \
    --max_threads=8



# LIKELY INVARIANT DISTANCE ANALYSIS
# DISTANCE CALCULATION AND ANALYSIS PARAMETERS
export INVARIANT_SCORE_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/distance_cross_version
export INVARIANT_FILE=$INVARIANT_SCORE_PATH/invariant_object
export INVARIANT_SCORE_TEXT=$INVARIANT_SCORE_PATH/invariant_score
mkdir -p $INVARIANT_SCORE_PATH
python3 /script/analyzer/analyze_invariants_thread_cross_version.py \
    --bfc_invariant_output_path $BFC_INVARIANT_PATH \
    --bic_invariant_output_path $BIC_INVARIANT_PATH \
    --stored_invariant_output_file $INVARIANT_FILE \
    --stored_invariant_score_text $INVARIANT_SCORE_TEXT \
    --max_threads 8



# RESET FRAMEWORK CONFIGURATIONS - ONLY FOR RQ1
rm /script/framework_config.env
mv /experiment_data/framework_config.env /script/framework_config.env

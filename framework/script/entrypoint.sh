#!/bin/bash

# LOAD FRAMEWORK CONFIGURATIONS
set -a
source /script/framework_config.env
set +a

# LOAD TARGET COMMITS TO BE FETCHED
set -a
source /subject_data/target_commit_info/target_commits.env
set +a

# TARGET FETCHING
source /subject_data/repo_fetch.sh

# install project-specific dependencies
source /subject_data/subject_dep.sh

# BUILD
# UPDATE FUZZER
set -a
source /script/setup_fuzzer.sh
set +a

# PARAMETERS
export BFC_TARGET=/subject_data/$FUZZING_TOOL/bin/bfc/target
export BIC_TARGET=/subject_data/$FUZZING_TOOL/bin/bic/target
export INITIAL_SEED_PATH=/subject_data/initial_seeds
mkdir -p /subject_data/$FUZZING_TOOL/bin/bfc
mkdir -p /subject_data/$FUZZING_TOOL/bin/bic
mkdir -p $INITIAL_SEED_PATH
source /subject_data/build.sh

# FUZZING
# FUZZING PARAMETERS
export BIC_INPUT_QUEUE_PATH=/subject_data/$FUZZING_TOOL/final_corpus
mkdir -p $BIC_INPUT_QUEUE_PATH
source /script/watcher/fuzz-single.sh $BIC_TARGET $INITIAL_SEED_PATH $BIC_INPUT_QUEUE_PATH

cd /workdir 

# EXECUTION TRACE
# EXECUTION TRACE PARAMETERS
export BREAKPOINT_VARIABLE_PATH=/subject_data/target_commit_info/breakpoint_variables
# BFC - PRIOR VERSION
export EXECUTION_TARGET=$BFC_TARGET
export REPOSITORY_PATH=/subject/repo/bfc
export FINAL_CORPUS_PATH=$BIC_INPUT_QUEUE_PATH
export TARGET_BREAKPOINTS=/subject_data/target_commit_info/bfc_breakpoints
export TARGET_VARIABLE_PATH=$BREAKPOINT_VARIABLE_PATH
export BFC_DEBUG_PATH=/subject_data/$FUZZING_TOOL/bfc_debug
export DEBUG_PATH=$BFC_DEBUG_PATH
source /script/watcher/execution-debug.sh

# BIC - NEW VERSION
export EXECUTION_TARGET=$BIC_TARGET
export REPOSITORY_PATH=/subject/repo/bic
export FINAL_CORPUS_PATH=$BIC_INPUT_QUEUE_PATH
export TARGET_BREAKPOINTS=/subject_data/target_commit_info/bic_breakpoints
export TARGET_VARIABLE_PATH=$BREAKPOINT_VARIABLE_PATH
export BIC_DEBUG_PATH=/subject_data/$FUZZING_TOOL/bic_debug
export DEBUG_PATH=$BIC_DEBUG_PATH
source /script/watcher/execution-debug.sh

# TRACE GENERATION AND LIKELY INVARIANT MINING
# TRACE GENERATION AND LIKELY INVARIANT PARAMETERS
export BFC_TRACE_OUTPUT_PATH=/subject_data/$FUZZING_TOOL/bfc_trace
export BFC_INVARIANT_PATH=/subject_data/$FUZZING_TOOL/bfc_invariant
export BIC_TRACE_OUTPUT_PATH=/subject_data/$FUZZING_TOOL/bic_trace
export BIC_INVARIANT_PATH=/subject_data/$FUZZING_TOOL/bic_invariant
python3 /script/analyzer/generate_trace_and_invariant_thread_sync.py \
    --target_variable_path $BREAKPOINT_VARIABLE_PATH \
    --bfc_debug_output_path $BFC_DEBUG_PATH/result \
    --bfc_trace_output_path $BFC_TRACE_OUTPUT_PATH \
    --bfc_invariant_output_path $BFC_INVARIANT_PATH \
    --bic_debug_output_path $BIC_DEBUG_PATH/result \
    --bic_trace_output_path $BIC_TRACE_OUTPUT_PATH \
    --bic_invariant_output_path $BIC_INVARIANT_PATH \
    --max_threads=8

# DISTANCE CALCULATION AND ANALYSIS
# DISTANCE CALCULATION AND ANALYSIS PARAMETERS
export INVARIANT_SCORE_PATH=/subject_data/$FUZZING_TOOL/distance_cross_version
export INVARIANT_FILE=$INVARIANT_SCORE_PATH/invariant_object
export INVARIANT_SCORE_TEXT=$INVARIANT_SCORE_PATH/invariant_score
mkdir -p $INVARIANT_SCORE_PATH
python3 /script/analyzer/analyze_invariants_thread_cross_version.py \
    --bfc_invariant_output_path $BFC_INVARIANT_PATH \
    --bic_invariant_output_path $BIC_INVARIANT_PATH \
    --stored_invariant_output_file $INVARIANT_FILE \
    --stored_invariant_score_text $INVARIANT_SCORE_TEXT \
    --max_threads 8

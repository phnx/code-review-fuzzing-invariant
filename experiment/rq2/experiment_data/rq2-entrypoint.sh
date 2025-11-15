#!/bin/bash


# LOAD FRAMEWORK CONFIGURATIONS
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


# BUILD
# UPDATE FUZZER
set -a
source /script/setup_fuzzer.sh
set +a

# BUILD
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


# CSR-FUZZING
export BFC_INPUT_QUEUE_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/csr_test_corpus
export CSR_CORPUS_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/csr_seed_corpus
export BIC_COMMIT_CHANGES=/experiment_data/$TARGET/target_commit_info/bic_changes
export BIC_COVERAGE_PATH=/experiment/coverage
export BIC_COVERAGE_HIT_PATH=/experiment/coverage/hit
mkdir -p $BFC_INPUT_QUEUE_PATH
mkdir -p $BIC_COVERAGE_HIT_PATH
source /script/watcher/fuzz.sh $BFC_TARGET $INITIAL_SEED_PATH $BFC_INPUT_QUEUE_PATH

cd /workdir 

source /script/watcher/execution-test-csr.sh

if [ "$(ls -A $CSR_CORPUS_PATH)" ]; then
    echo "some CSR seeds are available "
else
    echo "CSR seeds not available, fuzz BIC with initial corpus"
    export CSR_CORPUS_PATH=$INITIAL_SEED_PATH
fi


# FUZZING WITH CSR SEEDS
export BIC_INPUT_QUEUE_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/final_corpus
mkdir -p $BIC_INPUT_QUEUE_PATH
source /script/watcher/fuzz.sh $BIC_TARGET $CSR_CORPUS_PATH $BIC_INPUT_QUEUE_PATH

cd /workdir 

# DEBUG
# EXECUTION TRACE PARAMETERS
export BREAKPOINT_VARIABLE_PATH=/experiment_data/$TARGET/target_commit_info/breakpoint_variables
# BFC - PRIOR VERSION
export EXECUTION_TARGET=$BFC_TARGET
export REPOSITORY_PATH=$BFC_REPOSITORY_PATH
export FINAL_CORPUS_PATH=$BIC_INPUT_QUEUE_PATH
export TARGET_BREAKPOINTS=/experiment_data/$TARGET/target_commit_info/bfc_breakpoints
export TARGET_VARIABLE_PATH=$BREAKPOINT_VARIABLE_PATH
export BFC_DEBUG_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/bfc_debug
export DEBUG_PATH=$BFC_DEBUG_PATH
source /script/watcher/execution-debug.sh

# BIC - NEW VERSION
export EXECUTION_TARGET=$BIC_TARGET
export REPOSITORY_PATH=$BIC_REPOSITORY_PATH
export FINAL_CORPUS_PATH=$BIC_INPUT_QUEUE_PATH
export TARGET_BREAKPOINTS=/experiment_data/$TARGET/target_commit_info/bic_breakpoints
export TARGET_VARIABLE_PATH=$BREAKPOINT_VARIABLE_PATH
export BIC_DEBUG_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/bic_debug
export DEBUG_PATH=$BIC_DEBUG_PATH
source /script/watcher/execution-debug.sh

# EXECUTION TRACE AND LIKELY INVARIANT MINING
# TRACE GENERATION AND LIKELY INVARIANT PARAMETERS
export BFC_TRACE_OUTPUT_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/bfc_trace
export BFC_INVARIANT_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/bfc_invariant
export BIC_TRACE_OUTPUT_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/bic_trace
export BIC_INVARIANT_PATH=/experiment_data/$TARGET/$FUZZING_TOOL/bic_invariant
python3 /script/analyzer/generate_trace_and_invariant_thread_sync.py \
    --target_variable_path $BREAKPOINT_VARIABLE_PATH \
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

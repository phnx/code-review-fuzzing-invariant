# !/bin/bash
# this script creates debugging script and captures execution trace using selected CSR seeds
# since this can be used for both bug-inducing commit and bug-free commit, the pre-requisite variables are used
# pre-requisites:
#     - EXECUTION_TARGET: coverage-enable binary (bug-inducing or bug-free version)
#     - FINAL_CORPUS_PATH: path that contains testing input files
#     - REPOSITORY_PATH: path to respository (bug-inducing or bug-free version) - to maintain absolute path for debugging
#     - COMMIT_CHANGES: path to store commit changes information
#     - TARGET_BREAKPOINTS: path to store selected breakpoints information
#     - TARGET_VARIABLE_PATH: path to store observed variables information at each breakpoint
#     - DEBUG_PATH: path to store debug script and trace


for INPUT_FILEPATH in "$FINAL_CORPUS_PATH"/*
do

    # coverage test
    echo "========================"
    echo "execution test: $INPUT_FILEPATH"

    INPUT_FILENAME=$(basename "$INPUT_FILEPATH")
    
    DEBUG_SCRIPT_PATH=$DEBUG_PATH/script/$INPUT_FILENAME
    DEBUG_OUTPUT_PATH=$DEBUG_PATH/result/$INPUT_FILENAME

    mkdir -p $DEBUG_SCRIPT_PATH
    mkdir -p $DEBUG_OUTPUT_PATH

    # skip if batch debug result file already exists
    if [[ -s "$DEBUG_OUTPUT_PATH/batch" ]]; then
        echo "batch debug result exists, skip"
    fi

    python3 /script/watcher/script_generation_batch.py \
        --repository_path $REPOSITORY_PATH \
        --target_variable_path $TARGET_VARIABLE_PATH \
        --target_breakpoint_file $TARGET_BREAKPOINTS \
        --test_input $INPUT_FILEPATH \
        --debug_script_path $DEBUG_SCRIPT_PATH \
        --execution_target $EXECUTION_TARGET \
        --debug_output_path $DEBUG_OUTPUT_PATH

    # in DRYRUN mode, terminate if script generation returns abnormal exit code
    if [ $? -ne 0 ] && [ -n "$DRYRUN" ]; then
        echo "Error during automated debugging, it's likely that some variables are undefined at a breakpoint"
        exit 1
    fi

done

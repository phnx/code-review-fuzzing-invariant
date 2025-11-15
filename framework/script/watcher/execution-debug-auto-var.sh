# !/bin/bash
# this script creates debugging script and captures execution trace using selected CSR seeds
# since this can be used for both bug-inducing commit and bug-free commit, the pre-requisite variables are used
# pre-requisites:
#     - EXECUTION_TARGET: coverage-enable binary (bug-inducing or bug-free version)
#     - FINAL_CORPUS_PATH: path that contains testing input files
#     - REPOSITORY_PATH: path to respository (bug-inducing or bug-free version) - to maintain absolute path for debugging
#     - COMMIT_CHANGES: path to store commit changes information
#     - TARGET_BREAKPOINTS: path to store selected breakpoints information
#     - DEBUG_PATH: path to store debug script and trace


COUNTER=0
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

    python3 /script/watcher/script_generation_batch_auto_var.py \
        --repository_path $REPOSITORY_PATH \
        --target_breakpoint_file $TARGET_BREAKPOINTS \
        --test_input $INPUT_FILEPATH \
        --debug_script_path $DEBUG_SCRIPT_PATH \
        --execution_target $EXECUTION_TARGET \
        --debug_output_path $DEBUG_OUTPUT_PATH

    COUNTER=$((COUNTER+1))

    # in DRYRUN mode, terminate if script generation returns abnormal exit code
    # if [ $? -ne 0 ] && [ -n "$DRYRUN" ]; then
    #     echo "Error during automated debugging, it's likely that some variables are undefined at a breakpoint"
    #     exit 1
    # fi

    # short dryrun 
    if [[ "$COUNTER" -gt 1000 ]] && [ -n "$DRYRUN" ];  then
       echo "dryrun: break input loop"
       break
    fi

done

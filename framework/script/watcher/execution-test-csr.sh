# !/bin/bash
# this script run change-aware seed filtering on bug-free version
# pre-requisites:
#     - BFC_COVERAGE_TARGET: coverage-enable binary (bug-free version)
#     - BFC_INPUT_QUEUE_PATH: path that contains testing input files
#     - BIC_REPOSITORY_PATH: path to respository (bug-inducing version) - to extract changed functions
#     - BFC_REPOSITORY_PATH: path to respository (bug-free version) - to run coverage (if needed)
#     - BIC_COMMIT_CHANGES: path to store commit changes information
#     - CSR_CORPUS_PATH: path to store filtered seeds
#     - BIC_COVERAGE_PATH: coverage path for BIC during CSR
#     - BIC_COVERAGE_HIT_PATH: path that stores the hit changes in BIC during CSR

export WATCHER_DIR=$PWD
export EXECUTION_TIMEOUT=$LLDB_TIMEOUT_SEC

rm -rf $CSR_CORPUS_PATH
mkdir -p $CSR_CORPUS_PATH

# if not exist, extract commit change
# reset git ownership just in case
if [[ ! -s $BIC_COMMIT_CHANGES ]]; then
    echo "commit changes information not exist, extract commit changes"
    git config --global --add safe.directory '*'  
    python3 /script/watcher/extract-commit-changes.py $BIC_REPOSITORY_PATH > $BIC_COMMIT_CHANGES
fi

cd $BFC_REPOSITORY_PATH

for INPUT_FILEPATH in "$BFC_INPUT_QUEUE_PATH"/*
do

    # coverage test
    echo "========================"
    echo "execution test csr: $INPUT_FILEPATH"

    INPUT_FILENAME=$(basename "$INPUT_FILEPATH")
    HIT_OUTPUT=$BIC_COVERAGE_HIT_PATH/$INPUT_FILENAME

    # run profiling target with an input
    # LLVM_PROFILE_FILE="crf.profraw" $BFC_COVERAGE_TARGET $INPUT_FILEPATH
    timeout $EXECUTION_TIMEOUT bash -c "LLVM_PROFILE_FILE="crf.profraw" $BFC_TARGET $INPUT_FILEPATH" 

    if [ $? -eq 0 ]; then
        
        # merge execution profiles
        llvm-profdata merge -sparse crf.profraw -o crf.profdata

        INPUT_COVERAGE=$BIC_COVERAGE_PATH/$INPUT_FILENAME.json

        # generate report
        llvm-cov export $BFC_TARGET --format=text --instr-profile=crf.profdata > $INPUT_COVERAGE
        
        # analyze the coverage result per one input
        python3 /script/watcher/llvm-coverage.py $BIC_COMMIT_CHANGES $INPUT_COVERAGE > $HIT_OUTPUT

        # delete execution coverage to save disk space, only retain hit output
        rm $INPUT_COVERAGE

        # if hit output is not empty, copy seeds to a corpus
        if [[ -s $HIT_OUTPUT ]]; then
            echo "a hit seed, copy for CSR fuzzing"
            cp $INPUT_FILEPATH $CSR_CORPUS_PATH
        fi

    else
        echo "input caused timeout (60 sec), skipped"
    fi

done

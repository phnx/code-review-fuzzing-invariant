# !/bin/bash

TARGET_BIN=$1
SEED_PATH=$2
INPUT_QUEUE_PATH=$3

# optional $INITIAL_DICTIONARY
if [ -n "$INITIAL_DICTIONARY" ]; then
  echo "dictionary exists"
fi

# timeout in seconds
export FUZZING_TIME=$FUZZING_DURATION_SEC 

# LOWER FUZZING TIME FOR DRYRUN
if [ -n "$DRYRUN" ]; then
    echo "fuzzing in dryrun mode"
  export FUZZING_TIME=300
fi

echo "start fuzzing campaign"

if [ "$FUZZING_TOOL" = "aflplusplus" ]; then
    
    export AFL_NO_UI=1

    export AFLPP_TMP_OUTPUT=/workdir/$(date +%s)

    # start a foreground master
    timeout "$FUZZING_TIME"s \
        /program/AFLplusplus/afl-fuzz -M master ${INITIAL_DICTIONARY:+-x $INITIAL_DICTIONARY}  -i $SEED_PATH -o $AFLPP_TMP_OUTPUT \
        -m none  -t 1000+ $TARGET_BIN @@
    
    # copy files from master queue to input queue path
    cp $AFLPP_TMP_OUTPUT/master/queue/* $INPUT_QUEUE_PATH

elif [ "$FUZZING_TOOL" = "honggfuzz" ]; then
    # fuzz - 1 thread
     /program/honggfuzz/honggfuzz \
            --run_time $FUZZING_TIME \
            --threads 1 \
            ${INITIAL_DICTIONARY:+--dict $INITIAL_DICTIONARY} \
            --output $INPUT_QUEUE_PATH \
            --input $SEED_PATH -- $TARGET_BIN
            
elif [ "$FUZZING_TOOL" = "libfuzzer" ]; then
    # fuzz - no fork mode, 1 job
    $TARGET_BIN \
            -max_total_time=$FUZZING_TIME \
            -reduce_inputs=0 \
            -use_value_profile=1 \
            -ignore_crashes=1 \
            -fork=1 \
            ${INITIAL_DICTIONARY:+-dict=$INITIAL_DICTIONARY} \
            $INPUT_QUEUE_PATH \
            $SEED_PATH

else
    echo "unknown fuzzing tool, stop"
    exit 1
fi

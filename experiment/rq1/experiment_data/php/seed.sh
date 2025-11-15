# !/bin/bash

cd $BFC_REPOSITORY_PATH
sapi/cli/php sapi/fuzzer/generate_unserialize_dict.php
sapi/cli/php sapi/fuzzer/generate_parser_corpus.php

for fuzzerName in `ls sapi/fuzzer/corpus`; do
    mkdir -p "$INITIAL_SEED_PATH/${fuzzerName}"
    cp sapi/fuzzer/corpus/${fuzzerName}/* "$INITIAL_SEED_PATH/${fuzzerName}/"
done

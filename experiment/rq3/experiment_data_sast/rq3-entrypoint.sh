#!/bin/bash


# SAST EXECUTION
declare -a targets=("arrow-40653" \
    "aspell-18462" \
    "curl-8000" \
    "exiv2-50315" \
    "file-30222" \
    "grok-28418" \
    "harfbuzz-55779" \
    "leptonica-25212" \
    "libarchive-44843" \
    "libhtp-17198" \
    "libxml2-17737" \
    "ndpi-49057" \
    "openh264-26220" \
    "openssl-17715" \
    "pcapplusplus-23592" \
    "readstat-13262" \
    "usrsctp-18080" \
    "zstd-21970"
)

for  i in ${!targets[@]}; do
    TARGET=${targets[$i]}
    source /script/sast/codechecker/analyze-target.sh $TARGET
    source /script/sast/codeql/analyze-target.sh $TARGET
    source /script/sast/flawfinder/analyze-target.sh $TARGET
done

cd /script/sast
# ANALYZE RESULT
python3 /script/sast/analye_result.py

# CALL GRAPH ANALYSIS
python3 /script/sast/analye_call_graph.py

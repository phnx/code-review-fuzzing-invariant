# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone https://github.com/cisco/openh264.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# BIC
git -C $BIC_REPOSITORY_PATH fetch origin effb3931c7c67f34b167fe6e0a93253bf075f78c && \
git -C $BIC_REPOSITORY_PATH checkout effb3931c7c67f34b167fe6e0a93253bf075f78c

# BFC
git -C $BFC_REPOSITORY_PATH fetch origin 23d97aacd8fde711eb9ebf35d8381bc025b13a71 && \
git -C $BFC_REPOSITORY_PATH checkout 23d97aacd8fde711eb9ebf35d8381bc025b13a71

# fuzz driver
# download target
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/openh264-26220/decoder_fuzzer.cpp \
    -O /workdir/decoder_fuzzer.cpp

# seed corpus - recently changed in ossfuzz
# git clone https://github.com/mozillasecurity/fuzzdata.git /workdir/fuzzdata
# git -C /workdir/fuzzdata checkout effb3931c7c67f34b167fe6e0a93253bf075f78c

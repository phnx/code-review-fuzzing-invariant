# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone https://github.com/curl/curl.git $BFC_REPOSITORY_PATH/curl && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# BIC
git -C $BIC_REPOSITORY_PATH/curl fetch origin dd7521bcc1b7a6fcb53c31f9bd1192fcc884bd56 && \
git -C $BIC_REPOSITORY_PATH/curl checkout dd7521bcc1b7a6fcb53c31f9bd1192fcc884bd56

# BFC
git -C $BFC_REPOSITORY_PATH/curl fetch origin e6c22368c6e5426ec2b1cb8a3041ebc98d0ad402 && \
git -C $BFC_REPOSITORY_PATH/curl checkout e6c22368c6e5426ec2b1cb8a3041ebc98d0ad402

# fuzzer script
git clone https://github.com/curl/curl-fuzzer.git $BFC_REPOSITORY_PATH/curl-fuzzer
cp -r $BFC_REPOSITORY_PATH/curl-fuzzer $BIC_REPOSITORY_PATH

git -C $BFC_REPOSITORY_PATH/curl-fuzzer fetch origin c4ce63bf55674cebdad03f8bb6adb354bfc63609 && \
git -C $BFC_REPOSITORY_PATH/curl-fuzzer checkout c4ce63bf55674cebdad03f8bb6adb354bfc63609

git -C $BIC_REPOSITORY_PATH/curl-fuzzer fetch origin c4ce63bf55674cebdad03f8bb6adb354bfc63609 && \
git -C $BIC_REPOSITORY_PATH/curl-fuzzer checkout c4ce63bf55674cebdad03f8bb6adb354bfc63609


# fuzz driver
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/curl-8000/curl_fuzzer.cc \
    -O /workdir/curl_fuzzer.cc

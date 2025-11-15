# !/bin/bash

apt-get -y install zip

# run dependency script from fuzzer repo
$BFC_REPOSITORY_PATH/curl-fuzzer/scripts/ossfuzzdeps.sh
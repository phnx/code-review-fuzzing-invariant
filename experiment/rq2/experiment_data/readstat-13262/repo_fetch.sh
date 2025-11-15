# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone https://github.com/WizardMac/ReadStat.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# BIC
git -C $BIC_REPOSITORY_PATH fetch origin 1de4f389a8ffb07775cb1d99e33cbfa7e96bccf2 && \
git -C $BIC_REPOSITORY_PATH checkout 1de4f389a8ffb07775cb1d99e33cbfa7e96bccf2

# BFC
git -C $BFC_REPOSITORY_PATH fetch origin d1bfd735515803800cb9708e3fca9e5c1e8e7a48 && \
git -C $BFC_REPOSITORY_PATH checkout d1bfd735515803800cb9708e3fca9e5c1e8e7a48

# fuzz driver
# download target
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/readstat-13262/fuzz_format_sas7bdat.c \
    -O /workdir/fuzz_format_sas7bdat.c

# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone https://github.com/Exiv2/exiv2.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# BIC
git -C $BIC_REPOSITORY_PATH fetch origin 10a62b23500954abf7eb2cc3e577bebb21bb0b72 && \
git -C $BIC_REPOSITORY_PATH checkout 10a62b23500954abf7eb2cc3e577bebb21bb0b72

# BFC
git -C $BFC_REPOSITORY_PATH fetch origin 7a96867f31d60eece6c2b00dc2bbfffe18d4ce44 && \
git -C $BFC_REPOSITORY_PATH checkout 7a96867f31d60eece6c2b00dc2bbfffe18d4ce44

# fuzz driver
# download target
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/exiv2-50315/fuzz-read-print-write.cpp \
    -O /workdir/fuzz-read-print-write.cpp
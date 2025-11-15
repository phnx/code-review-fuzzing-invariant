# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone https://github.com/file/file.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# BIC
git -C $BIC_REPOSITORY_PATH fetch origin 6de3683de955277c4be4be350ec683b3203d3f31 && \
git -C $BIC_REPOSITORY_PATH checkout 6de3683de955277c4be4be350ec683b3203d3f31

# BFC
git -C $BFC_REPOSITORY_PATH fetch origin 7cbc03a7c3df89d2e93f15ff9d4714f7757f4931 && \
git -C $BFC_REPOSITORY_PATH checkout 7cbc03a7c3df89d2e93f15ff9d4714f7757f4931

# fuzz driver
# download target
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/file-30222/magic_fuzzer.cc \
    -O /workdir/magic_fuzzer.cc

# extra corpus
git clone --depth 1 https://github.com/DavidKorczynski/binary-samples.git $BFC_REPOSITORY_PATH/binary-samples
git clone --depth 1 https://github.com/corkami/pocs $BFC_REPOSITORY_PATH/pocs
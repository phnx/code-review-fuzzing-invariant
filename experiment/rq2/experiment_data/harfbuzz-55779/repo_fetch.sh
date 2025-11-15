# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone https://github.com/harfbuzz/harfbuzz.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# BIC
git -C $BIC_REPOSITORY_PATH fetch origin 8708b9e081192786c027bb7f5f23d76dbe5c19e8 && \
git -C $BIC_REPOSITORY_PATH checkout 8708b9e081192786c027bb7f5f23d76dbe5c19e8

# BFC
git -C $BFC_REPOSITORY_PATH fetch origin 661050b4659ee490dfe622821bc7fde7d1c40510 && \
git -C $BFC_REPOSITORY_PATH checkout 661050b4659ee490dfe622821bc7fde7d1c40510

# fuzz driver
# download target
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/harfbuzz-55779/hb-shape-fuzzer.cc \
    -O /workdir/hb-shape-fuzzer.cc

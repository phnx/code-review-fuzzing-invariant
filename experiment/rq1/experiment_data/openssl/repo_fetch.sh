# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/openssl/openssl.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# checkout base commit for both BFC and BIC
# BIC
git -C $BIC_REPOSITORY_PATH checkout 3bd5319b5d0df9ecf05c8baba2c401ad8e3ba130

# BFC
git -C $BFC_REPOSITORY_PATH checkout 3bd5319b5d0df9ecf05c8baba2c401ad8e3ba130

# fuzz target
cp "/magma/targets/openssl/src/abilist.txt" \
    "$BFC_REPOSITORY_PATH/abilist.txt"

cp "/magma/targets/openssl/src/abilist.txt" \
    "$BIC_REPOSITORY_PATH/abilist.txt"
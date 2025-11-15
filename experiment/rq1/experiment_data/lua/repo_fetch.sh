# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/lua/lua.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# checkout base commit for both BFC and BIC
# BIC
git -C $BIC_REPOSITORY_PATH checkout dbdc74dc5502c2e05e1c1e2ac894943f418c8431

# BFC
git -C $BFC_REPOSITORY_PATH checkout dbdc74dc5502c2e05e1c1e2ac894943f418c8431

# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/glennrp/libpng.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# checkout base commit for both BFC and BIC
# BIC
git -C $BIC_REPOSITORY_PATH checkout a37d4836519517bdce6cb9d956092321eca3e73b

# BFC
git -C $BFC_REPOSITORY_PATH checkout a37d4836519517bdce6cb9d956092321eca3e73b

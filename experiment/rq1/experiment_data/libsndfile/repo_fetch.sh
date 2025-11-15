# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/libsndfile/libsndfile.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# checkout base commit for both BFC and BIC
# BIC
git -C $BIC_REPOSITORY_PATH checkout 86c9f9eb7022d186ad4d0689487e7d4f04ce2b29

# BFC
git -C $BFC_REPOSITORY_PATH checkout 86c9f9eb7022d186ad4d0689487e7d4f04ce2b29

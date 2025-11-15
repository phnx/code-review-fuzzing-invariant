# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/php/php-src.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# checkout base commit for both BFC and BIC
# BIC
git -C $BIC_REPOSITORY_PATH checkout bc39abe8c3c492e29bc5d60ca58442040bbf063b

# BFC
git -C $BFC_REPOSITORY_PATH checkout bc39abe8c3c492e29bc5d60ca58442040bbf063b

# dependency
git clone --no-checkout https://github.com/kkos/oniguruma.git "/workdir/oniguruma" && \
git -C "/workdir/oniguruma" checkout 227ec0bd690207812793c09ad70024707c405376
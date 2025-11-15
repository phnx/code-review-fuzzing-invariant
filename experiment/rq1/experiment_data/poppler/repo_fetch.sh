# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://gitlab.freedesktop.org/poppler/poppler.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# checkout base commit for both BFC and BIC
# BIC
git -C $BIC_REPOSITORY_PATH checkout 1d23101ccebe14261c6afc024ea14f29d209e760

# BFC
git -C $BFC_REPOSITORY_PATH checkout 1d23101ccebe14261c6afc024ea14f29d209e760

# dependency
git clone --no-checkout https://gitlab.freedesktop.org/freetype/freetype.git "/workdir/freetype2" && \
git -C "/workdir/freetype2" checkout 50d0033f7ee600c5f5831b28877353769d1f7d48
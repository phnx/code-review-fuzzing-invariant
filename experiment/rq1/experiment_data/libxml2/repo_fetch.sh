# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://gitlab.gnome.org/GNOME/libxml2.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# checkout base commit for both BFC and BIC
# BIC
git -C $BIC_REPOSITORY_PATH checkout ec6e3efb06d7b15cf5a2328fabd3845acea4c815

# BFC
git -C $BFC_REPOSITORY_PATH checkout ec6e3efb06d7b15cf5a2328fabd3845acea4c815

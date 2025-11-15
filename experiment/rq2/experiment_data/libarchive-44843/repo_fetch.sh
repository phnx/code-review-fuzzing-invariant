# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone https://github.com/libarchive/libarchive.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# BIC
git -C $BIC_REPOSITORY_PATH fetch origin 52efa50c69653029687bfc545703b7340b7a51e2 && \
git -C $BIC_REPOSITORY_PATH checkout 52efa50c69653029687bfc545703b7340b7a51e2

# BFC
git -C $BFC_REPOSITORY_PATH fetch origin 4af83bbfe082056f8f5e2b2ce7f8cf31ac2bd4fb && \
git -C $BFC_REPOSITORY_PATH checkout 4af83bbfe082056f8f5e2b2ce7f8cf31ac2bd4fb

# dependency
git clone https://gitlab.gnome.org/GNOME/libxml2.git /workdir/libxml2 && \
git -C /workdir/libxml2 fetch origin b041d829a211072bdab0026219b5a428268648d4 && \
git -C /workdir/libxml2 checkout b041d829a211072bdab0026219b5a428268648d4


# fuzz driver
# download target
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/libarchive-44843/libarchive_fuzzer.cc \
    -O /workdir/libarchive_fuzzer.cc

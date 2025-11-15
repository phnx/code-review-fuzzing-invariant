# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone https://github.com/gnuaspell/aspell.git $BFC_REPOSITORY_PATH/aspell && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# BIC
git -C $BIC_REPOSITORY_PATH/aspell fetch origin e0646f9b063b23754951f1254f1ecb7af8ca36f3 && \
git -C $BIC_REPOSITORY_PATH/aspell checkout e0646f9b063b23754951f1254f1ecb7af8ca36f3

# BFC
git -C $BFC_REPOSITORY_PATH/aspell fetch origin bc5e450fc020dc928dfecf7f82c9e7129bf2f2e3 && \
git -C $BFC_REPOSITORY_PATH/aspell checkout bc5e450fc020dc928dfecf7f82c9e7129bf2f2e3

# fuzz driver
# download target
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/aspell-18462/aspell_fuzzer.cpp \
    -O /workdir/aspell_fuzzer.cpp

# fuzz helper
# recent master is commit fa4aa32c6bf9573801a7675137e1c31b9f13247f
git clone https://github.com/gnuaspell/aspell-fuzz.git "$BFC_REPOSITORY_PATH/aspell-fuzz"
rm -rf "$BIC_REPOSITORY_PATH/aspell-fuzz"
mkdir -p "$BIC_REPOSITORY_PATH/aspell-fuzz"
cp -r "$BFC_REPOSITORY_PATH/aspell-fuzz" "$BIC_REPOSITORY_PATH"

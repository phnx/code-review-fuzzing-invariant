# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://gitlab.com/libtiff/libtiff.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# checkout base commit for both BFC and BIC
# BIC
git -C $BIC_REPOSITORY_PATH checkout c145a6c14978f73bb484c955eb9f84203efcb12e

# BFC
git -C $BFC_REPOSITORY_PATH checkout c145a6c14978f73bb484c955eb9f84203efcb12e

# fuzz target
cp "/magma/targets/libtiff/src/tiff_read_rgba_fuzzer.cc" \
    "$BFC_REPOSITORY_PATH/contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc"

cp "/magma/targets/libtiff/src/tiff_read_rgba_fuzzer.cc" \
    "$BIC_REPOSITORY_PATH/contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc"
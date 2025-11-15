# !/bin/bash
# example repo fetch script, taken from rq2:libhtp

echo "clone subject and checkout target commits"

rm -rf /subject/repo
mkdir -p /subject/repo

git clone https://github.com/OISF/libhtp.git /subject/repo/bfc && \
cp -r /subject/repo/bfc /subject/repo/bic

# BIC
git -C /subject/repo/bic fetch origin $NEW_VERSION_COMMIT_SHA && \
git -C /subject/repo/bic checkout $NEW_VERSION_COMMIT_SHA

# BFC
git -C /subject/repo/bfc fetch origin $PRIOR_VERSION_COMMIT_SHA && \
git -C /subject/repo/bfc checkout $PRIOR_VERSION_COMMIT_SHA

# fuzz driver
# download target and header from BugOSS
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/libhtp-17198/fuzz_htp.c \
    -O /workdir/fuzz_htp.c

wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/libhtp-17198/fuzz_htp.h \
    -O /workdir/fuzz_htp.h
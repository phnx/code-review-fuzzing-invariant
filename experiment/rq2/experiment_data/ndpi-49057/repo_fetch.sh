# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone https://github.com/ntop/nDPI.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# BIC
git -C $BIC_REPOSITORY_PATH fetch origin 2edfaeba4ada90ca8771a44132d2b9cc85e45570 && \
git -C $BIC_REPOSITORY_PATH checkout 2edfaeba4ada90ca8771a44132d2b9cc85e45570

# BFC
git -C $BFC_REPOSITORY_PATH fetch origin 997dce0f04816b4d8440f1cfa924a89e7cee4846 && \
git -C $BFC_REPOSITORY_PATH checkout 997dce0f04816b4d8440f1cfa924a89e7cee4846

# dependency
git clone --depth 1 https://github.com/json-c/json-c.git /workdir/json-c
curl -L https://www.tcpdump.org/release/libpcap-1.9.1.tar.gz > /workdir/libpcap-1.9.1.tar.gz


# fuzz driver
# download target
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/ndpi-49057/fuzz_process_packet.c \
    -O /workdir/fuzz_process_packet.c

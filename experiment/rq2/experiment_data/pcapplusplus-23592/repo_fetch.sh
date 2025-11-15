# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone https://github.com/seladb/PcapPlusPlus.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# BIC
git -C $BIC_REPOSITORY_PATH fetch origin 50aab202d24331ef35b9eff68d96ef9f97baf6a1 && \
git -C $BIC_REPOSITORY_PATH checkout 50aab202d24331ef35b9eff68d96ef9f97baf6a1

# BFC
git -C $BFC_REPOSITORY_PATH fetch origin 0a62fd3e959813ca41d71d42c86aa7cf1f55ced0 && \
git -C $BFC_REPOSITORY_PATH checkout 0a62fd3e959813ca41d71d42c86aa7cf1f55ced0

# dependency
git clone https://github.com/the-tcpdump-group/libpcap.git /workdir/libpcap && \
git -C /workdir/libpcap fetch origin 35bfb718dc84ff9beac6bb3e0c9c817a12dee3f8 && \
git -C /workdir/libpcap checkout 35bfb718dc84ff9beac6bb3e0c9c817a12dee3f8 

# fuzz driver
# download target
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/pcapplusplus-23592/FuzzTarget.cpp \
    -O /workdir/FuzzTarget.cpp

# corpus
git clone https://github.com/the-tcpdump-group/tcpdump.git /workdir/tcpdump && \
git -C /workdir/tcpdump fetch origin ea4e272785eb3a1aab6ac148f178439c86aa68ae && \
git -C /workdir/tcpdump checkout ea4e272785eb3a1aab6ac148f178439c86aa68ae 

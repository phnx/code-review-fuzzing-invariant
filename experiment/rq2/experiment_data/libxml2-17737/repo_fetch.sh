# !/bin/bash

echo "clone subject and checkout target commits"

rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone https://gitlab.gnome.org/GNOME/libxml2.git $BFC_REPOSITORY_PATH && \
cp -r $BFC_REPOSITORY_PATH $BIC_REPOSITORY_PATH

# BIC
git -C $BIC_REPOSITORY_PATH fetch origin 1fbcf4098ba2aefe241de8d7ceb229b995d8daec && \
git -C $BIC_REPOSITORY_PATH checkout 1fbcf4098ba2aefe241de8d7ceb229b995d8daec

# BFC
git -C $BFC_REPOSITORY_PATH fetch origin 0762c9b69ba01628f72eada1c64ff3d361fb5716 && \
git -C $BFC_REPOSITORY_PATH checkout 0762c9b69ba01628f72eada1c64ff3d361fb5716

# fuzz driver
# download target and header
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/libxml2-17737/libxml2_xml_reader_for_file_fuzzer.cc \
    -O /workdir/libxml2_xml_reader_for_file_fuzzer.cc
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/libxml2-17737/fuzzer_temp_file.h \
    -O /workdir/fuzzer_temp_file.h
wget https://raw.githubusercontent.com/sdevlab/BugOss/refs/heads/master/artifacts/libxml2-17737/xml.dict \
    -O /workdir/xml.dict
    
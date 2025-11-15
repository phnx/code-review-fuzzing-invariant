# !/bin/bash
export DEBIAN_FRONTEND=noninteractive

# required by llvm apt
apt-get install -y lsb-release wget software-properties-common gnupg

# install minimum llvm-15 and clang-15, via llvm apt
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
./llvm.sh 15 all

# change llvm and clang alternative
update-alternatives \
  --install /usr/lib/llvm              llvm             /usr/lib/llvm-15  20 \
  --slave   /usr/bin/llvm-config       llvm-config      /usr/bin/llvm-config-15  \
    --slave   /usr/bin/llvm-ar           llvm-ar          /usr/bin/llvm-ar-15 \
    --slave   /usr/bin/llvm-as           llvm-as          /usr/bin/llvm-as-15 \
    --slave   /usr/bin/llvm-bcanalyzer   llvm-bcanalyzer  /usr/bin/llvm-bcanalyzer-15 \
    --slave   /usr/bin/llvm-c-test       llvm-c-test      /usr/bin/llvm-c-test-15 \
    --slave   /usr/bin/llvm-cov          llvm-cov         /usr/bin/llvm-cov-15 \
    --slave   /usr/bin/llvm-diff         llvm-diff        /usr/bin/llvm-diff-15 \
    --slave   /usr/bin/llvm-dis          llvm-dis         /usr/bin/llvm-dis-15 \
    --slave   /usr/bin/llvm-dwarfdump    llvm-dwarfdump   /usr/bin/llvm-dwarfdump-15 \
    --slave   /usr/bin/llvm-extract      llvm-extract     /usr/bin/llvm-extract-15 \
    --slave   /usr/bin/llvm-link         llvm-link        /usr/bin/llvm-link-15 \
    --slave   /usr/bin/llvm-mc           llvm-mc          /usr/bin/llvm-mc-15 \
    --slave   /usr/bin/llvm-nm           llvm-nm          /usr/bin/llvm-nm-15 \
    --slave   /usr/bin/llvm-objdump      llvm-objdump     /usr/bin/llvm-objdump-15 \
    --slave   /usr/bin/llvm-ranlib       llvm-ranlib      /usr/bin/llvm-ranlib-15 \
    --slave   /usr/bin/llvm-readobj      llvm-readobj     /usr/bin/llvm-readobj-15 \
    --slave   /usr/bin/llvm-rtdyld       llvm-rtdyld      /usr/bin/llvm-rtdyld-15 \
    --slave   /usr/bin/llvm-size         llvm-size        /usr/bin/llvm-size-15 \
    --slave   /usr/bin/llvm-stress       llvm-stress      /usr/bin/llvm-stress-15 \
    --slave   /usr/bin/llvm-symbolizer   llvm-symbolizer  /usr/bin/llvm-symbolizer-15 \
    --slave   /usr/bin/llvm-tblgen       llvm-tblgen      /usr/bin/llvm-tblgen-15 \
    --slave   /usr/bin/llvm-cxxfilt      llvm-cxxfilt      /usr/bin/llvm-cxxfilt-15 \
    --slave   /usr/bin/llvm-profdata     llvm-profdata    /usr/bin/llvm-profdata-15
update-alternatives \
  --install /usr/bin/clang                 clang                  /usr/bin/clang-15     20 \
  --slave   /usr/bin/clang++               clang++                /usr/bin/clang++-15 \
  --slave   /usr/bin/clang-cpp             clang-cpp              /usr/bin/clang-cpp-15
update-alternatives \
  --install /usr/bin/lldb                 lldb                  /usr/bin/lldb-15     20 \
  --slave   /usr/bin/lldb-server          lldb-server           /usr/bin/lldb-server-15 \
  --slave   /usr/bin/lldb-instr           lldb-instr            /usr/bin/lldb-instr-15 \
  --slave   /usr/bin/lldb-argdumper       lldb-argdumper        /usr/bin/lldb-argdumper-15 \
  --slave   /usr/bin/lldb-dap             lldb-dap              /usr/bin/lldb-dap-15 

rm ./llvm.sh
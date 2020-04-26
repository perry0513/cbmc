# Dependencies:
# Docker
# Flex
# Bison
# g++ version 5.0 or newer

home=$(pwd)

# Download CBMC
git clone https://github.com/diffblue/cbmc.git
# Compile CBMC (https://github.com/diffblue/cbmc/blob/develop/COMPILING.md#what-architecture)
cd cbmc/src
make minisat2-download
make LINKFLAGS=-static -j36
export PATH=$PATH:$(pwd)/cbmc/
export PATH=$PATH:$(pwd)/goto-instrument/
export PATH=$PATH:$(pwd)/goto-cc/
export PATH=$PATH:$(pwd)/goto-diff/
cd $home

# Download one-line-scan
git clone https://github.com/awslabs/one-line-scan.git
export PATH=$PATH:$(pwd)/one-line-scan/configuration


# Download Xen:
git clone https://github.com/nmanthey/xen.git
cd xen
time one-line-scan --no-analysis --trunc-existing --extra-cflags -Wno-error -o CPROVER -j 8 -- make xen -j$(nproc) -k
./compile_stub_syscall.sh
cd xen/arch/x86/
./generic-compile-xsa200.sh harness.o
cd ../../common
./compile_get_cpu_info.sh
./compile_multicallstub.sh
cd ../
mv xen-syms xen.binary
goto-cc xen.binary common/get_cpu_info.o  -o xen-syms.binary

cd $home

VEGEN_DIR=`pwd`/$1
BENCH_DIR=`pwd`/$2

export CXX=`pwd`/llvm-build/bin/clang++

export GSLP_BUILD_DIR=`pwd`/vegen-build
source $VEGEN_DIR/extra-clang-flags.sh
export OPTFLAGS=$CLANG_FLAGS
cd $BENCH_DIR
git checkout asplos-ae
make clean
make 

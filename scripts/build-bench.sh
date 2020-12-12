VEGEN_DIR=`pwd`/$1
BENCH_DIR=`pwd`/$2

export CXX=`pwd`/llvm-build/bin/clang++

cd $BENCH_DIR
git checkout asplos-ae
make clean
make report

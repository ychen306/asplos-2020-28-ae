SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
git clone https://github.com/llvm/llvm-project
git clone https://github.com/ychen306/intrinsics-semantics vegen
git clone https://github.com/ychen306/vegenbench
bash -x $SCRIPT_DIR/build-llvm.sh llvm-project
CXX=clang++ bash -x $SCRIPT_DIR/build-vegen.sh vegen

source vegen/flags.sh vegen-build
bash -x $SCRIPT_DIR/build-bench.sh vegen vegenbench

export MY_CC=`pwd`/llvm-build/bin/clang

git clone https://github.com/ychen306/NPB3.0-omp-C nas-vegen
cd nas-vegen
git checkout asplos-ae-vegen
mkdir bin
make bt cg ep ft is lu mg sp CLASS=A
cd -

git clone https://github.com/ychen306/NPB3.0-omp-C nas-clang
cd nas-clang
git checkout asplos-ae-clang
mkdir bin
make bt cg ep ft is lu mg sp CLASS=A
cd - 

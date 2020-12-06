# switch llvm to the version we are using
LLVM_DIR=`pwd`/$1
cd $LLVM_DIR
git checkout 8a304606971d4884fef330ea00d6898c9291abff
cd -

rm -rf llvm-build
mkdir -p llvm-build
cd llvm-build
cmake -DLLVM_ENABLE_PROJECTS=clang -DCMAKE_CXX_COMPILERS=$CXX -DLLVM_TARGETS_TO_BUILD=X86 -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=On $LLVM_DIR/llvm
make -j 36

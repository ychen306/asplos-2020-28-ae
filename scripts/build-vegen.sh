LLVM_BUILD_DIR=`pwd`/llvm-build

VEGEN_DIR=`pwd`/$1

CXX=`which $CXX`

export PATH=$LLVM_BUILD_DIR/bin:$PATH

cd $VEGEN_DIR
#git checkout asplos-ae
cd -

rm -rf vegen-build
mkdir vegen-build
cd vegen-build
cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_COMPILER=$CXX -DCMAKE_PREFIX_PATH=$LLVM_BUILD_DIR $VEGEN_DIR
make -j

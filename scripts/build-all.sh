SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
git clone https://github.com/llvm/llvm-project
git clone https://github.com/ychen306/intrinsics-semantics vegen
git clone https://github.com/ychen306/vegenbench
bash -x $SCRIPT_DIR/build-llvm.sh llvm-project
bash -x $SCRIPT_DIR/build-vegen.sh vegen
source vegen/flags.sh vegen-build
bash -x $SCRIPT_DIR/build-bench.sh vegen vegenbench

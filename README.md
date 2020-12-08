# VeGen Artifact Evaluation

## Introduction
This repository contains the scripts and guide for the paper, VeGen: A Vectorizer Generator for SIMD and Beyond.

This guide has two parts -
 - Reproducing the optimization results
 - Reproducing the auto-generated vectorizer

Although logically the first part depends on the first part,
we have a copy of the generated vectorizer so they can be done independently.

## Requirements
You would need the following dependencies -
 - make
 - cmake
 - c++ compiler (we recommend
clang++ which is significantly faster at compiling our generated vectorizer)
 - git
 - bash
 - Intel [SDE](https://software.intel.com/content/www/us/en/develop/articles/intel-software-development-emulator.html) (This is only necessary if you want to reproduce the semantic extraction from intel's documentation).
 - python3
 - python3 libraries, all of which can be installed via pip.
   - ply
   - tqdm
   - z3-solver
   - bitstring
   - llvmlite

## Evaluation
In a preferably empty directory (or this repository),
 run the following command.
```bash
CXX=<c++ compiler of your choice> <path-to-this-repo>/scripts/build-all.sh
```
This process checks out VeGen, the evaluation benchmarks, builds the specific version of LLVM that VeGen uses,
and should take about half an hour, depending on your machine.
We hardcoded the number of threads that `make` can use to 36 in the scripts.
You can modify this.
After this, you should see the following directories.
 - `llvm-project`
 - `llvm-build`
 - `vegen`
 - `vegen-build`
 - `vegen-bench`

`vegen` is the impelementation of VeGen,
 including its vectorizer generator (`vegen/sema`)
 and its target-independent vectorization heuristic (`vegen/gslp`).
`vegenbench` is the benchmark suite.

### Benchmarking
There are three sets of benchmarks/tests inside `vegenbench`.
 - `bench`. These are real-world DSP kernels we ported from FFmpeg and x265.
 - `synthetic`. These are the synthetic backend codegen test we ported from LLVM's unit test.
 - `dotprod`. These are some integer dot-product kernels we ported from OpenCV.

Each set of benchmarks is has its standalone executable optimized by VeGen (e.g., `bench`), which takes no argument;
each also has a reference version (i.e., executables postfixed with `-ref`) optimized with standard LLVM `-O3` passes.
Use the following command to get the speedup.
```bash
python3 get-speedup.py
```

### Using VeGen as an optimization pass
There are some boilerplate Clang flags you need to set to use VeGen.
These flags are set automatically by our benchmarking scripts.
If you want to use VeGen outside of this context, first do the following.
```bash
# this command sets `CLANG_FLAGS` to flags you need to use VeGen
source <path-to-vegen>/extra-clang-flags.sh <path-to-vegen-build>
```
Now you can, e.g., optimize the example file  `vegenbench/cmul-ex.cc` as follows.
```bash
<...>/llvm-build/bin/clang++ $CLANG_FLAGS cmul-ex.cc -S
# cat cmul-ex.s
```

### Generating the Vectorizer
A copy of the generated vector could be found in `vegen/gslp/InstSema.cpp`,
assuming you are in the same directory that you invoked `build-all.sh`.
This part shows how to generate `InstSema.cpp`, which contains
the target-specific components of VeGen.

For all the commands run in this part of evaluation, we assume you are in the directory `vegen/sema`.

VeGen generates `InstSema.cpp` from instruction semantics.
The formal semantics for the subset of x86 vector intrinsics that we can
verify is in `./vegen/sema/intrinsics.all.sema`, which is our ad hoc format.
This is generated from Intel's intrinsic documentation in `data-latest.xml`.
Note that `intrinsics.all.sema` is already included in the repository
and that this step is optional.
To reproduce it, use the following command---make sure Intel SDE is in your `PATH`.
```bash
python3 sema-gen.py data-latest.xml intrinsics.all.sema <num threads>
```
On our 16-core machine, this process takes about 8 minutes.


Now we lift these SMT formulas into a VeGen's
instruction description language,
using the following command (which implicitly uses `intrinsics.all.sema`).
```bash
python3 lift-sema.py
```
This should take about half an hour and produce the file `alu.lifted`.

Now we can generate `InstSema.cpp`, which contains the pattern matching
code and other utility code used by VeGen's target-independent 
vectorizer. Use the following command to generate `InstSema.cpp`.
```bash
python3 gen_rules.py alu.lifted perf.json Skylake
``` 
The last two arguments
tells the generator to specialize the cost model for Skylake 
(`perf.json` doesn't have parameters for other microarchitectures).

Assuming you are in `vegen/sema`, you can (optionally) rebuild 
VeGen's vectorizer with the following commands.
```bash
cp InstSema.cpp ../vegen/gslp/
cd ../../vegen-build
make
cd ../
# And to re-optimize the benchmark using the rebuilt vectorizer
bash <path-to-this-repo>/scripts/build-bench.sh vegen vegenbench
```

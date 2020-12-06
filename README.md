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
CXX=<c++ of your choice> <path-to-this-repo>/scripts/build-all.sh
```
This process includes building the specific version of LLVM that VeGen uses 
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
After this is done, you should find two binaries `vegenbench/bench` and `vegenbench/bench-ref`, both of which takes no argument to execute.
The first one reports the performance of the benchmarks optimized 
by VeGen; the second by Clang/LLVM.

### Generating the Vectorizer
A copy of the generated vector could be found in `vegen/gslp/InstSema.cpp`,
assuming you are in the same directory that you invoked `build-all.sh`.
This part shows how to generate `InstSema.cpp`, which contains
the target-specific components of VeGen.

For all the commands run in this part of evaluation, we assume you are in the directory `vegen/sema`.

VeGen generates `InstSema.cpp` from instruction semantics.
The formal semantics for the subset of x86 vector intrinsics that we can
verify is in `./vegen/sema/intrinsics.all.sema`, which is our ad hoc format,
where the odd rows are intrinsic names and even rows are their semantics
in SMT formula.

First we lift these SMT formulas into a VeGen's
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

# VeGen Artifact Evaluation

## Introduction
This repository contains the scripts and guide for the paper, VeGen: A Vectorizer Generator for SIMD and Beyond.

This guide has two parts -
 - Reproducing the optimization results (Figure 9, 10, 11) and the vector code from the two case studies (Figure 2 and Figure 12).
 - Reproducing the auto-generated vectorizer

Although logically the second part depends on the first part,
we have a copy of the generated vectorizer so they can be done independently.

## Requirements
You would need the following dependencies -
 - make
 - cmake
 - clang (this is not a hard requirement, but we've found that GCC is very slow at compiling our generated vectorizer)
 - git
 - bash
 - Intel [SDE](https://software.intel.com/content/www/us/en/develop/articles/intel-software-development-emulator.html)
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
and takes about half an hour, depending on your machine.
We hardcoded the number of threads that `make` can use to 36 in the scripts.
You can modify this.
After this, you should see the following directories.
 - `llvm-project`
 - `llvm-build`
 - `vegen`
 - `vegen-build`
 - `vegen-bench`
 - `nas-vegen`
 - `nas-clang`

`vegen` is the impelementation of VeGen,
 including its vectorizer generator (`vegen/sema`)
 and its target-independent vectorization heuristic (`vegen/gslp`).
`vegenbench` is our benchmark suite.
`nas-vegen` and `nas-clang` are respectively the version of NAS benchmarks optimized by VeGen and Clang.

### Benchmarking
There are two sets of benchmarks/tests inside `vegenbench`.
 - `synthetic`. These are the synthetic backend codegen test we ported from LLVM's unit test (Figure 9 of the review draft).
 - `dotprod`. These are some integer dot-product kernels we ported from OpenCV (Figure 10 of the review draft).

Each set of benchmarks has its standalone executable optimized by VeGen (e.g., `synthetic`), which takes no argument;
each also has a reference version (i.e., executables postfixed with `-ref`) optimized with standard LLVM `-O3` passes.
Use the following command to get the speedup.
```bash
make report
```

To reproduce Figure 10, execute the programs in `nas-<vegen|clang>/bin/*.A,`, which reports their execution times.
Note that the `is` benchmark reports zero second regardless of which optimizer you use.

### Using VeGen as an optimization pass
There are some boilerplate Clang flags you need to set to use VeGen.
These flags are set automatically by our benchmarking scripts.
If you want to use VeGen outside of this context, first do the following.
```bash
# this command sets `CLANG_FLAGS` to the flags you need to use VeGen
source <path-to-vegen>/flags.sh <path-to-vegen-build>
```
Now you can, e.g., optimize the example file  `vegenbench/ex-cmul.cc` as follows.
```bash
<...>/llvm-build/bin/clang++ $CLANG_FLAGS <some file>.cc -S
```

We included the source code of the two case studies, the TVM dot-product kernel (Figure 2 of the review draft) and 
the scalar complex multiplication kernel (Figure 12 of the review draft) in `vegenbench`.

To reproduce the vectorized TVM kernel, do the following.
```
../llvm-build/bin/clang++ $CLANG_FLAGS ex-tvm.cc -mavx512vnni -mavx512f -S
cat ex-tvm.s
```

To reproduce the vectorized scalar complex multiplication kernel, do the following.
```
../llvm-build/bin/clang++ $CLANG_FLAGS ex-cmul.cc -S
cat ex-cmul.s
```

### Generating the Vectorizer
A copy of the generated, x86-specific vectorizer could be found in `vegen/gslp/InstSema.cpp`.
This part shows how to generate `InstSema.cpp`.

Do the following to generate `InstSema.cpp`. The script implicitly
uses `data-latest.xml`, which Intel uses to render the Intrinsic Guide.
Make sure that [SDE](https://software.intel.com/content/www/us/en/develop/articles/intel-software-development-emulator.html)
is in your `PATH`.
```bash
cd vegen/sema
bash gen-inst-sema.sh
```
This process is not optimized---since it's an offline process that run once per architecture---and slow and should take an hour or more.


Assuming you are in `vegen/sema`, you can (optionally) rebuild 
VeGen's vectorizer with the following commands.
```bash
cp InstSema.cpp ../vegen/gslp/
cd ../../vegen-build
make
cd ../
# And to re-optimize the benchmark using the rebuilt vectorizer
CXX=clang++ bash <path-to-this-repo>/scripts/build-bench.sh vegen vegenbench
```

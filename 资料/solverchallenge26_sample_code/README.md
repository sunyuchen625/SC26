# SolverChallenge26 sample code

This repository contains serial and MPI sample entry points for the
SolverChallenge26 interface. The public executable names remain compatible
with the original samples; all samples use the end-to-end timing interface
documented below.

## Layout

```text
include/solverchallenge26/   public include entry points
src/                         reader, loader, MPI, and diagnostics libraries
problems/problem01..10/      per-problem solver, dependency, and build files
apps/                        serial and MPI application entry points
tests/                       header and integration test sources
cmake/                       CMake dependency modules
```

The public headers use the `solverchallenge26/` prefix and contain the public
types and function declarations. Common library implementations live under
`src/`, application entry points under `apps/`, and solver implementations
under `problems/`. The PETSc binary reader supports the
SolverChallenge26 binary format without requiring the PETSc library.

## Requirements

The build uses a C compiler and CMake 3.21 or newer. MPI targets require
MPICH, and float128 residual checks require GCC `libquadmath`. On the cluster,
load MPI before configuring or building:

```bash
module load mpich
```

## Build

The recommended build uses CMake:

```bash
cmake -S . -B build -DSC26_PROBLEM=01 -DSC26_BUILD_MPI=ON
cmake --build build --parallel
```

The serial-only build does not require MPI:

```bash
cmake -S . -B build-serial -DSC26_PROBLEM=01 -DSC26_BUILD_MPI=OFF
cmake --build build-serial --parallel
```

The root `Makefile` remains as a compatibility wrapper around CMake:

```bash
module load mpich
make SC26_PROBLEM=01
```

MPI GPU support is optional because the default build host may not have CUDA:

```bash
module load mpich
make SC26_PROBLEM=01 SC26_BUILD_MPI_GPU=ON
```

This target builds `MPI_GPU_direct_solver` and `MPI_GPU_iterative_solver`. The
selected problem's `gpu_direct_solver.cu` and `gpu_iterative_solver.cu` are the
adapter boundaries for the external distributed GPU solvers chosen by the
contestant.

Build outputs are written to `build/bin/`.

## Run

The four solver samples use the following interface:

```text
./build/bin/executable_file matrix-file vector-file [read_base] [sys_type]
```

PETSc binary input is the default and always uses zero-based indices. Matrix
Market `.mtx` / `.rhs` input is also supported; `read_base` is used only for
Matrix Market input. Timing is always end-to-end solver time. `sys_type` is
`0` for real and `1` for complex systems;
when omitted, the matrix type is detected where supported.

For PETSc binary input, each MPI process reads its local row partition. For
Matrix Market input, rank 0 reads the complete system and scatters the local
parts. After the solve, the local solution pieces are gathered to rank 0.
Rank 0 re-reads the complete matrix and right-hand side before running double,
long double, and float128 residual checks.

```bash
./build/bin/direct_solver data/matrix.dat data/vector.dat 0 0
./build/bin/iterative_solver data/matrix.dat data/vector.dat 0 0
mpirun -np 2 ./build/bin/MPI_direct_solver data/matrix.dat data/vector.dat 0 0
mpirun -np 2 ./build/bin/MPI_iterative_solver data/matrix.dat data/vector.dat 0 0
mpirun -np 2 ./build/bin/MPI_GPU_direct_solver data/matrix.dat data/vector.dat 0 0
mpirun -np 2 ./build/bin/MPI_GPU_iterative_solver data/matrix.dat data/vector.dat 0 0
```

The CPU drivers and T2 HYPRE driver execute five full warmups and five full
timed runs. MPI takes the maximum elapsed time across ranks for the entire
timed interval. `CHECK formal total time` is in seconds and
`CHECK end to end time` is the mean of the five formal runs in milliseconds.
Memory and residual checks run once after the measured stage. The selected
`problems/problemXX/solver.c` is the customization point
for a submitted solver implementation, and `solver.h` contains its interface.
Only the selected problem slot is compiled. Solver callbacks receive a
`const struct SC26_SolverInput*` containing the matrix, right-hand side,
solution vectors, global and local sizes, row offset, and MPI communicator.

The MPI GPU direct and iterative harnesses follow the same data contract:
every rank retains only its local CSR rows and RHS, the selected GPU adapter
uses the supplied communicator for distributed solving, and the local solution
is copied back to host memory before gathering to rank 0. CPU-to-GPU and
GPU-to-CPU solution transfer times are reported separately and excluded from
end-to-end time. Rank 0 then reloads the complete system for residual checking.
The GPU entries also report `GPU memory usage` and `GPU observed memory delta`
using the shared `gpu_metrics.h` semantics. GPU execution is not claimed to be
tested on hosts without a CUDA environment.

The GPU timing output contains separate CPU-to-GPU transfer, GPU-to-CPU
solution transfer, and end-to-end lines. The end-to-end value uses MPI wall
time to include distributed solver communication, while both transfer calls
are excluded. GPU adapters must complete asynchronous transfers before
returning from `upload` or `copy_solution`.

Select a problem with CMake:

```bash
module load mpich
cmake -S . -B build -DSC26_PROBLEM=01
cmake --build build --parallel
```

The same selection is available through the compatibility wrapper:

```bash
make SC26_PROBLEM=01
```

Valid values are `01` through `10`; every build must select one of these ten
problem slots. `SC26_PROBLEM` selects the solver implementation only; matrix
and right-hand-side paths are supplied separately on the command line.

## Tests

Run the header dependency checks with:

```bash
ctest --test-dir build --output-on-failure
```

To enable the optional MPI matrix smoke test, provide generic paths at
configuration time:

```bash
cmake -S . -B build \
  -DSC26_PROBLEM=01 \
  -DSC26_TEST_MATRIX=/path/to/matrix.dat \
  -DSC26_TEST_RHS=/path/to/vector.dat
ctest --test-dir build --output-on-failure
```

No cluster-specific test path is embedded in the source or documentation.

## Adding an external library

Add the dependency only to the selected problem's
`problems/problemXX/CMakeLists.txt`. The file already defines the
`sc26_problem_dependencies` interface target, which is linked to that
problem's serial and MPI solver targets:

```cmake
find_package(SomeSolver CONFIG REQUIRED)
target_link_libraries(sc26_problem_dependencies
    INTERFACE SomeSolver::SomeSolver
)
```

Add library-specific includes or compile definitions to the same target when
needed. Do not append library paths or flags to global `CFLAGS` or `LDFLAGS`.
MPI and quadmath remain configured by the common build through `MPI::MPI_C`
and target-level `quadmath` linkage.

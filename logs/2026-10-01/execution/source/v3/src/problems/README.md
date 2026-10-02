# Problem slots

The competition template provides ten independent solver modification slots:
`problem01` through `problem10`. Put the interface declarations in that
directory's `solver.h` and the implementation in `solver.c`; the shared
readers, MPI distribution, timing, memory reporting, and residual checks are
reused from `src/`.

Choose the slot at configure time with `-DSC26_PROBLEM=01` through
`-DSC26_PROBLEM=10`. The selected slot is added to the include path and its
`solver.c` is compiled with the existing solver entry points. Other problem
implementations are not compiled.

Each problem also has a `CMakeLists.txt` containing the
`sc26_problem_dependencies` interface target. Add `find_package`, include
directories, compile definitions, and link libraries for that problem there;
the common build automatically propagates them to its serial and MPI solver
targets.

When MPI GPU support is enabled, the selected problem's `gpu_direct_solver.cu`
and `gpu_iterative_solver.cu` are compiled as the direct and iterative GPU
adapters. Each adapter receives the local CSR view and `MPI_Comm` through
`SC26_SolverInput`. Implement host-to-device copies in the adapter's `upload`
function and device-to-host solution copies in `copy_solution`; both transfer
times are reported separately from the end-to-end solve time.
Use the shared `gpu_memory_sample` helper after allocation-heavy stages so the
reported tracked peak and observed memory delta retain the reference semantics.
The direct adapter is intended for factorization/direct-solve libraries,
whereas the iterative adapter owns iteration, convergence, and any required
distributed reductions.
Keep external GPU library discovery and linking in the same problem's
`CMakeLists.txt`.

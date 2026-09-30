# SolverChallenge26 Project Brief

Status date: 30 September 2026, Asia/Shanghai.

CUDA OOM! is an Ocean University of China team participating in SolverChallenge26, the sixth linear solver algorithm and performance optimization competition. The project implements and benchmarks solvers for ten large sparse linear systems from engineering applications. Its immediate objective is to establish valid solutions across the problems, then optimize measured performance and prepare reproducible competition submissions.

The current commercial CPU implementation has passing full scale results for T2 at its lower accuracy tier, T5, T6, T7, and all ten right hand sides of each of T8, T9, and T10. T1, T3, T4, and the higher accuracy tier of T2 remain unresolved. These are original system residual checks in the supplied framework; a successful local run does not yet establish an accepted formal submission or a competitive score.

## Team and schedule

The team consists of Sun Yuchen, captain; Zhou Junzhe, also known as Justin; and Su Chengqi. The advisers are Zhang Linjie and Fu Kai. Registration and initial compute resource registration are complete. Another OUC team, led by Sun Jingyu, is separate from CUDA OOM!.

The schedule recorded in the project materials opens program submission on 30 September 2026 and closes it on 30 October. The saved official page does not specify the exact submission closing time; 24:00 belongs to the registration deadline. The recorded shortlist date is 10 November, with presentations and awards in Shenzhen on 20–23 November. The internal targets are a main deliverable by 25 October and submission verification by 29 October. The local project does not yet contain evidence of a formal submission or official scoring. These dates come from the previously saved competition materials; this brief does not establish a fresh portal check.

## Compute environment and access

All full scale numerical work has used the commercial CPU platform at Yancheng Supercomputing. The recorded competition node specification is Intel Xeon Platinum 8488C, 96 cores, and 512 GB DDR5. The verified Slurm partition is `qhn`, account `sunyc`, with work under `/data/home/sunyc/solverchallenge26`. The account association permits up to four nodes across the user's projects; each competition experiment uses one node. The allowance and account expiry remain unconfirmed.

The validated software environment is GCC 11.3.0, OpenMPI 4.1.8, CMake 3.24.2, HYPRE 2.33.0, and oneMKL 2022.0.0. MPI iterative experiments generally use 96 ranks with one thread each; T2 uses 32 ranks and the failed T1 trial used 8 ranks to meet its memory budget. Direct solver experiments use one MPI rank and 96 OpenMP threads. The full input directory is `/data/home/maorz/SolverChallenge26-TenProblems`. Large solution files remain on that platform; local files retain logs, summaries, source snapshots, and small known solution outputs.

The domestic CPU platform uses Huawei Uniportal and jumper. The actual registered account is `travissun`, in lowercase. Three individual confidentiality undertakings and the application were successfully submitted on 25 September at 14:42. The last recorded jumper check returned 401 for missing authorization. There is no subsequent local authorization or host access record. A follow up email draft is awaiting the user's review.

For the domestic GPU platform, SCNet account `TravisSun` has been registered and entered in the resource form. The last local check found no accessible competition region. The saved platform specification is 32 CPU cores, 128 GB host memory, and two BW1000 DCUs. The manual records DTK/HIP and architecture `gfx936`. GPU porting and a usable allocated region have not been established by an experiment.

On 30 September, Codex connected to the existing commercial CPU account, retrieved the remaining completed T10 logs, and verified the final job records. The three remaining groups ended successfully on 26 September: jobs 9193327, 9193324, and 9193325. The account queue was empty at the 30 September check.

## Local code and evidence

The framework is under `资料/solverchallenge26_sample_code/`, based on upstream commit `b66421483501021dd84aa10fc494f1dbf8e65958`, with its MIT license retained. The project records implementation commit `3970942`; the latest local committed checkpoint before the 30 September documentation and archive updates is `55969ef`. The current working tree includes the newer results and document organization.

The principal files are:

- `problems/problem02/solver.c`: the T2 HYPRE solver.
- `problems/cpu_baseline/solver.c`: shared CPU implementations for T1 and T3–T10, selected through `SC26_PROBLEM`.
- `problems/cpu_baseline/CMakeLists.txt`: HYPRE and MKL dependencies, problem selection, and the T5/T7 pressure MGR build option.
- `apps/MPI_iterative_solver.c` and `apps/MPI_direct_solver.c`: framework callbacks, repeated timing, and final checks.
- `src/diagnostics.c` and `src/mpi_system_loader.c`: residual checks, input, distribution, and original system handling.
- `scripts/`: Slurm build, diagnostic, small system, and full scale experiment scripts.
- `tests/`: known solution generators, the MPI smoke test, and `check_result.py`.
- `docs/baselines/`: the four numerical reports covering all ten problems.
- `logs/`: dated original solver output, process memory records, Slurm output, input diagnostics, summaries, and source snapshots.

Current plans and compute status are in `docs/`. Historical resource checks are in `docs/archive/`; review records are in `docs/reviews/`. Platform manuals and application documents are under `资料/`. The expanded HYPRE source and its release archive are present in `资料/dependencies/` as local build and reference material.

The 23 September Grok review covered the earlier implementation and reproduction instructions. Its scope precedes the T5/T7/T8/T10 extension; it is not evidence that the current complete implementation has already passed an independent audit.

## Problem characteristics and acceptance

The residual below is computed using the original matrix and right hand side. Relative acceptance means `norm(b - A*x, 2) / norm(b, 2)`. T8 instead uses the maximum absolute component of `b - A*x`.

| Problem | Application | Matrix order | Nonzeros | Values | Required residual |
| --- | --- | ---: | ---: | --- | --- |
| T1 | Three temperature fusion energy equations | 6,291,456 | 52,133,888 | Real | Relative <1e-4 and <1e-8, separately scored |
| T2 | Combustor pressure equation | 19,637,808 | 97,535,322 | Real | Relative <1e-6 and <1e-10, separately scored |
| T3 | Contact elasticity with constraints | 2,081,541 | 71,033,481 | Real | Relative <1e-8 |
| T4 | Large three dimensional elasticity | 12,582,822 | 678,943,908 | Real | Relative <1e-8 |
| T5 | Incompressible velocity and pressure coupling | 31,214,240 | 1,786,704,832 | Real | Relative <1e-8 |
| T6 | Time harmonic Maxwell equations | 1,765,074 | 28,533,594 | Complex | Relative <1e-8 |
| T7 | Multicomponent flow for carbon storage | 34,500,003 | 721,719,027 | Real | Relative <1e-6 |
| T8 | Integrated circuit harmonic balance, 15 by 15 blocks | 5,809,680 | 194,348,610 | Complex | Maximum absolute <1e-8 |
| T9 | SRAM transient simulation | 9,683,038 | 75,425,210 | Real | Relative <1e-8 |
| T10 | RF VCO harmonic balance | 418,718 | 921,708,586 | Complex | Relative <1e-8 |

T1 has a CPU memory limit of at most 9 GB and a separate GPU memory limit of at most 9 GB. T9 has strict limits below 100 GB for each. Node capacity does not override these problem limits. T8, T9, and T10 each have ten right hand sides. Recorded zero initial guess requirements apply to T4, T6, and T7; the tested implementations start from zero.

## Verified numerical status

Times below are framework means over five complete solver callbacks, for each right hand side. Every repetition rebuilds the preconditioner or repeats direct analysis, factorization, solve, and cleanup. These are measured baselines, not official leaderboard scores. A range across right hand sides from different experiment groups is not a consolidated single node timing for the whole problem.

| Problem | Tested method | Original float128 residual | Mean seconds | Status |
| --- | --- | ---: | ---: | --- |
| T1 | Equilibrated GMRES(30) and AMG | Relative 1.104663e3 | 96.003442 | Lower tier failed; upper tier not run |
| T2 lower tier | GMRES(50), BoomerAMG, constant component projection internally | Relative 5.894250e-7 | 20.884207 | Passed |
| T2 upper tier | Same method at tighter internal tolerance | Relative 5.867434e-7 | 21.926099 | Failed |
| T3 | PARDISO with extended precision residual refinement | Relative 2.744395e-5 | 44.038319 | Failed |
| T4 | Equilibrated GMRES(50) and AMG | Relative 0.1150246 | 159.440061 | Failed |
| T5 | Equilibrated GMRES(50) and pressure MGR | Relative 9.732279e-9 | 167.237252 | Passed with a small margin |
| T6 | Complex PARDISO | Relative 1.801880e-12 | 35.216142 | Passed |
| T7 | Equilibrated GMRES(50) and local ILU(0) | Relative 1.777361e-9 | 6.190578 | Passed |
| T8, all ten RHS | Complex PARDISO | Worst maximum absolute 3.657010e-16 | 75.239949–76.551812 per RHS | All passed |
| T9, all ten RHS | Real PARDISO | Worst relative 1.045516e-15 | 73.410935–75.026316 per RHS | All passed, memory <100 GB |
| T10, all ten RHS | Complex 64 bit PARDISO with sorted internal CSR | Worst relative 7.406004e-15 | 196.740315–200.674681 per RHS | All passed |

T7 pressure MGR also passed with relative residual 4.092948e-10 and mean 6.731982 seconds. It reduced iterations from 42 to 11, but the measured total time was longer than ILU(0). T5 ILU(0) failed with relative residual 2.642542e-3.

T5 pressure MGR reaches the 300 iteration limit in all five runs. Its internal scaled residual is about 1.83e-8, while the original system check is strictly below 1e-8. The approximately 2.7% acceptance margin makes improved convergence and independent reproduction a priority.

T8 peak process RSS is 44.879 GiB. T9's largest recorded peak is 38.015 GB in decimal units. T10's peak is 134,051,045,376 bytes, approximately 124.845 GiB. T5 MGR's sum of process peaks is 202,886,234,112 bytes. MPI peak sums are conservative sums of each rank's full process maximum, which need not occur simultaneously.

The 30 September verification checked all twenty T8 and T10 RHS records: exactly five completed solves, correct original residual metric below its threshold, successful process exit, and zero perturbed pivots in all repetitions. The evidence is `logs/2026-09-26/stage2/all-rhs-validation_2026-09-30.log`. The full updated stage summary is `logs/2026-09-26/stage2/summary.json`.

## Numerical boundaries and current bottlenecks

T2 has a numerical near constant nullspace. A full row scan found `norm(A*1, 2)` and `norm(transpose(A)*1, 2)` near 6.94e-19. The original RHS constant component is about 5.867434e-7 relative to its norm. The projected system can reach its tight target while the original system stays near that value. This is evidence to investigate compatibility and the evaluation convention; it is not proof that the stored double precision matrix makes the upper tier mathematically impossible.

T1 has three contiguous temperature blocks of 2,097,152 unknowns, substantial coefficient scaling, and a strict memory budget. The generic AMG trial failed despite a full process peak sum below 9 GB. T3 is sensitive to large constraint coefficients; direct refinement improved its residual without reaching the threshold. T4 has a larger elasticity structure and several highly connected rows; its generic AMG configuration failed. These unresolved problems require targeted numerical experiments, not simply assuming that a tighter internal tolerance will pass.

T10 uses `pardiso_64`, 64 bit CSR indices and parameters, and explicit initialization. An actual input issue was identified: the final row's column indices were unsorted. The adapter sorts columns and their complex coefficients together in an internal copy, retaining the original input for final residual checks. Ordered and unsorted complex known solution cases passed after this correction. The unsuccessful diagnostic runs remain part of the local evidence.

Symbolic analysis and PARDISO preprocessing dominate the direct baselines: for T10 rhs01, the stage means were about 182.917 seconds in analysis, 11.014 in factorization, and 4.550 in solve and cleanup. Matching and scaling in the library analysis path use matrix values, so stage labels alone should not be interpreted as purely structural work. Reuse across RHS and repetitions needs evaluation against the recorded competition timing rules before it can be claimed as a valid scoring improvement.

## Validation and reproduction limits

The original framework performs final residual checks with float128 accumulation using the in memory double precision solution and the original inputs. Internal scaled or projected residuals are reported separately. The text solution file keeps six decimal places and cannot replace the in memory accuracy check.

Input and output, final validation, and some framework operations are outside the callback timing interval. GNU time records cover the complete process, including the final full input reread on rank zero. Official timing eligibility and problem wide multi RHS accounting still need formal submission verification.

Evidence includes an MPI/data smoke test, six initial T2 known solution runs, eighteen T1/T3/T6 extension cases, nine T4/T9 extension cases, fourteen initial T5/T7/T8/T10 cases, eight coupled pressure cases, and ordered/unsorted T10 regression checks. Each numerical case checks its five repetitions and a known solution where applicable. The framework's two CTest tests are header include order checks, not numerical solver tests.

The deployment and module instructions are in the README and baseline reports. One recorded environment issue is that `intel/2022.1` injects Intel MPI headers through `CPATH`, conflicting with OpenMPI. The validated builds purge modules, load GCC/OpenMPI/CMake explicitly, and set `MKLROOT` separately.

Independent teammate reproduction is still a planned deliverable. Domestic platform access and HIP implementation have not been validated. The project has numerical experiment reports and scripts; a final competition technical report and accepted submission are not yet evidenced locally.

## Immediate priorities

1. Resolve the formal submission path, entrypoints, dependencies, accuracy tier selection, structure-only analysis restriction, and multi RHS timing and reuse convention.
2. Improve T5's convergence margin and reproduce the passing configurations independently.
3. Run targeted investigations for T1's temperature blocks, T3/T4 constraints and elasticity, and T2 upper tier compatibility.
4. Optimize direct preprocessing and multi RHS work only through measured comparisons under the applicable timing rules.
5. Confirm CPU allowance and expiry and follow up on domestic resource allocation, then assess the value of platform porting against the remaining deadline.

The primary status and follow up plan is [项目背景与下一步工作方案](项目背景与下一步工作方案.md). Detailed numerical evidence is in [T2](baselines/T2数值基线_2026-09-22.md), [T1/T3/T6](baselines/初步阶段扩展基线_2026-09-23.md), [T4/T9](baselines/T4_T9数值基线_2026-09-23.md), and [T5/T7/T8/T10](baselines/T5_T7_T8_T10数值基线_2026-09-26.md).

The current independent review is [Claude Sonnet 5.5 max project audit](reviews/CLAUDE_AUDIT_2026-09-30.md), with locally verified findings and prioritized follow-up work.

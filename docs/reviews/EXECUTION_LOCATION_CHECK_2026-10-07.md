# Execution-location check

Date: 7 October 2026, Asia/Shanghai. Reviewer: Codex. Scope: the approved October next-phase jobs, their saved batch sources and supplied scheduler records.

**No login-node compilation or numerical execution was found in the reviewed records.** Compute commands occur inside Slurm batch bodies. The E-Shell commands supplied to the user submit those bodies with quoted heredocs; the login shell does not execute their contents.

| Job | Assigned compute node | Reviewed work |
| --- | --- | --- |
| 9213575 | `c3n182` | Frozen CPU launch comparisons |
| 9213576 | `c3n10` | Diagnostic compilation and T1 solves |
| 9213582 | `c3n200` | CPU comparison attempt, failed |
| 9213608 | `c3n39` | Completed CPU comparisons |
| 883172 | `f11r1n20` | Allocated DCU inventory |
| 887201 | `f11r3n11` | HIP/MPI compilation and successful HIP kernel; MPI launch failed |
| 887220 | `f11r3n11` | MPI-only follow-up, `FAILED 1:0`, one second; stopped at `mpirun --version` before the MPI program |
| 890436 | `f11r1n19` | Passed allocation/host check; launcher rejected `-np` before the child or MPI program |
| 890784 | `f11r2n02` | Passed allocation/host check; program reached `MPI_Init`, then failed at shared-memory component selection |
| 890896 | `f11r1n20` | Component inventory and prefix hypothesis test; initialization still failed |
| 890942 | `f11r1n19` | Successful MPI initialization/finalization after correcting the component search path |

CPU evidence includes `BatchHost`, node allocation and launch records in the [saved batch logs](../../logs/2026-10-03/next-phase/batch/) and [accounting](../../logs/2026-10-03/next-phase/jobs-accounting-20261004.log). GPU evidence is the [G0 output](../../logs/2026-10-04/gpu/g0-883172-user-output.log), [887201 output](../../logs/2026-10-05/gpu/hip-probe-887201-user-output.log), its matching submitted-script hash and the [887220 accounting record](../../logs/2026-10-05/gpu/mpi-probe-887220-status.json). The latter supplies a compute-node assignment, but does not identify which command failed or prove MPI execution.

## Execution boundary

Seven active entry points now require a nonempty Slurm job ID and daemon node name, and require the short host name to match that daemon node. Otherwise they exit before module loading, compilation or execution. The entry points are the three SCNet scripts, remediation build/baseline, CPU launch comparison and T1 diagnostic.

All seven scripts pass Bash syntax checking. Fourteen direct-invocation checks—missing allocation and mismatched host for each script—exit with code 2 before workload commands. The [check record](../../logs/2026-10-07/execution-location/guard-checks.json) distinguishes these local shell-boundary checks from allocated compute runs. The submitted 887201 and 887220 sources are retained as historical evidence.

Login-node activity is limited to submitting/querying jobs and reading or transferring files. Compiler invocations, solver execution, HIP/MPI programs and numerical validation execute inside the assigned compute allocation. Every new task requires the allocation and execution-node check before starting its workload.

## Current GPU result

The small double-precision HIP kernel passed in 887201. The component diagnostic identified an environment search path that omitted existing OpenMPI plugins. Corrected job 890942 initialized and finalized MPI successfully on `f11r1n19`, with rank 0 and size 1. The seven new GPU allocations report ten whole seconds in total. Source preparation and the subsequent HYPRE build retain the allocated-node execution check; full-scale solver acceptance remains a separate step.

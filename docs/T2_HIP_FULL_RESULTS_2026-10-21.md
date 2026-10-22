# T2-low HIP full-data result

Date: 21 October 2026, Asia/Shanghai. **S3 numerical acceptance: PASS. CPU retention is provisional against the experimental reference pending the actual contract.**

Job **953826** completed `0:0` on `f11r3n09`, from **18:20:49 to 18:22:45**, with **116 allocated seconds**, one MPI process, one Hygon DCU, 16 CPUs and 58 GiB. Submission was at 18:20:14. The solver used one OpenMP thread. The [raw accounting](../logs/2026-10-21/plan-execution/t2-full-953826-accounting.log) and [batch output](../logs/2026-10-21/plan-execution/sc26_t2_hip_full-953826.out) identify the allocation and runtime checks.

## Full original problem

The input has **19,637,808 rows and 97,535,322 nonzeros**. The original matrix and RHS hashes match the [accepted CPU input record](../logs/2026-10-03/next-phase/batch/sc26_launch_compare-9213608.out#L1062-L1063); their PETSc headers and sizes are recorded in the batch output. This is the original T2-low problem, with default projection and internal tolerance `1e-7`.

| Gate | Observed result |
| --- | --- |
| Complete solves | Five; 13 GMRES iterations each; all five internal relative residuals below `1e-7` |
| Original-system in-memory float128 relative residual | **5.938952e-7**, below `1e-6` |
| Projection / device policy / phase records | Five each; `memory_device=1 execution_device=1` |
| Full-process host peak RSS | **5,651,876 KiB**, within the 58 GiB allocation |
| GPU observations | Five samples per ANALYSE / SETUP / SOLVE stage; maximum observed used VRAM **21.90 GiB**, reported capacity **63.98 GiB** |
| Process / checker / scheduler | Zero exits; completion markers present; runtime and batch stderr empty |

The [verification record](../logs/2026-10-21/plan-execution/t2-hip-full-verification.json) binds these gates to the [full solver log](../logs/2026-10-21/plan-execution/t2-full-953826/solver.log), [GNU time record](../logs/2026-10-21/plan-execution/t2-full-953826/process.time), actual source checks and input identities. GPU observations are rounded phase samples. They do not measure a continuous peak. The separate runtime banner's `0.00 GiB` field is not the capacity measurement.

## Source and allocated-device checks

The run reused the accepted S1 executable, without rebuilding. The [submitted batch](../logs/2026-10-21/plan-execution/t2-full-953826/submitted.sbatch) is byte-identical to the current [full-data entry point](../scripts/scnet-t2-hip-full.sbatch), SHA256 `3f28ebcddad50856031878bf7a81f7f06bcb1b15a255b71c7b90d6b331646261`.

All 89 source entries match the [identified HIP source snapshot](T2_HIP_RESULTS_2026-10-09.md). Source manifest `7a5f354a…`, cache `5e0d630e…`, binary `7f02c33a…`, installed HYPRE `e3887d90…` and parent `d1c5bd1…` retain their accepted identities. The batch checked the binary against the submitted S1 fingerprint, checked the pinned library/cache/manifest and verified the original input hashes. The complete fingerprints and checks are in the verification record and raw output.

The allocated device reports **gfx936**, with one visible device. The installed HYPRE has HIP/GPU enabled and unified memory disabled. The unchanged application/library migration and dispatch path, five full-data device-policy records and phase observations provide source/runtime-backed device evidence.

Before the full problem, the same executable passed the three known systems on the newly allocated device:

| Case | Solves | Original float128 relative residual | Known-solution maximum error |
| --- | ---: | ---: | ---: |
| Poisson | 5 | 5.279773e-12 | 0 |
| Nonsymmetric | 5 | 3.654671e-13 | 0 |
| Neumann | 5 | 6.013807e-13 | 8.673617e-17 |

Each case has five device-policy and complete-phase records, internal tolerance `1e-11`, successful checks and zero process exits. Projection is off for the two unique systems and on for Neumann. The [per-case raw records](../logs/2026-10-21/plan-execution/t2-full-953826/device-small/) retain the logs, times and exits. Earlier accepted S1 and S2 results retain their own scope.

## Timing and performance choice

| Round | Analyse (s) | Prepare (s) | Solve and cleanup (s) | Complete callback sum (s) |
| --- | ---: | ---: | ---: | ---: |
| 1 | 0.120556 | 5.891597 | 6.955464 | 12.967617 |
| 2 | 0.045320 | 5.466655 | 7.031529 | 12.543504 |
| 3 | 0.045372 | 5.871026 | 6.945786 | 12.862184 |
| 4 | 0.045468 | 5.881562 | 6.935390 | 12.862420 |
| 5 | 0.046484 | 5.875692 | 6.948181 | 12.870357 |

The driver's outer five-round mean is **12.833244 s**. Each row sums the three completed callbacks; vector reset and outer MPI barriers also enter the driver mean. These are prototype-inclusive measurements after the device known-system checks. Migration and diagnostics remain within the prototype callbacks. The formal GPU transfer-excluded interface/timing contract is unresolved.

The fastest measured experimental CPU reference is **7.036402 s**, using 96 ranks in job `9213608`, with the [accepted launch evidence](NEXT_PHASE_RESULTS_2026-10-04.md). The GPU prototype mean is **82.38% slower** than that reference. CPU retention is provisional against this experimental setting. The same CPU job measured **24.355135 s at 16 ranks, 20.266965 s at 32 ranks and 12.692410 s at 64 ranks**. The GPU prototype beats the 16- and 32-rank means by more than the 10% target, while trailing the 64-rank mean. If the actual contract permits only 32 ranks or fewer, reopen S4 selection at the 24 October eligibility gate together with formal GPU entry, platform eligibility and transfer-excluded timing. The approved small-advantage repeat condition is not triggered by these comparisons. The final choice requires the fastest CPU setting permitted by the actual contract.

## Evidence and accounting

The downloaded [evidence archive](../logs/2026-10-21/plan-execution/t2-full-953826-evidence-20261021.tar.gz) matches its [remote checksum](../logs/2026-10-21/plan-execution/t2-full-953826-evidence-20261021.sha256): `ebe71f01bf2b0b3f2f3faf2a1b48d899059c42d10ad3e9285a83163a1322d217`. Original data and answer files remain on SCNet.

The later `scontrol` export is empty after the controller stopped retaining the completed job. The in-allocation job record is preserved in batch stdout, and the accounting record supplies the completed state, exits, resources and timestamps.

The [allocation ledger](../logs/2026-10-21/plan-execution/gpu-allocation-ledger.json) now records **15 completed GPU allocations and 1160 allocated seconds**, including failed allocations from earlier work. This phase adds 116 seconds and performs no new compilation. Commercial CPU use remains 12.3136 node-hours; no new CPU or LX2 allocation was made in this phase.

CPU delivery preparation and the frozen report retain their accepted identities. Genuine teammate reproduction, the actual submission/launcher contract and LX2 readiness remain governed by the [approved calendar and acceptance plan](NEXT_PLAN_ACCEPTANCE_2026-10-21.md).

# SolverChallenge26 next-phase results

Evidence dates: 3–14 October 2026, Asia/Shanghai. Scope: the [approved next sequence](reviews/STATUS_REVIEW_2026-10-02.md), following delivered commit `6b7f675ecaa6949815a3a77f95467fc35f8d5bbf`. Current audit and approved execution gates are in the [9 October plan](NEXT_PLAN_ACCEPTANCE_2026-10-09.md).

The frozen-method CPU launch campaign is complete. All fourteen configurations from its two completed allocations pass the existing numerical/execution/provenance verifier. Current paired measurements exceed the 10% time-reduction target for T2-low, T7 and T6. The T1 diagnostic completed below 9 GB; its proposed 90%/10% metric trigger was not met. A source candidate and teammate reproduction guide are prepared. Formal launch/package conditions and independent teammate evidence remain open. The [completed native Claude Opus 5.5/max audit](reviews/CLAUDE_NEXT_PHASE_AUDIT_2026-10-04.md) gives PASS for this bounded phase.

The [T2 execution record, updated 14 October](T2_HIP_RESULTS_2026-10-09.md), records S1 passing all three HIP known systems and S2 passing all six freshly built CPU cases from the same source snapshot. HIP job 897432 completed `0:0` in 20 seconds. The full-data request was rejected before allocation for the current account/partition combination; full T2 accuracy and performance remain open.

## Paired CPU launch measurements

Both completed jobs used one Intel Xeon Platinum 8488C node with 96 CPUs, 450 GiB requested memory and the frozen v19 binaries. Each configuration ran five complete solver callbacks, followed by the original in-memory float128 check. Iterative runs used one thread per rank and explicit core mapping/binding. T6 used one MPI rank, no rank binding, and the recorded OpenMP/MKL thread count. The same policy applies to all configurations within each comparison.

The first allocation, job 9213575 on c3n182, established the trend:

| Problem | MPI ranks | Framework mean | Original relative residual | Sum of process peaks |
| --- | ---: | ---: | ---: | ---: |
| T7 | 16 | 17.002697 s | 1.601450e-9 | 67.252 GB |
| T7 | 96 | 6.032227 s | 1.777361e-9 | 94.062 GB |
| T2-low | 16 | 24.116106 s | 5.885605e-7 | 15.638 GB |
| T2-low | 32 | 20.019956 s | 5.894250e-7 | 16.765 GB |

This supported the additional counts within the remaining budget. The extended allocation, job 9213608 on c3n39, completed all ten configurations:

| Problem | MPI ranks | Threads per rank | Framework mean | Original relative residual | Sum of process peaks |
| --- | ---: | ---: | ---: | ---: | ---: |
| T7 | 16 | 1 | 17.204675 s | 1.601450e-9 | 67.255 GB |
| T7 | 64 | 1 | 9.706044 s | 1.798360e-9 | 84.765 GB |
| T7 | 96 | 1 | 5.869507 s | 1.777361e-9 | 94.064 GB |
| T2-low | 16 | 1 | 24.355135 s | 5.885605e-7 | 15.549 GB |
| T2-low | 32 | 1 | 20.266965 s | 5.894250e-7 | 16.773 GB |
| T2-low | 64 | 1 | 12.692410 s | 5.896190e-7 | 18.906 GB |
| T2-low | 96 | 1 | 7.036402 s | 5.875263e-7 | 20.385 GB |
| T6 | 1 | 32 | 46.049212 s | 1.795509e-12 | 37.414 GB |
| T6 | 1 | 64 | 37.476449 s | 1.795509e-12 | 38.914 GB |
| T6 | 1 | 96 | 35.427933 s | 1.828909e-12 | 40.450 GB |

Against the smaller-count control in this same allocation, the fastest settings reduce measured time by **65.88% for T7**, **71.11% for T2-low** and **23.07% for T6**. These support exploratory 96-rank T2/T7 and 96-thread T6 configurations. The actual organizer launch contract governs their official adoption. The teammate guide retains the delivered configurations; T5's validated method, defaults and margin are preserved.

All fourteen records have five complete phase records, one original-system residual check, zero process exits, Slurm `COMPLETED 0:0`, complete-process GNU time peaks and verified frozen source/cache/binary identity. Each allocation also records the exact comparison-script hash. MPI process peaks are summed conservatively and need not coincide. Evidence: [run manifest](../logs/2026-10-03/next-phase/launch-runs.json), [complete verification](../logs/2026-10-03/next-phase/launch-verification.json), [batch logs](../logs/2026-10-03/next-phase/batch/) and [script versions](../logs/2026-10-03/next-phase/source/).

An intervening extended allocation, job 9213582 on c3n200, ended `FAILED 1:0` during the 64-rank launch. Its logs record MPI runtime errors and GNU time execution failing with “Cannot send after transport endpoint shutdown”. Its first 16-rank run reached numerical acceptance, but the allocation fails the normal execution acceptance. The unchanged script/configurations were resubmitted with a one-time exclusion of that node; job 9213608 completed. The failed allocation and elapsed time are retained in the evidence and budget.

The campaign used **2,826 allocated seconds = 0.785 single-node hours**, including the failed allocation, below its three-hour cap. No further performance jobs are scheduled for this campaign.

## T1 residual-metric diagnostic

Job 9213576 completed `0:0` on c3n10 with eight MPI ranks and one thread per rank, in one 81-second allocation. It uses the frozen shared T1 implementation: GMRES/BoomerAMG, source-default tolerance `1e-11` and 300-iteration cap. The diagnostic executes one solve, then computes original r=b−Ax and Dr with Dᵢᵢ=1/√maxⱼ|aᵢⱼ|. Matrix products use float128; group sums and MPI reductions use long double. Original matrix/RHS arrays are retained for statistics, then the existing SDK independently reloads and checks the original full system.

An existing known field system checks the diagnostic's original relative norm against the SDK float128 result. The full run matches the SDK's printed residual and covers all 6,291,456 rows. It reports joint bins by the three contiguous temperature blocks and floor(log10(row maximum)).

| Metric | Measured value |
| --- | ---: |
| ‖r‖₂ | 1.059666447920458e5 |
| ‖Dr‖₂ | 7.077642066561719e-1 |
| ‖b‖₂ | 9.592666601410783e1 |
| ‖Db‖₂ | 3.297168480066314 |
| Original relative residual | 1.104663063933249e3 |
| Scaled relative residual | 2.146581865425139e-1 |
| Conservative GNU time process-peak sum | 5,677,342,720 bytes |
| Framework process-peak sum | approximately 5,677,342,681 bytes |

Both memory measures satisfy 9,000,000,000 bytes. The dominant joint bin, temperature block 1 with row-maximum decade 10, contains **98.79896% of original squared-residual energy** and **58.86981% of scaled squared-residual energy**. It exceeds the original 90% threshold but exceeds the scaled 10% threshold as well. The predeclared trigger is therefore not met; this proposed metric branch closes for the present round. The observations do not identify a sole cause or establish that T1 is unsolvable. The original residual remains far above its lower-tier requirement; diagnostic completion is separate from normal five-solve numerical acceptance.

Evidence: [full diagnostic log](../logs/2026-10-03/next-phase/runs/t01-9213576/full/solver.log), [bin summary](../logs/2026-10-03/next-phase/runs/t01-9213576/full/bin-summary.json), [build/job output](../logs/2026-10-03/next-phase/batch/sc26_t1_diagnostic-9213576.out) and [exact diagnostic source](../logs/2026-10-03/next-phase/source/t1-residual-diagnostic.c).

## Submission candidate and independent reproduction

The [candidate](../deliverables/SC26_CPU_candidate_6b7f675.tar.gz) contains the delivered source, build/run scripts, tests, technical report, source identity/checklist, acceptance summaries and reproduction instructions. All 118 src/scripts/tests entries match the accepted frozen v19 manifest. The report is copied byte-for-byte from the delivered commit. The [final archive check](../logs/2026-10-03/next-phase/candidate-package-check-20261004.json) verifies those entries, the report and the T9 guide's 16-thread setting inside the package. Archive SHA256: `dae96e3fa5c8dc4cf8d66469b34797a84a0f3d741d0f8f4d8b4884f16206a111`.

The [submission question sheet](SUBMISSION_CANDIDATE_2026-10-03.md) consolidates the actual interface gaps, including T3 precision/output. The [teammate guide](REPRODUCE_CPU_2026-10-03.md) gives independent source/build/24-case/T2-low/T7/T5/T9-RHS01 steps and the required provenance, job and acceptance records. Completion of independent reproduction depends on evidence from the teammate who performs it.

The public contest page and current official README were read on 3 October and rechecked on 14 October. The README is byte-identical to the saved project version. It documents the argument contract, per-problem customization and MPICH, with a two-rank example. The conference page lists task submission on 30 October at 24:00. Exact formal package layout, required launch settings, numerical scaling placement, untimed conversion/sort integration, CPU timing-unit labeling, tier handling, T2 compatibility, ten-RHS reuse/aggregation, portal timezone and final receipt still need the actual organizer contract. The [updated candidate sheet](SUBMISSION_CANDIDATE_2026-10-03.md) aligns the frozen package/report with the later measured launch settings and links the current source/package checks and feedback drafts.

## Alternate-platform conditions and budget

SCNet login and the E-Shell screen are observable through native Chrome. The region is 华中一区【A区】, Linux user `travissun`; the 14 October accounting prompt is `zz-login02`. The immediate G0 request 882897 returned “Requested nodes are busy” before allocation. Normal queued G0 job **883172** subsequently completed `0:0` in two seconds on `f11r1n20`. Its actual allocation was one CPU, one DCU and `3800M` host memory. The [GPU environment and execution record](SCNET_GPU_G0_2026-10-04.md) identifies `gfx936`, approximately 64 GiB of device memory, DTK module 25.04.2 and actual dcc 25.08.0/clang 17. On 5 October, probe **887201** executed and passed the double-precision HIP kernel, then ended `FAILED 1:0` after three seconds when `mpirun` rejected `--bind-to`. The 7 October component diagnostic identified an omitted OpenMPI plugin directory in the module environment. Job 890942 then passed single-process MPI initialization and finalization on the assigned compute node after the job-local path correction. Source preparation 891308 identified the installed HIP package paths but failed to resolve GitHub. Native file upload and terminal input recovered on 7 October; the agent uploaded the cached pinned HYPRE archive and build script, verified both remote hashes and submitted **891416**. The 8 October accounting is `FAILED 2:0`, 38 seconds on `f11r1n18` with four CPUs. Its original stderr identifies a missing MPI header include path during HIP compilation. The observed MPI include path was added explicitly for the subsequent builds described below. The Chrome extension connection still fails. The [14 October LX2 record](华为平台接入进度.md) supplies the backend, account, queue and data path. Backend SSH login is now verified at the node76 prompt and the user completed initial password change; actual scheduler, toolchain, data access and allocated workload validation remain pending.

The corrected HIP build was synchronized and submitted as **891465** on 8 October. Its [final accounting](../logs/2026-10-08/gpu/hypre-build-891465-status.json) is `FAILED 2:0`, 427 seconds on `f11r2n02` with four CPUs. The HYPRE HIP static library finished compiling; the IJ executable failed to link because the generated search path points above the installed Clang builtins directory. Relink validation **892530** supplied the actual runtime directory and reused the build tree. Its [accounting and execution results](../logs/2026-10-08/gpu/hypre-relink-892530-status.json) confirm `COMPLETED 0:0`, 131 seconds on `f11r3n10`, four CPUs, and an 8×8×8 device-memory solve converging in 12 iterations to `2.016065e-09`. The library archive changed during this run. Rebuild **892588** added the HIP block-limit parameter at 1024; its [final accounting](../logs/2026-10-08/gpu/hypre-build-892588-status.json) confirms `COMPLETED 0:0`, 413 seconds on `f11r2n10` with four CPUs. The [subsequent runtime record](../logs/2026-10-08/gpu/hypre-runtime-892588-user-output.log) verifies the exact source/configuration/binary identities and the same 12-iteration residual. The thread-limit diagnostic was cleared in 892588; that historical run retained an `orted/hwloc` cleanup double free. Subsequent singleton repeat **893006** completed `0:0` in two seconds on the same `f11r2n10` and verified the same example binary. The [9 October supplied record](../logs/2026-10-09/gpu/hypre-smoke-893006-user-output.log) confirms registered isolated-singleton mode, solver exit zero, twelve iterations, residual `2.016065e-09`, empty batch stderr and zero-byte runtime stderr. G1 therefore passes for this synthetic single-process/single-DCU configuration; the general cleanup root cause is not established. Fourteen recorded GPU allocations, including failed attempts, account for 1,044 whole seconds; HYPRE build/relink accounts for 1,009 seconds, and conservatively including the new T2 build/small-case allocation gives 1,029 seconds against the two-hour integration cap. T2 job 897432 completed on 14 October and passed all fifteen HIP small-system solves. The same-source CPU regression also passes. The full-data request was rejected before allocation for the current account/partition combination; its [live access summary](../logs/2026-10-14/plan-execution/scnet-partition-access-summary.json) records the team's direct absence from the partition allow list. Full T2 accuracy and performance validation remain pending.

The four new CPU allocations total **2,907 seconds = 0.8075 single-node hours**, including T1 and the failed comparison. Together with the delivered 11.4861 hours, the tracked CPU total through the launch campaign is **12.2936 single-node hours**. The two 9 October S2 allocations add 72 seconds, bringing the tracked total to **12.3136 single-node hours**. At most two SC26 CPU jobs ran concurrently. Raw [accounting](../logs/2026-10-03/next-phase/jobs-accounting-20261004.log) preserves scheduler-reported timestamps. The three-hour performance cap and original 18–25-hour project budget remain separate from the commercial CPU platform's absence of a machine-time quota.

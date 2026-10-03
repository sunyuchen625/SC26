# SolverChallenge26 next-phase results

Evidence dates: 3–4 October 2026, Asia/Shanghai. Scope: the [approved next sequence](reviews/STATUS_REVIEW_2026-10-02.md), following delivered commit `6b7f675ecaa6949815a3a77f95467fc35f8d5bbf`.

The frozen-method CPU launch campaign is complete. All fourteen configurations from its two completed allocations pass the existing numerical/execution/provenance verifier. Current paired measurements exceed the 10% time-reduction target for T2-low, T7 and T6. The T1 diagnostic completed below 9 GB; its proposed 90%/10% metric trigger was not met. A source candidate and teammate reproduction guide are prepared. Formal launch/package conditions and independent teammate evidence remain open. The [completed native Claude Opus 5.5/max audit](reviews/CLAUDE_NEXT_PHASE_AUDIT_2026-10-04.md) gives PASS for this bounded phase.

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

The public contest page and current official README were read on 3 October. The README is byte-identical to the saved project version. It documents the argument contract, per-problem customization and MPICH, with a two-rank example. Exact formal package layout, required launch settings, numerical scaling placement, untimed conversion/sort integration, tier handling, T2 compatibility, ten-RHS reuse/aggregation and closing time still need the actual organizer contract.

## Alternate-platform conditions and budget

SCNet login and the E-Shell screen are observable through native Chrome. The region is 华中一区【A区】, Linux user `travissun`; the latest visible prompt is `zz-login02`. Browser automation reports a connection failure, and automated terminal input has not produced confirmed remote output. The web task entry has not yielded an operative submission form. The user executed the one-DCU immediate G0 request: job 882897 returned “Requested nodes are busy” before allocation. The [observed terminal record](../logs/2026-10-03/next-phase/gpu-g0-attempt-20261004.log) contains that failure. The user submitted normal queued G0 job **883172** using the [inventory script](../scripts/scnet-g0.sbatch). Its latest user-reported state is **PENDING**; the [visible terminal accounting](../logs/2026-10-03/next-phase/gpu-g0-observation-20261004.log) also shows `None assigned` and no output files. Its allocated output will determine the subsequent HIP work. Browser control remains unavailable after attempts through Chrome and the in-app browser. LX2 remains dependent on confirmed backend recovery and connection details.

The four new CPU allocations total **2,907 seconds = 0.8075 single-node hours**, including T1 and the failed comparison. Together with the delivered 11.4861 hours, the tracked CPU total is **12.2936 single-node hours**. At most two SC26 CPU jobs ran concurrently. Raw [accounting](../logs/2026-10-03/next-phase/jobs-accounting-20261004.log) preserves scheduler-reported timestamps. The three-hour performance cap and original 18–25-hour project budget remain separate from the commercial CPU platform's absence of a machine-time quota.

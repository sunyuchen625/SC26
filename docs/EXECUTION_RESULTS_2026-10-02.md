# SolverChallenge26 execution results

Evidence date: 2 October 2026, Asia/Shanghai. Scope: the [approved execution plan](EXECUTION_PLAN_2026-10-01.md), using the organizer's commercial CPU cluster. The experiment directory is dated 1 October, when execution started.

The structure-only direct candidate passes full-scale T4, T6 and all ten RHS of T8, T9 and T10. Source defaults reproduce T2's lower-tier pass and T7's pass without experimental environment overrides. T5 satisfies the convergence-margin acceptance on two nodes and at 64/96 ranks. All thirty direct RHS records pass the complete saved acceptance checks.

## Implementation and validation boundary

Direct analysis passes a `NULL` values pointer to PARDISO phase 11 and explicitly sets scaling and matching to zero. The existing CSR representation, complex conversion and T10 column/value sorting are retained. Logs identify the installed oneMKL 2022.0.0 build, effective options, factor sizes and perturbed pivots. The installed 32-bit initialization defaults report scaling and matching enabled; the 64-bit path uses explicit parameters.

T4 now shares the existing 64-bit PARDISO/CSR path with T10, following an observed factor-index overflow. T2 defaults to projection and tolerance `1e-7`; the unique-solution small cases explicitly disable projection. T7 defaults to tolerance `1e-12` and ILU(0). The T5 candidate defaults to pressure MGR, tolerance `5e-9` and an iteration cap of 450.

Each normal acceptance run executes five complete callbacks, then the original in-memory float128 check against the original matrix and right-hand side. T8 uses the maximum absolute residual; the other recorded problems use the relative two-norm residual. `tests/check_result.py` remains the numerical log checker, and `scripts/verify_runs.py` adds execution and provenance checks. Six-decimal answer files are outside the numerical acceptance boundary.

The recorded memory is the complete-process GNU time peak. For MPI runs, rank peaks are summed conservatively; they need not occur simultaneously. Acceptance also checks process exits, Slurm completion, five phase records, and the applicable T1/T9 memory limits. Source manifests, CMake cache hashes and binary identities connect each fresh result to its frozen build. Builds and full-scale computations run inside allocated Slurm jobs.

## Completed five-solve acceptance

| Problem | Job | Configuration | Original residual | Framework mean | Full-process peak |
| --- | --- | --- | ---: | ---: | ---: |
| T2 lower tier | 9210626 | 16 MPI ranks; source defaults | 5.885605e-7 relative | 26.868102 s | 15.594 GB summed |
| T7 | 9210627 | 16 MPI ranks; source defaults | 1.601450e-9 relative | 22.873265 s | 67.247 GB summed |
| T4 | 9211739 | 32 threads; 64-bit indices; value-free analysis | 1.170601e-12 relative | 114.693288 s | 138.446 GB |
| T5 | 9210478 | 96 MPI ranks; source defaults | 2.576043e-9 relative | 186.844411 s | 203.111 GB summed |
| T6 | 9210509 | 32 threads; value-free analysis | 1.834771e-12 relative | 58.308549 s | 37.406 GB |
| T8 RHS 01 | 9210510 | 32 threads; value-free analysis | 2.408763e-16 maximum absolute | 77.810522 s | 42.614 GB |
| T9 RHS 01 | 9210479 | 32 threads; value-free analysis | 1.326167e-16 relative | 79.631060 s | 28.129 GB |
| T10 RHS 01 | 9211884 | 32 threads; final v19 reciprocal row pairs; numerical scaling | 7.227728e-15 relative | 188.761426 s | 128.813 GB |

All listed jobs completed with Slurm `COMPLETED 0:0`, process exit zero and verified source/configuration provenance. T5/T7 reported internal convergence in all five solves. The T2/T5/T7 default submissions had `SC26_RTOL` and `SC26_PROJECT_CONSTANT` unset. Rank/thread counts are recorded per row and differ from several September baselines.

Evidence: [selected direct results](../logs/2026-10-01/execution/selected-verification.json), [final-source T10 RHS 01](../logs/2026-10-01/execution/final-t10-rhs01-verification.json), [default results](../logs/2026-10-01/execution/defaults-verification.json), [T5 margin results](../logs/2026-10-01/execution/t5-margin-verification.json), and their [direct](../logs/2026-10-01/execution/selected-runs.json), [final T10](../logs/2026-10-01/execution/final-t10-rhs01-runs.json), [default](../logs/2026-10-01/execution/defaults-runs.json) and [T5](../logs/2026-10-01/execution/t5-margin-runs.json) manifests.

The eight-target v4 build passed all 20 existing small cases in job 9210469. The v15 build added T4 and passed all nine targets and 23 cases in job 9211738. The frozen final v19 build passed all nine targets and 24 cases in job 9211860, including a missing-diagonal complex system with reciprocal connections and unsorted columns. The [binary comparison](../logs/2026-10-01/execution/final-binary-comparison.json) establishes identical executable bytes outside the non-allocated ELF `.comment` section for T2/T4/T5/T6/T7/T8/T9 against their accepted builds. T4 is fully byte-identical; the other differences are two characters in the GCC startup-object version string. Their code and data are unchanged.

## T4 factor-index diagnosis and single-solve result

The 32-bit analysis job 9210629 printed 9,539,544,996 factor nonzeros while `iparm[17]` overflowed to 949,610,404. The 64-bit analysis job 9210637 reported 9,169,913,772 factor nonzeros and an estimated peak of 121,479,555 KiB. This established the need to extend the existing wide-index path.

Job 9210659 then completed one analysis, one factorization and one solve on c3n34 with 32 threads and a 150 GiB allocation. The original relative residual was **6.043028e-13**, with process exit zero and Slurm `COMPLETED 0:0`. Analysis took 72.614970 s, factorization 52.103627 s and solve/cleanup 6.051518 s; their sum was 130.770115 s. Full-process peak memory was 138,387,951,616 bytes.

Normal acceptance followed in v15. Build 9211738 passed the 23 known-solution cases. Job 9211739 completed five full callbacks on c3n14 with 32 threads; the final relative residual was **1.170601e-12**, framework mean 114.693288 s, and full-process peak 138,445,668,352 bytes. Each factorization reported zero perturbed pivots. Process exit, Slurm completion and source/cache/binary provenance passed the existing verifier. Raw evidence is under [batch logs](../logs/2026-10-01/execution/batch/) and [runs](../logs/2026-10-01/execution/runs/).

## Bounded numerical experiments

| Problem / experiment | Job | Ranks or threads | Original relative residual | Framework mean | Full-process peak |
| --- | --- | ---: | ---: | ---: | ---: |
| T1 variable-aware AMG | 9210555 | 8 ranks | 5.120941e1 | 101.701884 s | 6.951 GB summed |
| T1 variable-aware AMG | 9210580 | 16 ranks | 3.085449e2 | 47.396139 s | 8.010 GB summed |
| T1 MGR, third temperature coarse | 9210632 | 8 ranks | 9.348043e1 | 94.972634 s | 7.764 GB summed |
| T1 MGR, first temperature coarse | 9210633 | 8 ranks | 4.412557e0 | 96.105858 s | 7.805 GB summed |
| T3 explicit numerical DAD scaling | 9210636 | 16 threads | 5.414750e-5 | 46.011686 s | 13.850 GB |
| T3 original-system GMRES with scaled PARDISO preconditioner | 9210658 | 16 threads | 2.702628e-5 | 63.972122 s | 14.587 GB |
| T10 value-free analysis, unscaled factorization | 9210520 | 32 threads | 1.926778e28 | 184.981494 s | 121.968 GB |
| T10 explicit numerical DAD scaling | 9210634 | 24 threads | 3.360065e9 | 186.279025 s | 121.466 GB |
| T10 parallel nested dissection with numerical DAD scaling | 9210697 | 32 threads | 1.714870e9 | 128.836212 s | 122.426 GB |
| T10 structure-only row matching with numerical scaling | 9211747 | 32 threads | 1.284191e12 | 206.717354 s | 127.410 GB |

Each row completed five solves and its processes returned zero. The batch jobs ended `FAILED 1:0` because the original numerical check rejected the result. Their frozen source, cache and binary provenance is verified in [experimental results](../logs/2026-10-01/execution/experimental-verification.json); an aggregate verifier exit of one is the expected verdict for this manifest. These experiments remain identifiable in the archived evidence.

The four planned T1 trials satisfy the 9 GB memory bound but fail the lower-tier residual requirement. The bounded T1 branch is complete for this round.

T3 diagnostic job 9210628 used nine fresh phase-33 solves on one factorization, requesting refinement budgets zero through eight. Requested and performed counts agreed. The relative residual fell from 1.188179e-4 to approximately 2.74e-5 and then stalled. The final solution infinity norm was approximately 1.16e4, the maximum row sum of `|A||x|` approximately 1.30e9, and the right-hand-side two-norm approximately 0.0321. These diagnostics show substantial cancellation. Together with the two five-solve rows above, the three approved T3 trials complete this round; they do not establish impossibility of the target accuracy.

T10's unscaled and DAD candidates both reported 1,386 perturbed pivots per factorization. The v14 experiment used parallel nested dissection (`iparm[1]=3`) with the same post-analysis DAD scaling. Its complete original relative residual was 1.714870e9; pivots were 1,386 in four repetitions and 1,436 in one. The full CSR contains **1,613 missing structural diagonal positions**. Build 9210696 and the five-solve result are archived.

The v17 structural-matching build passed all 24 small cases. Full job 9211747 matched all 418,718 rows, moved 3,226 rows and reduced perturbed pivots to 580 per factorization, but its final original residual was 1.284191e12.

The selected method preserves existing structural diagonals and pairs each remaining row with the nearest available row having a reciprocal CSR connection. The permutation P depends only on column indices. The owned CSR, complex values and right-hand side represent PA and Pb; phase 11 receives `NULL` values with library scaling/matching disabled. Numerical preparation forms D(PA)D and DPb, and the returned solution is restored as x=Dy before the original-system check. Full job 9211791 completed five solves with relative residual **7.231651e-15**, mean 202.711104 s and peak 128,814,817,280 bytes. All 1,613 missing diagonals were paired, 3,226 rows moved, and each factorization reported one perturbed pivot.

The frozen final source v19 has manifest SHA256 `bf8148b56bf20d4c0249b24c8d9540c4212cec153760944f5b38b20137ee68a9`. Its clean nine-target/24-case build completed normally. All ten T10 RHS completed in two sequential lanes with 32 threads and 150 GiB: jobs 9211884–9211888 cover RHS 01–05; jobs 9211889–9211893 cover RHS 06–10. Each successor used `afterany` on the previous job, retaining at most two running SC26 jobs. All ten have five complete callbacks, original residual passes, process exit zero, Slurm `COMPLETED 0:0` and verified source/cache/binary provenance. Evidence: [final T10 manifest](../logs/2026-10-01/execution/final-t10-runs.json) and [verification](../logs/2026-10-01/execution/final-t10-verification.json).

## All-RHS acceptance

Jobs 9210630 (T9) and 9210631 (T8) completed all ten RHS apiece on c3n90 using 16 threads. The final T10 jobs use 32 threads and the v19 source. All thirty records pass the original numerical checker, five-solve/execution checks, applicable memory limits and source/configuration provenance. The [full-RHS manifest](../logs/2026-10-01/execution/full-rhs-runs.json) requires exactly RHS 01–10 for each problem; the [verification](../logs/2026-10-01/execution/full-rhs-verification.json) accepts all thirty.

| Problem | Maximum original residual across ten RHS | Per-RHS framework mean range | Sum of ten means | Largest full-process peak |
| --- | ---: | ---: | ---: | ---: |
| T8 | 3.537289e-16 maximum absolute | 79.191692–79.560917 s | 793.459075 s | 40,099,975,168 bytes |
| T9 | 1.051758e-15 relative | 75.559040–75.954751 s | 757.628227 s | 24,635,875,328 bytes |
| T10 | 7.521765e-15 relative | 181.421000–214.132749 s | 2,004.431736 s | 128,830,332,928 bytes |

These sums describe the current per-RHS invocation. Formal scoring aggregation and reuse remain governed by the organizer's interface.

## T5 convergence margin

The four R4 jobs completed on two distinct nodes with two rank counts. Each records five internal convergence flags of one and an original residual at most `5e-9`; process, Slurm and provenance checks also pass.

| Job | Node / ranks | Scaled tolerance | Iterations in each solve | Original relative residual | Framework mean | Summed process peak |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 9210478 | c3n29 / 96 | Source default 5e-9 | 342 | 2.576043e-9 | 186.844411 s | 203.111 GB |
| 9210707 | c3n29 / 96 | Explicit 2e-9 | 353 | 1.115346e-9 | 192.066167 s | 202.705 GB |
| 9210708 | c3n90 / 64 | Source default 5e-9 | 330 | 2.704132e-9 | 262.241067 s | 191.653 GB |
| 9210709 | c3n90 / 64 | Explicit 2e-9 | 351 | 8.506732e-10 | 278.685928 s | 191.649 GB |

The selected 96-rank default is approximately 11.7% slower than the September 167.237252 s mean, satisfying the approved approximately 20% timing target. The 64-rank results provide the required robustness evidence with their own timings. The validated default remains pressure MGR, tolerance `5e-9`, cap 450. Evidence: [margin verification](../logs/2026-10-01/execution/t5-margin-verification.json).

The user confirmed that commercial CPU has no platform machine-time quota. Execution used **11.4861 tracked single-node hours**, within the approved 18–25 node-hour budget, and retained at most two running SC26 jobs. Final allocation accounting is saved in [job accounting](../logs/2026-10-01/execution/jobs-final-accounting-20261002.log).

## Access and delivery status

SSH access was restored after the user reported recovery at midday on 2 October. The [recovered accounting](../logs/2026-10-01/execution/jobs-recovery-20261002.log) confirms that the submitted Slurm jobs completed during the access interruption. Their results, batch logs and caches are now archived. The earlier [01:50 refusal](../logs/2026-10-01/execution/connection-status-20261002.log) remains dated access evidence.

The SCNet web E-Shell remains open, but its terminal output could not be read through the available browser/native UI connection. The planned G0 inventory awaits an observable allocated job. LX2 remains dependent on the staff's maintenance-recovery confirmation and backend connection details. The formal submission interface, MPI requirement, accuracy-tier packaging and multi-RHS reuse are governed by the organizer questions in the approved plan.

The [Chinese technical report](SC26技术报告_2026-10-02.docx) follows the official DOCX template and records the numerical and memory scope of the completed evidence. All six rendered pages were inspected and the original template's section and table geometry were verified. The [local read-only Claude Opus 5.5 max audit](reviews/CLAUDE_EXECUTION_AUDIT_2026-10-02.md) returned **PASS**, with no blocking findings. The current-state document corrections are recorded with the complete audit. GitHub delivery is authorized; formal eligibility, teammate reproduction, GPU/LX2 work and portal submission retain the boundaries above.

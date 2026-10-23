# Current CPU numerical evidence

Updated: 24 October 2026, Asia/Shanghai. Measurements below retain their dated configurations; current performance is not inferred from mixing different jobs. The frozen CPU candidate comes from `6b7f675`, with 118 manifested source/script/test entries and final v19 manifest `bf8148b56bf20d4c0249b24c8d9540c4212cec153760944f5b38b20137ee68a9`.

## Passing full-scale configurations

These runs completed five full callbacks, original-system in-memory float128 validation, successful rank/launcher exits, scheduler `COMPLETED 0:0`, memory and source/cache/binary checks. The measurements were completed by 2 October.

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

The source-default T2/T5/T7 runs clear numerical environment overrides. T8 uses maximum absolute residual; the other selected systems use relative two-norm. Direct analysis passes NULL values to PARDISO phase 11 and disables numerical scaling/matching. T4 uses 64-bit factor indices. T10's row permutation depends only on CSR indices; numerical preparation applies scaling and restores the original solution before validation.

[Default run manifest](../logs/2026-10-01/execution/defaults-runs.json), [selected direct manifest](../logs/2026-10-01/execution/selected-runs.json), [final T10 manifest](../logs/2026-10-01/execution/final-t10-runs.json) and their adjacent verification records retain the raw linkage. The source-manifest files referenced by these records remain available; the current frozen implementation is supplied in the CPU candidate package.

## T8/T9/T10: all ten right-hand sides

| Problem | Maximum original residual across ten RHS | Per-RHS framework mean range | Sum of ten means | Largest full-process peak |
| --- | ---: | ---: | ---: | ---: |
| T8 | 3.537289e-16 maximum absolute | 79.191692–79.560917 s | 793.459075 s | 40,099,975,168 bytes |
| T9 | 1.051758e-15 relative | 75.559040–75.954751 s | 757.628227 s | 24,635,875,328 bytes |
| T10 | 7.521765e-15 relative | 181.421000–214.132749 s | 2,004.431736 s | 128,830,332,928 bytes |

All thirty records have five full solves, valid original residuals, successful execution and verified provenance. These sums describe independent RHS invocations. Formal reuse and score aggregation require the actual testing contract. [Full-RHS manifest](../logs/2026-10-01/execution/full-rhs-runs.json), [verification](../logs/2026-10-01/execution/full-rhs-verification.json).

## T5 convergence margin

| Job | Node / ranks | Scaled tolerance | Iterations in each solve | Original relative residual | Framework mean | Summed process peak |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 9210478 | c3n29 / 96 | Source default 5e-9 | 342 | 2.576043e-9 | 186.844411 s | 203.111 GB |
| 9210707 | c3n29 / 96 | Explicit 2e-9 | 353 | 1.115346e-9 | 192.066167 s | 202.705 GB |
| 9210708 | c3n90 / 64 | Source default 5e-9 | 330 | 2.704132e-9 | 262.241067 s | 191.653 GB |
| 9210709 | c3n90 / 64 | Explicit 2e-9 | 351 | 8.506732e-10 | 278.685928 s | 191.649 GB |

The selected default remains pressure MGR, tolerance 5e-9 and cap 450. Both nodes and rank counts meet the internal residual margin and record five convergence flags. [Margin manifest](../logs/2026-10-01/execution/t5-margin-runs.json), [verification](../logs/2026-10-01/execution/t5-margin-verification.json).

## Frozen-method CPU launch comparison

Job 9213608 ran these configurations sequentially on one 8488C node. All settings use the same frozen v19 methods; iterative runs use one thread per rank, with recorded binding. T6 uses one MPI rank and the stated OpenMP/MKL threads.

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

Job 9213575 also passed its four preliminary configurations. Intervening allocation 9213582 failed during MPI/time execution and remains in the accounting; it is not a passing performance result. [All fourteen passing configuration records](../logs/2026-10-03/next-phase/launch-runs.json), [verification](../logs/2026-10-03/next-phase/launch-verification.json), [raw accounting](../logs/2026-10-03/next-phase/jobs-accounting-20261004.log).

The fastest recorded experimental 96-rank T2 reference is 7.036402 s. [23 October controls](T2_CPU_CONTROLS_2026-10-23.md) measure 7.126864 s at 96 ranks; the [same timed-driver controls](T2_GPU_PREPARATION_2026-10-23.md) later measure 8.416504/8.670765 s. Keep each timing scope and all comparable runs. Final comparison uses the fastest permitted CPU configuration covered by applicable evidence.

## Delivery boundary

T1, T3 and T2-high remain below their required accuracy. Their original logs and failed-result verdicts remain evidence of those limits. Five repeated callbacks are followed by one original-system float128 check; six-decimal answer files do not substitute for that check. MPI RSS values are conservative sums of complete-process rank peaks, rather than simultaneous node peaks.

Numerical acceptance does not establish the formal launcher, timer, output parser, multi-RHS score convention or teammate reproduction. Use the [candidate settings](SUBMISSION_CANDIDATE_2026-10-03.md), [reproduction guide](REPRODUCE_CPU_2026-10-03.md) and [current work order](SC26_队友交接工单_2026-10-24.md).

# T2-low GPU preparation and repeated timing

> Historical experimental scope: the original five-round records and seconds below are retained. They are not scores under the 27 October 15:38 five-warmup/five-official-run protocol. Current measurement tasks are in the [delivery plan](DELIVERY_PLAN_2026-10-27.md).

Date: 23 October 2026, Asia/Shanghai. Exact IJ diagonal/offdiagonal preallocation and HIP interpolation 18 reduce the full prototype driver mean to **3.905254 s**, reproduced at **3.907222 s** and **3.903342 s** in job **962526**. All three original-system float128 checks are **5.896126e-7**, below `1e-6`; each contains five complete solves at default internal tolerance `1e-7`, 24 GMRES iterations per round. This report describes the current GPU candidate and its experimental S4 evidence.

## Implementation and timing

The HIP branch counts each structural row's local and remote columns using the row's ownership interval and passes both count arrays to `HYPRE_IJMatrixSetDiagOffdSizes`. The pinned HYPRE 2.33.0 implementation copies both arrays; they are freed after the call. These counts use indices only. Their computation remains inside `analyse`, and the unchanged overall driver timer includes it. HIP AMG uses interpolation 18, general relaxation 18, coarse relaxation 6, RAP2 enabled and GMRES restart 50. The CPU algorithm keeps its prior parameters and estimated row allocation.

The iterative MPI driver records each complete round from vector reset through analysis, preparation, solve/cleanup and the ending MPI barrier. The existing maximum-rank overall five-round mean remains the primary metric. Per-round maxima are reduced and printed after stopping that overall timer. Their arithmetic mean is a distinct statistic and need not equal the maximum-rank overall mean; ignoring loop overhead, the average of per-round maxima is at least the maximum of per-rank averages. The added diagnostics apply to both real and complex driver loops; this phase validates the affected T2 real path.

Preparation probes measure host-observed assembly, migration/policy and GMRES/AMG setup call intervals, including implicit synchronization and diagnostics within those intervals. They are not isolated GPU kernel timings. All reported prototype totals include the implementation's transfers, diagnostics and cleanup. Formal transfer-excluded scoring requires the actual entry/timing contract.

## Screening and repetitions

Each variant first passes Poisson, nonsymmetric and Neumann known systems, five solves per system, then five full T2-low solves. In each allocation the instrumented baseline receives another full run and the fastest screened variant receives two. All comparable attempts are retained.

| Allocation / variant | Full five-round means, seconds |
| --- | --- |
| `962398`, instrumented l1-Jacobi / interpolation 6 baseline | 6.825540; repeat 6.821888 |
| `962398`, restart 30 | 6.839748 |
| `962398`, interpolation 18 | 6.744615; repeats 6.741028, 6.732985 |
| `962398`, RAP2 disabled | 6.854984 |
| `962526`, interpolation 18 / estimated row allocation | 6.719512; repeat 6.725953 |
| `962526`, interpolation 18 / exact row allocation | **3.905254; repeats 3.907222, 3.903342** |

Job `962398` completed `0:0` on `f11r1n08`, 15:42:26–15:52:37, **611 allocated seconds**; 95 complete solves pass. Job `962526` completed `0:0` on `f11r1n09`, 16:04:30–16:10:49, **379 allocated seconds**; 55 complete solves pass. Both grants are one DCU, 16 CPUs and 58 GiB; each GPU invocation uses one MPI process and one OpenMP thread. GPU multi-rank behavior is outside these experiments.

The exact-allocation screen improves **41.882%** over its same-allocation interpolation-18 baseline. Mean assembly calls fall from **3.774299 s** to **0.873945 s**; migration/policy remains about **0.143 s**, setup about **1.778 s**. The total metric counts the structural scan, so this is an end-to-end improvement. Exact full-process host RSS peaks range from **4,909,244 to 4,926,220 KiB**; the maximum rounded GPU phase observation is **15.30 GiB**, against 63.98 GiB reported capacity. Phase observations do not establish a continuous GPU memory peak.

| Screen callback mean (s) | Estimated allocation | Exact allocation |
| --- | ---: | ---: |
| Analyse, including structural scan | 0.058489 | 0.186032 |
| Preprocess | 5.691255 | 2.795171 |
| Solve and cleanup | 0.957678 | 0.912085 |

Analysis increases by **0.127542 s** per round; the primary driver improvement includes this cost. Preprocess falls by **2.896084 s** and solve/cleanup by **0.045593 s**. These separately scoped callback means explain the net gain rather than assigning the entire gain to assembly. Exact insertion also changes the in-row ordering: the pinned host assemble path swaps the diagonal to the first slot, whereas the estimated-allocation path shifts other entries. The observed convergence trajectory changes slightly: both screens take 24 iterations, final internal residuals are approximately **5.8641e-08** (estimated) and **5.8097e-08** (exact), and original float128 residuals are **5.896665e-7** and **5.896126e-7**, respectively. All remain within the stated numerical gates.


| Exact candidate full run | Round 1 | Round 2 | Round 3 | Round 4 | Round 5 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Screen | 4.033378841 | 3.873334929 | 3.871909960 | 3.874022003 | 3.873624183 |
| Repeat 1 | 4.056492682 | 3.868203992 | 3.868638780 | 3.869651810 | 3.873123418 |
| Repeat 2 | 4.041271720 | 3.868037368 | 3.868752863 | 3.869637975 | 3.869008607 |

Seconds above are measured complete outer-round MPI maxima. Across all 15 candidate rounds the observed range is **3.868037368–4.056492682 s**. First rounds remain included. This is an observed range from sequential runs, rather than a statistical confidence interval.

[Screening verification](../logs/2026-10-23/gpu-preparation/screening-verification.json) and [exact-preallocation verification](../logs/2026-10-23/gpu-preparation/exact-verification.json) retain all per-case rounds, original residuals, internal convergence, device policy, phase records, process exits, memory and identities. Their adjacent `screening/` and `exact/` directories retain raw records, submitted batches, scheduler receipts, source snapshots and CMake caches. Retrieved archives match remote SHA256 `5a22e05078b49c2cb3c01d65d38669453d5c467fef562753b85915e555a35d1e` and `c461444dfd0c87c2640e42c34d68128cea34f61d4a6d8a2af8f998871bb3d3d2`. Both GPU batch stderr files are empty. Every small-system original residual is below `1e-10`, with known solutions checked independently.

## CPU control and S4

Exact-source HIP-off build/regression **9270818** completed `0:0` on `c3n50`, 16:17:05–16:19:57, **172 seconds**, four CPUs / 16 GiB. Six known-system cases at one and four MPI ranks pass **30 complete solves**, with maximum original residual **4.340013e-12** and known-solution error **1.249001e-16**. All 89 source entries match the GPU snapshot. [Regression verification](../logs/2026-10-23/gpu-preparation/cpu-build-verification.json) and `cpu-build/` retain the build, source, binary receipt and case records.

Full control **9270819** completed `0:0` on `c3n182`, 16:23:56–16:26:43, **167 seconds**, 96 CPUs / 60 GiB. Two sequential runs use the same built exact-source HIP-off binary, one thread per rank, core binding, the same timed driver and original inputs. All ten solves converge in 18 iterations at internal tolerance `1e-7`; both original float128 residuals are **5.875263e-7**. Every launcher and all **192 rank process exits** are zero. Conservative sums of complete-process rank RSS peaks are **20,005,840** and **19,992,264 KiB**, within the 60 GiB grant. Raw module/locale and OpenMPI bindings/device warnings accompany successful checkers and scheduler completion.

| CPU full run | Overall mean | Round 1 | Round 2 | Round 3 | Round 4 | Round 5 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Repeat 1 | 8.416504 | 8.451929333 | 8.381401304 | 8.441860665 | 8.422939108 | 8.384708296 |
| Repeat 2 | 8.670765 | 8.394323253 | 9.683222127 | 8.355807160 | 8.512082952 | 8.408699072 |

All times are seconds. The slower second CPU round is retained. Fresh CPU round maxima span **8.355807160–9.683222127 s**, fully separated from all 15 exact GPU rounds. The fresh CPU means are slower than the earlier same-day **7.126864 s** control and the earlier [CPU experiment](CPU_RESULTS.md) at **7.036402 s**; the comparison therefore conservatively retains **7.036402 s**, the fastest recorded 96-rank mean. Even the worst exact GPU repeat, **3.907222 s**, reduces that mean by **44.471%**, exceeding the preferred 10% S4 target. Source/instrumentation and node differences are recorded; these observations are not a randomized statistical comparison.

**Experimental S4 performance passes against the measured 96-rank CPU setting**, with repeated GPU means, actual round ranges and contemporaneous CPU controls. Formal S4/platform acceptance remains conditional on the actual permitted launcher/ranks, HIP entry/admissibility and transfer-excluded timing contract. The frozen CPU package remains the provisional formal delivery until those terms are settled; genuine teammate reproduction is also outstanding. The 24 October eligibility and 25 October freeze gates retain their scope.

Both CPU receipts report Intel Xeon Platinum 8488C, two sockets, 48 cores per socket and one thread per core. Their instantaneous `lscpu` frequency observations differ and do not explain frequency during the solve. On c3n17 versus c3n182 repeat 1, mean CPU callbacks are analyse 0.002258/0.001898 s, preprocess 5.421794/6.636346 s and solve/cleanup 1.702893/1.778164 s. The timing drift remains unexplained; the performance decision uses the faster historical reference. The pre-existing round barriers are retained in both source versions.

[Full CPU verification and S4 calculation](../logs/2026-10-23/gpu-preparation/cpu-control-verification.json) and `cpu-control/` retain both raw runs, 192 per-rank time records, binding warnings, exact binary checks and terminal accounting. Remote archive SHA256 values match **79069fe97b40c0447a2349b5e2315b86a8d4a0dcd646c14523b79edced7510d9** (build/regression) and **683ac45aa594dcb05a7014d204891a09f265d1fbe151d797fed27b14f9243fd3** (full control). Identical build files in the second archive were compared byte-for-byte with the first retained build snapshot.

## Delivery identity and allocation reconciliation

The [preparation source archive](../deliverables/SC26_T2_HIP_preparation_20261023.tar.gz) contains 89 manifested source entries and 91 members, parent `d09163c18ce629d65d55c0e6316b9755b7e2975d`. Every manifested entry matches the current worktree and the exact GPU build source. [Source identity](../logs/2026-10-23/gpu-preparation/source-identity.json) records archive SHA256 `f9482721a702b88d4e1b5e87957f59a8391215eb1938a8599bfc055e1e1c1e3a`, manifest `edcbf44abeee448a736cc01bfe16ac58a052a74e44a132a2d67a2f35e0080d6b`, solver `ea585ebaf584fa059946ba40371378a03b5404629f841e66c286eb1a8f2856f4` and driver `34f19d4985ded7685eeca2f1f07e6dfec0af91c9039dba668be75a6dedf2a6d0`. The frozen CPU candidate retains its separate source and report identity.

Recovered overnight job **960428** completed `0:0`, 03:37:56–03:41:24 on `f11r1n01`, using **208 allocated seconds**. Its identical smoother-comparison batch passes 40 solves: baseline **12.740458 s**, l1-Jacobi **6.894245 s**, original residuals `5.938952e-7` / `5.894610e-7`. It is a distinct successful submission preceding `961898`. All eight individual solver logs, case exit/time/stderr files and the batch stdout are retained and verified. Each case has five converged solves and its original-system check. That historical driver has no individual outer-round records. [Historical verification](../logs/2026-10-23/gpu-preparation/historical-960428-verification.json) states this scope. This run is retained as a comparable historical result and adds its omitted allocation to the ledger.

The previous received-evidence subtotal of 1466 GPU seconds becomes **2664 seconds across 20 completed allocations**, including failures from prior phases: `1466 + 208 recovered + 611 + 379`. The two new experiments contribute **150 solves**, and the historical reconciliation contributes another **40 previously unrecorded solves**. The [allocation ledger](../logs/2026-10-23/gpu-preparation/allocation-ledger.json) records **339 new commercial CPU single-node seconds**, bringing the tracked approximate cumulative CPU use to **12.574433 node-hours**. Original combined job `9270765` was replaced only while pending and cancelled with **zero allocated seconds**; unrelated account jobs were preserved. This phase completes **190 new solves** (150 GPU, 30 CPU regression, 10 CPU full controls), plus the separately recovered 40 historical solves.

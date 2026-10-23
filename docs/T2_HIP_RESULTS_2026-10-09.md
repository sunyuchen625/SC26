# T2 HIP execution record

Updated: 23 October 2026, Asia/Shanghai. Current acceptance follows the [approved plan](NEXT_PLAN_ACCEPTANCE_2026-10-21.md).

**S1, S2 and original full T2-low S3 numerical acceptance pass for their identified snapshots.** The [23 October smoother comparison](T2_HIP_OPTIMIZATION_2026-10-23.md) passes 40 solves and reduces the same-allocation GPU mean from 12.739078 s to 6.809676 s. Final-source HIP validation and CPU regression pass; S4 platform selection remains inconclusive under the approved smaller-advantage criterion. The frozen CPU delivery remains the provisional primary submission path.

The sections below retain the S1/S2 and 14 October request evidence for their recorded snapshots. The current full entry point requests one DCU, 16 CPUs and 58 GiB with scheduler node selection, and revalidates three known systems on the allocated device before full data.

## Identified snapshot

Source archive: [SC26_T2_HIP_source_20261009.tar.gz](../deliverables/SC26_T2_HIP_source_20261009.tar.gz), SHA256 `9708c99de61699a0c9d7452503ab07c97284ed3287b57185a816947d8de58ee0`. All 89 manifest entries match the accepted 9 October source archive. Manifest SHA256: `7a5f354a82e8f5429190428f1a1c3f1381113e9eb7d4265de5b197cd906a96e9`. Parent commit: `d1c5bd160b5fd823c24e9f0f125f1f19cb7704e4`.

The uploaded [HIP builder](../scripts/scnet-t2-hip-build.sbatch) has SHA256 `ace025f03759e267dd645b0d4960aa3994fff8f71eae5897f675bab26451a6be`. It checks the recorded install-892588 library fingerprint and emits installed HIP/unified-memory features in its allocated build. Local shell syntax and the missing-allocation guard pass. Source and script [remote transfer checks](../logs/2026-10-09/plan-execution/t2-hip-897432-submission.log) are recorded separately from execution acceptance.

## S1: HIP build and known systems

The [batch output](../logs/2026-10-14/plan-execution/sc26_t2_hip_build-897432.out) and [final accounting](../logs/2026-10-14/plan-execution/t2-hip-897432-accounting-user.log) identify one node, one MPI process, four CPUs, one DCU and `15200M` host memory. The build uses `SC26_T2_HIP=ON`, float128 checks and the installed HIP HYPRE library, with unified memory disabled.

All three 385-row systems pass five complete GMRES solves at internal tolerance `1e-11`. Each case has five device/device policy records and five complete phase records. Projection is off for Poisson and nonsymmetric systems and on for Neumann. Each solver exits zero with empty runtime stderr; the original-system and known-solution checkers pass.

| Case | Original float128 relative residual | Known-solution maximum error | Complete-process host RSS peak |
| --- | ---: | ---: | ---: |
| Poisson | 5.279773e-12 | 0 | 577544 KiB |
| Nonsymmetric | 3.654671e-13 | 0 | 579956 KiB |
| Neumann | 6.013760e-13 | 8.673617e-17 | 581792 KiB |

The [verification record](../logs/2026-10-14/plan-execution/t2-hip-small-verification.json) and [actual per-case gate output](../logs/2026-10-14/plan-execution/t2-hip-897432-record-checks-user.log) bind the fifteen solves to these identities:

| Artifact | SHA256 |
| --- | --- |
| HIP executable | `7f02c33a25b0f30b80224b505e73a63a8f2dbda3f3cddd064003743fd6ea168d` |
| CMake cache | `5e0d630e62ea9a7c4d1330045e19e5d20594a5ee7cefcf445fe6b105d6d1e1bd` |
| Installed HYPRE library | `e3887d90f71190657cd3315b8b4e896bbf238ad38b0178f0b2b05ad8535deb36` |

The full small-case evidence archive `t2-897432-evidence-20261014.tar.gz` was downloaded and verified against its remote SHA256 `dd6ba2d52cd9e337b8d64b5940e63ee67ae774108575641f34cfd9f2f4509cbf`. The [individual cases, cache, batch and build logs](../logs/2026-10-14/plan-execution/t2-897432/) are retained locally. Raw records independently confirm the fifteen solves, policies, phases, projection settings, original residuals, zero exits and empty error files.

Device evidence combines the identified HIP/non-unified library and application with checked matrix/vector migrations in the source and HYPRE 2.33.0's memory-location dispatch to device matvec. All fifteen policy records agree with this path. Each case also contains five ANALYSE, five SETUP and five SOLVE memory observations. Their reported device capacity is 63.98 GiB; these rounded phase samples are not continuous peaks. The separate HYPRE device-info line reporting `0.00 GiB` is not used as capacity evidence.

## S2: CPU regression

Job **9227847** completed `0:0` on `c3n78`, four CPUs, 16 GiB requested memory, 25 allocated seconds. It extracted the identified archive into its own snapshot directory, configured `SC26_T2_HIP=OFF`, linked the actual CPU HYPRE and built only `MPI_iterative_solver`. The existing six-case script ran with the snapshot as its working directory and explicit `SC26_ROOT`/`SC26_BUILD_DIR` pointing to this new binary.

Each case has five GMRES records, five complete phase records and one original-system float128 check. Internal tolerance is `1e-11`; unique systems have projection off, and Neumann has projection on with the constant-nullspace checker argument.

| Case | MPI ranks | Original relative residual | Known-solution maximum error |
| --- | ---: | ---: | ---: |
| Poisson | 1 | 1.306065e-12 | 0 |
| Poisson | 4 | 4.340013e-12 | 0 |
| Nonsymmetric | 1 | 3.957536e-13 | 0 |
| Nonsymmetric | 4 | 3.526985e-12 | 0 |
| Neumann | 1 | 1.126722e-12 | 1.249001e-16 |
| Neumann | 4 | 5.420348e-13 | 8.153200e-17 |

The [complete verification](../logs/2026-10-09/plan-execution/t2-hipoff-verification.json) binds these results to the new cache, binary, library, source manifest, batch and test-script identities. Binary SHA256 is `6b02653379cef1a24599bf9b10dfe157f6dd19694080bf03e60c9ad4ddc29ffd`; cache SHA256 is `6eb81974d26f2506040d4b3e125584888044fe96884f660022d829fe786508b9`. The [batch output](../logs/2026-10-09/plan-execution/sc26_t2_hipoff-9227847.out), [scheduler accounting](../logs/2026-10-09/plan-execution/t2-hipoff-9227847-accounting.log) and [individual cases](../logs/2026-10-09/plan-execution/t2-hipoff-9227847/runs/small-9227847/) retain the raw evidence. OpenMPI OpenFabrics warnings are captured; all six launcher/checker invocations exit successfully.

Earlier job **9227732** completed all six numerical checks but ended `FAILED 1:0` at the batch's extra empty-stderr assertion. Its [status](../logs/2026-10-09/plan-execution/t2-hipoff-9227732-status.json), [batch output](../logs/2026-10-09/plan-execution/sc26_t2_hipoff-9227732.out) and individual case files are retained. The corrected batch used for 9227847 completes the required six-case gate. Both allocations count toward the engineering budget: **72 new CPU seconds**, bringing the tracked CPU total to **12.3136 node-hours**.

## S3: 14 October full-data request evidence

The 14 October full T2 batch snapshot used the verified S1 executable without rebuilding. It requested one MPI process, one DCU, 18 CPUs, 64 GiB host memory and a 45-minute limit on `f11r2n10`; the solver used one OpenMP thread. Script SHA256 was `5ab397d022815105a635b6479c305f9039d2e89d86daa1d18f2e162fa6d60d72`. The transferred script passed its checksum check.

The first [submission receipt](../logs/2026-10-14/plan-execution/t2-full-first-submission-rejection.json) rejected 64 GiB with four requested CPUs because the partition's `DefMemPerCPU` is 3800 MiB. Eighteen requested CPUs cover that ratio. The [corrected submission](../logs/2026-10-14/plan-execution/t2-full-second-submission-rejection.log) was then rejected with `Invalid account or account/partition combination specified`. Neither submission created a job or consumed allocated time.

The [live access summary](../logs/2026-10-14/plan-execution/scnet-partition-access-summary.json) records default account `ac3k88uz8y`, its `cluster_zz_2` association with `hx1hdnormal`, and the partition's UP state. The [exact membership query](../logs/2026-10-14/plan-execution/scnet-own-account-membership-user.log) returns `DIRECTLY_LISTED_IN_ALLOWACCOUNTS=0`. These records establish the 14 October submission/access problem; effective account inheritance and its cause remained unverified at that checkpoint.

## Gates recorded at the 14 October checkpoint

The 14 October allocation ledger records fourteen completed GPU allocations totalling **1,044 seconds**, including **1,029 integration seconds**. Job 953826 subsequently added 116 seconds, the 23 October comparison adds 208 seconds, and final-source validation 962050 adds 98 seconds, bringing the cumulative total to 1466 seconds. The [23 October result](T2_HIP_OPTIMIZATION_2026-10-23.md) records the new optimization and its acceptance scope.

The [14 October official-source checks](../logs/2026-10-14/plan-execution/official-interface-check.json) confirm all six inspected public files are byte-identical to the 9 October receipts, and the README still matches the saved version. The public GPU driver separates transfer timing; its memory helper reports tracked allocations and sampled observed usage. HIP entry admissibility, the actual formal launcher/package, CPU timing-unit labeling and independent teammate evidence remain open. The [updated contract sheet](SUBMISSION_CANDIDATE_2026-10-03.md) includes the [official conference page's](https://solver-conference.cn/solver26/index.html) 30 October 24:00 submission time; portal timezone and receipt details still require confirmation. The [14 October LX2 record](华为平台接入进度.md) supplies backend `152.11.26.76`, user `travissun`, queue `challenge26` and data path `/fs_real_a800/home/challenge26`. Backend SSH login is verified at the `node76` prompt, and the user completed initial password change. Donau CLI authentication failed three times; the default CMake is unusable for this source. Queue authorization, data contents, a usable native toolchain and allocated workloads remain unverified.

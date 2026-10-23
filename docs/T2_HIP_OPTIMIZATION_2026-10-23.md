# T2-low HIP smoother comparison

Date: 23 October 2026, Asia/Shanghai. Job **961898** completed `0:0` on `f11r1n07`, from **13:41:54 to 13:45:22**, with **208 allocated seconds**, one Hygon DCU, 16 CPUs and 58 GiB. The accepted relax-6 binary and an l1-Jacobi candidate ran sequentially in this same allocation. Each used one MPI process and one OpenMP thread.

| Full original T2-low | Relax 6 | l1-Jacobi 18 |
| --- | ---: | ---: |
| Driver five-round mean (s) | 12.739078 | **6.809676** |
| GMRES iterations in each round | 13 | 25 |
| Original-system float128 relative residual after five rounds | 5.938952e-7 | 5.894610e-7 |
| Mean analyse callback (s) | 0.059512 | 0.058157 |
| Mean preparation callback (s) | 5.716966 | 5.739199 |
| Mean solve and cleanup callback (s) | 6.950637 | 1.000135 |
| Full-process host peak RSS (KiB) | 5,629,368 | 5,628,356 |
| Maximum observed GPU phase sample (GiB) | 21.90 | 15.28 |

l1-Jacobi reduces the measured GPU mean by **46.545%**, a **1.871× speedup**. The improvement comes from solve and cleanup despite the higher iteration count. Preparation now dominates the measured callbacks. These are prototype-inclusive driver means: the implementation includes preparation, migration, diagnostics and cleanup. Callback sums have a separate scope. GPU memory values are rounded phase samples, with 63.98 GiB reported capacity.

The experiment changes only general AMG relaxation from 6 to 18; coarse relaxation remains 6. GPU support for l1-Jacobi is documented and implemented in the pinned HYPRE 2.33.0 source. The accepted baseline executable, HYPRE library and original matrix/RHS hashes are checked in the batch. All 89 manifest entries are retained; only the solver entry changes. Candidate solver SHA256: `4e08cf8c7fd6892943fffb17f393ce175a4d7714ad1ee98acf8d3584bb9854ca`; executable SHA256: `cc57db80775153d69ffb32ee4bf15f648bc3ec817862ed7fa1e1b66b5d8dfe00`.

Both variants pass Poisson, nonsymmetric and Neumann known systems, five complete solves each, followed by five complete original T2-low solves: **40 solves total**. Small-system original float128 residuals are below `1e-10`; the largest known-solution error is `1.249001e-16`. Full runs use default projection and internal tolerance `1e-7`, with all internal solves converged and original-system checks below `1e-6`. Every configuration has five device-policy records, five complete phase records and zero process exits. HYPRE is HIP/GPU enabled with unified memory disabled. Host RSS fits the actual grant.

[Verification and identities](../logs/2026-10-23/resource-optimization/gpu-relax18-verification.json), [accounting](../logs/2026-10-23/resource-optimization/gpu-relax18/relax18-961898-accounting.log), [batch output](../logs/2026-10-23/resource-optimization/gpu-relax18/sc26_t2_relax18-961898.out), [submitted batch](../logs/2026-10-23/resource-optimization/gpu-relax18/relax18-961898/submitted.sbatch) and [individual records](../logs/2026-10-23/resource-optimization/gpu-relax18/relax18-961898/) retain the evidence. The retrieved archive matches remote SHA256 `2ee31f257963cb06053ac9b140da0b73b490c2bea204467506f5562912f79302`.

The [fresh CPU controls](T2_CPU_CONTROLS_2026-10-23.md) give 7.126864 s at 96 ranks. The initial l1-Jacobi mean is 4.451% lower. This triggers the approved smaller-advantage repeat criterion. S4 remains inconclusive: the existing driver records outer means, while callback phase sums do not establish individual outer-round ranges. Final platform selection still requires the permitted CPU configuration and formal HIP entry/timing eligibility by the 24 October gate. The frozen CPU delivery remains the provisional primary submission path.

The current source selects l1-Jacobi in the existing HIP branch and relaxation 6 in the CPU branch. The new [89-entry source snapshot](../deliverables/SC26_T2_HIP_source_20261023.tar.gz) passes exact-source validation on both paths:

| Validation | Job and allocation | Result |
| --- | --- | --- |
| Final HIP source | `962050`, `f11r1n17`, 98 seconds, one DCU / 16 CPUs / 58 GiB | 3 known systems × 5 solves plus 5 full solves pass; full mean **6.860954 s**, original residual **5.894610e-7**, 25 iterations per round, host peak **5,634,960 KiB**, GPU phase samples up to **15.28 GiB**. |
| HIP-off CPU regression | `9270600`, `c3n37`, 152 seconds, 4 CPUs / 16 GiB | 3 known systems × 1 and 4 MPI ranks × 5 solves pass; maximum original residual **4.340013e-12**, maximum known-solution error **1.249001e-16**. |

Both jobs completed `0:0`. [Final GPU verification](../logs/2026-10-23/resource-optimization/gpu-final-verification.json) binds the current solver and all 89 manifest entries to the allocated build, binary, runtime and [final accounting](../logs/2026-10-23/resource-optimization/gpu-final-962050-accounting-user.log). That accounting row came from the human's follow-up `sacct` query; the archive's immediate post-wait accounting still reported RUNNING. [CPU regression verification](../logs/2026-10-23/resource-optimization/cpu-final-verification.json) retains the same source identity, exact archive check and raw records. Captured CPU module/locale, tar timestamp and OpenMPI device warnings accompany successful launchers, checkers and scheduler completion.

Source SHA256: `e432e915f9a4193435a5710f512202c570796d49e4e6ef31bb8b82694cc1c612`; manifest SHA256: `0b05a5bda03bc4d2f8045729307e94f15481b80a2ae12dc53ec7bf057ef3c25f`; archive SHA256: `b777cb575305cb12a15488a761532784670d1b68d8ed139c55e55f89db4a5625`. The [source identity](../logs/2026-10-23/resource-optimization/source-identity.json) records parent commit `84fa8b6` and 91 archive members. The original CPU and 9 October HIP archives retain their identities and dated acceptance.

The final GPU mean also remains below the fresh 96-rank CPU mean, but S4 stays inconclusive under the individual outer-round range requirement. This phase completes **110 solves** across CPU controls, GPU comparison, final HIP validation and CPU regression. The [allocation ledger](../logs/2026-10-23/resource-optimization/allocation-ledger.json) adds **306 GPU seconds** and **600 commercial CPU single-node seconds**, bringing cumulative GPU allocation to **1466 seconds**. [LX2 readiness](华为平台接入进度.md) still requires scheduler credentials, trusted ingress, native dependencies and the permitted evidence arrangement.

The next performance investigation is preparation, which dominates the current GPU callbacks. The delivery gates remain formal launcher/entry/timing confirmation and genuine teammate reproduction by 24 October, followed by the 25 October freeze. The source change and its measured GPU improvement are accepted within the numerical evidence above; the final submission platform awaits S4 and formal eligibility.

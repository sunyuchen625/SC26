# SolverChallenge26 project audit

Date: 30 September 2026. Reviewer: Claude Code, Claude Sonnet 5.5, max effort. Evidence reconciliation: Codex.

This report integrates the independent review with local verification of its material claims. Source paths beginning with `apps/`, `src/` or `problems/` are relative to `资料/solverchallenge26_sample_code/`; other paths are relative to the project root.

**Scope.** This is a read-only review of the current working tree. I read the framework drivers, loader and diagnostics, both solver sources, CMake, every sbatch and test script, and `tests/check_result.py`. I also read the saved official page (`logs/2026-09-23/official-page.html`) and raw logs: all 20 T8/T10 and 10 T9 right-hand-side (RHS) logs, plus the full-scale T1–T7 logs. Nothing was run. Binaries and large inputs are remote. The reviewer did not run Git commands. Codex subsequently verified that the current solver source, scripts and tests have no diff against implementation commit `3970942`. I did not touch private application files, credentials or remote sources.

Evidence labels: **D** is demonstrated by cited local evidence, **I** is my inference, **U** is unknown locally.

**Prior review scope.**

- The 23 Sep Grok review covered commit a116859 and docs 01d24d6, meaning T1/T2/T3/T6 (`docs/reviews/校验记录_2026-09-23.md:5,21`).
- The T4/T9 wiring, T5/T7 MGR, the T8 max-abs metric and the T10 `pardiso_64` row-sorting path had no independent review.
- Its line citations no longer match the file. Scaling is now at `problems/cpu_baseline/solver.c:219-245`, non-convergence handling at `:342-348`, and the one-rank guard at `:42-49`.
- It recommended a clean-clone rebuild (`.agents/collaboration/2026-09-23-grok-review/grok.md:49`). None is recorded.

## Overall assessment

- **D:** 7 of 12 scored items (T2-low, T5–T10) pass the framework's float128 check. The brief's figures match the raw logs. T1 (both tiers), T2-high, T3 and T4 are unresolved.
- **Official scoring eligibility is the highest-priority risk.**
  - T10 explicitly enables value-dependent operations in its analysis phase, conflicting with the saved structure-only analysis rule. The other direct paths need their library defaults checked.
  - The 10-RHS invocation and timing model is unknown.
  - The passing settings live in environment variables and scripts.
- T5 is a thin pass from a run that never converged internally. The current T2-high method reaches the observed compatibility floor; general infeasibility has not been established. T1/T3/T4 have had only one to three attempts each.
- A few written organizer answers gate most engineering choices.

## Numerical pass versus internal convergence

| Item | Original-system float128 result | Internal solver state |
|---|---|---|
| T2-low | 5.894e-7 < 1e-6 (41% margin) | Converged in 15 iterations; 5.867e-7 is the observed compatibility floor in this method (finding 5) |
| T2-high | 5.867e-7, fails 1e-10 | Converged in 21 iterations |
| T5 (MGR) | 9.732e-9 < 1e-8 (2.7% margin) | **Not converged:** 300-iteration cap, scaled residual 1.83e-8 vs requested 1e-12 |
| T7 | 1.78e-9 (ILU), 4.09e-10 (MGR) | Converged in 42 and 11 iterations |
| T6/T8/T9/T10 | ≤1.8e-12; 3.66e-16 (max-abs); ≤1.05e-15; ≤7.41e-15 | Direct; zero perturbed pivots; refinement always uses all 4 steps |
| T1 / T4 | 1.1e3 / 0.115, fail | Stalled at cap: scaled 0.215 / 0.345 |
| T3 | 2.74e-5, fail | Direct factorization fine; refinement stalled |

## Findings, ranked

### 1. Critical: direct analysis must be reconciled with the structure-only rule

- **D:** The organizers define direct-method analysis as structure-only. They say PARDISO phase 11 "can accept matrix values… not allowed in this competition" (`logs/2026-09-23/official-page.html:254`).
- **D:** Every direct path passes the numeric array into phase 11 (`problems/cpu_baseline/solver.c:73-84,109`). Passing a pointer establishes availability; the enabled operations determine whether analysis actually depends on values.
  - T10 sets scaling and matching explicitly (`:56-57`).
  - The others rely on `pardisoinit` (`:67`). **U:** Their installed MKL defaults were not established by local evidence in this audit. The reviewer recalled value-dependent defaults for unsymmetric types; that recollection is a hypothesis to verify.
- **D:** The project's own report concedes the "analyse" field includes matching and scaling (`docs/baselines/初步阶段扩展基线_2026-09-23.md:29`).
- **D:** That phase is 54% (T6), 87% (T9), 90% (T8) and 92% (T10) of the measured time. Sources are `logs/2026-09-23/runs/t06-direct-9188190/solver.log:5-8`, `logs/2026-09-23/t4-t9/runs/t09-direct-9188209/rhs-01/solver.log:5-8` and `logs/2026-09-26/stage2/all-rhs-validation_2026-09-30.log:3,23`.
- **U:** Whether and how the portal enforces this, and whether stages are timed or reused separately.
- **Effect:** T10 has a demonstrated conflict with the saved analysis-stage restriction. The compliance of the other direct baselines remains conditional on their actual options and the official evaluation interface.
- **I:** A value-free analysis may raise fill or perturbed pivots. T6 and T9 factors are already at 93% and 87% of the 32-bit limit (2,002,635,810 and 1,870,948,576 vs 2,147,483,647; `logs/2026-09-23/runs/t06-direct-9188190/solver.log:5`, `logs/2026-09-23/t4-t9/runs/t09-direct-9188209/rhs-01/solver.log:5`). The 64-bit interface exists only for T10 (`problems/cpu_baseline/solver.c:23-27,52-65`, `problems/cpu_baseline/solver.h:14-16`), so extra fill could break them.
- **Smallest check:** Ask the organizers how phase 11 is checked. Then rerun T9 (74 s) and T6 (35 s) with value-dependent options off, using the existing iparm settings around `problems/cpu_baseline/solver.c:69-72`. Compare perturbed pivots, factor nnz, residual and time.

### 2. Critical: multi-RHS completion is proven, the scoring model is not

- **D (completion):** All 10 RHS of T8, T9 and T10 pass independently.
  - I re-read the 20 T8/T10 logs. Each has five `perturbed_pivots=0` lines, there are no nonzero counts anywhere in `logs/**/solver.log`, and all 20 `process.time` files show `Exit status: 0`.
  - The residuals and times match `logs/2026-09-26/stage2/all-rhs-validation_2026-09-30.log:1-43`.
  - The ten T9 raw logs give ≤1.045516e-15, 73.41–75.03 s, and process peaks ≤38,015,324,160 B (<100 GB).
- **D (what was measured):** The driver takes one RHS file per process and repeats the full callback set five times (`apps/MPI_direct_solver.c:54-55,152-173`). Analysis is therefore repeated per RHS. T10 sums to 1,984.0 s (`logs/2026-09-26/stage2/all-rhs-validation_2026-09-30.log:43`).
- **U:** The official page says only "10 RHS" (`logs/2026-09-23/official-page.html:691,747,807`) and defines the solve stage as "input b, get x" (`:258,267`). It does not say how RHS are presented, whether reuse is allowed, or how times combine.
- **I:** With analysis and factorization reused, T10 would take about 183 + 11 + 10×4.6 ≈ 239 s, not 1,984 s. The score is (Tmin/Tself)(10−x)+x with x=1 (`:137`), so 2× the best time earns 5.5 points and 10× earns 1.9.
- **Smallest check:** Get the invocation and reuse rule in writing before engineering. Keep the per-RHS results as the fallback. Reuse also depends on finding 1.

### 3. High: validated configurations live outside the source defaults

- **D:** `SC26_RTOL` defaults to 1e-11 (`problems/cpu_baseline/solver.c:184-193`). The iterative trials used 1e-12 for T3–T7 (`scripts/initial-baseline.sbatch:22-24`). T2 tiers use 1e-7 and 5e-11 (`scripts/t2-baseline.sbatch:24-26`).
- **D:** T2 needs `SC26_PROJECT_CONSTANT=1` (`scripts/t2-baseline.sbatch:17`). It is off by default (`problems/problem02/solver.c:92-94`). The notes record stagnation near 1.9e-4 without it (`.agents/任务进度.md:28`). T2 aborts on non-convergence (`problems/problem02/solver.c:146-157`), so a bare run yields no answer.
- **D:** T5/T7 MGR is a separate CMake build (`problems/cpu_baseline/CMakeLists.txt:6-12`). The plain T5 build fails at 2.6e-3.
- **D:** Ranks and threads come from scripts: 96, 32 or 8 ranks, plus MKL thread variables (`scripts/stage2-complex.sbatch:18-19`). The PARDISO path aborts unless there is exactly one rank (`problems/cpu_baseline/solver.c:42-49`). The reference README shows `mpirun -np 2` for the direct driver (`资料/solverchallenge26_sample_code/README.md:95`).
- **Effect:** A build from the repo without the scripts does not reproduce the passes. There is no mechanism to select T1/T2 tiers other than environment variables.
- **Smallest check:** Once the interface is known, run each passing problem with the exact official-style command and no extra environment. Use small systems first, then one full-scale run each for T2-low and T5.

### 4. High: T5 is a thin pass, not a converged solve

- **D:** The original relative residual is 9.732279e-9, which is 2.68% under the limit. Only one full-scale job (9193138) exists. All five repetitions hit the 300-iteration cap with the same printed scaled residual of 1.832383e-8 (`logs/2026-09-26/stage2/runs/t05-9193138/1e-12/solver.log:313,623,933,1243,1553`).
- **D:** The residual was still falling 6–11% per iteration at the cap (same file, `:299-310`).
- **D:** The solver monitors the scaled system (scaled ‖b‖=1835, original ‖b‖≈90). The original-to-scaled ratio is 0.53 here but 2,121 for T7-ILU (`logs/2026-09-26/stage2/runs/t07-9193129/1e-12/solver.log:59,296`). The pass is a property of this particular iterate.
- **U:** Sensitivity to node, rank count, partition and reduction order.
- **Smallest check:**
  - Repeat the job on another node and with another rank count.
  - Measure a higher iteration cap. About 26 s per 50 iterations, from 157 s over 300.
  - Keep 9193138 as the fallback.

### 5. High: T2-high is limited by compatibility in the tested method

- **D:** The high-tier original residual equals the b constant-component ratio to all printed digits, 5.867434e-7 (`logs/2026-09-22/t2/runs/t2-9187935/5e-11/solver.log:196`, `docs/baselines/T2数值基线_2026-09-22.md:44`).
- **D:** For the low tier, √((5.894250e-7)² − (5.867434e-7)²) ≈ 5.6e-8. That matches the reported projected internal residual, 5.616e-8 (`logs/2026-09-22/t2/runs/t2-9187890/1e-7/solver.log:33`). The measurements are consistent with an original residual of √(floor² + internal²), and the floor takes 59% of the low-tier threshold.
- **I:** With the measured ‖Aᵀ1‖ ≈ 6.94e-19 (report `:41`), cancelling ⟨1,b⟩ ≈ 7.27e-7 requires a solution 2-norm on the order of 1e12, by Cauchy–Schwarz. That suggests a severe accuracy problem. It does not prove that no double precision solution can meet the original 1e-10 check.
- **Effect:** Tighter tolerances in the current projected method have not removed the original residual floor. The stored matrix has a near nullspace, rather than a proved exact left nullspace; the feasibility of a different method or evaluation convention remains unresolved.
- **Smallest check:** The T2 report's own next step (`:135`) is to ask the organizers about the nullspace convention. No local record shows this was done. Send them sum(b), ‖Aᵀ1‖ and the two residuals.

### 6. Medium–High: T1, T3 and T4 had few attempts, and evidence points to structure

- **T1.**
  - **D:** One configuration (GMRES(30)+BoomerAMG with DAD scaling) stagnated completely, with convergence rate 1.0000 at iterations 275–300 (`logs/2026-09-23/runs/t01-9188182/1e-8/solver.log:285-310`).
  - **D:** The row dump shows why. Row 0 has diagonal 936.76, cross-variable coupling −926.76 and spatial couplings near 1e-6. Row 1 has ±9.94e9 x-couplings against ~1e-6 in y/z. The last row has 3.3e11 couplings (`logs/2026-09-23/remote-logs/t01-blocks-9188191.out:37-84,167-188`).
  - **D:** `NumFunctions` is not used for T1 (`problems/cpu_baseline/solver.c:315-317`).
  - **I:** Generic AMG is ignoring the three-block, anisotropic, near-cancelling structure. A variable-aware or structured-grid approach is a hypothesis from general HYPRE knowledge to test, tier 1 (1e-4) first.
  - **D:** The reference framework reported 5,208.6 MB (numerically MiB on this Linux platform) against the 9 GB limit (`logs/2026-09-23/runs/t01-9188182/1e-8/solver.log:1555`).
  - **I:** Each rank allocates a global scale vector (`problems/cpu_baseline/solver.c:220`), 50 MB per rank at n=6.29M. At 96 ranks that is about 4.8 GB, which probably forced the 8-rank choice.
- **T3.**
  - **D:** Factorization is healthy. There are zero perturbed pivots, 1.02e9 factor nnz and 16.4 GiB (`logs/2026-09-23/runs/t03-direct-9188194/solver.log:5-7,25`).
  - **D:** Refinement stalls: 5.92e-5 after 4 double steps against 2.74e-5 after 8 extended steps (`:36`; `logs/2026-09-23/runs/t03-direct-9188189/solver.log:36`). The diagonal reaches 1e30 (`logs/2026-09-23/remote-logs/inspect-t03.json:92-95`).
  - **I:** This is not a pivoting breakdown. A representation floor (large |A||x| against ‖b‖=0.032, `logs/2026-09-23/remote-logs/inspect-t03.json:104`) and an ill-conditioned penalty structure both fit. The 6-decimal answer file cannot distinguish them.
  - **Smallest check:** A per-step refinement trace, plus ‖x‖∞ and ‖|A||x|‖∞ relative to ‖b‖. This needs a one-off diagnostic dump. T3 is the most tractable unsolved item.
- **T4.**
  - **D:** One full configuration gave scaled residual 0.3446, identical in all repetitions (`logs/2026-09-23/t4-t9/runs/t04-9188218/1e-12/solver.log:313`).
  - **D:** 12.52M rows have 54 nnz and six rows have 5,046 (`logs/2026-09-23/t4-t9/inspect-t04.json:5-12`).
  - **U:** Whether the dof ordering is interleaved, which `NumFunctions(3)` assumes.
  - **Smallest check:** Obtain a T4 phase-11 memory estimate before scheduling full factorization. The current `MPI_direct_solver` continues into factorization if its estimate is below the 400 GiB experiment budget (`problems/cpu_baseline/solver.c:111-136`); it is not an analysis-only probe. **U:** The T4 direct memory estimate is not recorded.

### 7. Medium: platform, allowance, deliverables, schedule

- **D:** Final scores come from competition-provided platforms, and usage time is limited (`logs/2026-09-23/official-page.html:104`). The page lists three platforms and single-node use (`:107-110`).
- **D:** The local evidence covers only the commercial CPU. Domestic CPU access is at 401 (`docs/华为平台接入进度.md:5`). The DCU has no region (`docs/算力申请与使用方案.md:13`).
- **U:** Which platform scores which problem, whether all three are required, and the CPU allowance.
- **I:** The 22 stage-2 jobs alone used about 341 node-minutes (my sum of `logs/2026-09-26/stage2/jobs.log`).
- **D:** The portal takes an executable interface, and closed-source submissions need "link files" (`:101`). Scoring considers package autonomy and innovation (`:111`). A technical report is required (`:115-122`). The template exists (`资料/solverchallenge26_sample_code/SolverChallenge26报告模板.docx`, not opened). No draft or package is evidenced.
- **D:** "24:00" on the saved page belongs to the registration deadline (`:204-205`). The submission-close row shows only "10月30日" (`:183-185`). The current project plan and English brief now record 30 October, with the exact closing time to be confirmed.

### 8. Medium: reproducibility, validation boundaries, hygiene

- **D:** No teammate run and no clean-clone run are recorded.
- **D:** Scripts hardcode account and paths (`scripts/initial-baseline.sbatch:4,10,18,27`).
- **D:** The official README requires MPICH (`资料/solverchallenge26_sample_code/README.md:27-29`). Validation used OpenMPI 4.1.8.
- **D:** Binary SHA-256 values are in the batch stdout and consistent across jobs (for example T10 `ae8668b9…` in `logs/2026-09-26/stage2/batch/sc26_stage2_complex-9193147.out:27`). Stage 2 ties binaries to source only through the commit hash (`logs/2026-09-26/stage2/source/code-commit.txt`).
- **D:** CTest contains only header checks (`资料/solverchallenge26_sample_code/CMakeLists.txt:153-166`). A completed driver returns 0 even when its printed residual fails acceptance (`apps/MPI_direct_solver.c:272-302`); the external result checker supplies the numerical failure status.
- **D:** `tests/check_result.py:19-22` checks one float128 line and five solves. It does not itself validate `converged=`, pivots, exit code, memory or time. The archived 30 September wrapper, `logs/2026-09-26/stage2/source/verify_all_rhs.py:8-20`, additionally checks all T8/T10 RHS for completed job status, process exit 0, five zero-pivot records and complete stage records. Internal convergence is reported separately from acceptance of the original system.
- **D:** The initial known-solution generator uses 385 unknowns; full-scale conditioning is not represented by those cases (`tests/make_small_systems.py:7-24`).
- **D:** The page publishes one MD5 per problem (for example `logs/2026-09-23/official-page.html:687`). No comparison with those published hashes is recorded. **U:** The exact download object covered by each MD5 is not identified locally; it must be established before comparing it with individual matrix or RHS files.
- **D:** Existing project documentation contains team contact information, and `资料/资源申请/` contains personal application originals. Personal undertaking originals and the application receipt are retained locally and excluded from Git tracking. The official access guide is included in the repository. Team contact details remain part of the private project documentation.

### 9. Medium: performance bottlenecks

- **D:** T2 spends 85% of its time in AMG setup (17.2–18.7 s of 20.9 s, `logs/2026-09-22/t2/runs/t2-9187890/1e-7/solver.log:34,64,94,124,154`). It ran at 32 ranks only (`scripts/t2-baseline.sbatch:6`).
- **D:** T5 spends 157 s of 167 s in 300 iterations.
- **D:** T8/T9/T10/T6 are analysis-bound (finding 1). Ordering is sequential METIS (`problems/cpu_baseline/solver.c:69`). Hypothesis from MKL documentation, to verify: parallel nested dissection and value-free ordering.
- **I:** T7's tolerance of 1e-12 looks tighter than the 1e-6 requirement needs. This is low priority.
- **U:** No competitor baseline exists locally, so competitiveness is unknown. The prior-year best reports are external links I did not assess.

### 10. Low

- `src/diagnostics.c:74` says "averaged over 10 runs", but all drivers use 5 (`apps/MPI_direct_solver.c:38`). The portal supplies its own timing (`logs/2026-09-23/official-page.html:101`), so its repetition count is unknown.
- T2 aborts on any HYPRE error, while `cpu_baseline` tolerates non-convergence (`problems/problem02/solver.c:41-47` vs `problems/cpu_baseline/solver.c:342-348`).
- Every `cpu_baseline` build requires MKL (`problems/cpu_baseline/CMakeLists.txt:13-16`).

## Feasibility through 30 Oct

- **D:** About 30 days remain. Internal targets are 25 Oct for the main deliverable and 29 Oct for verification.
- **I:**
  - A scorable submission of the seven passing items is achievable if the interface answers arrive within days.
  - T3 is plausible and T1 tier 1 is possible. T4 is doubtful and T2-high is unlikely.
  - Broad GPU or domestic-CPU coverage is unrealistic without access.
- **U:** The node-hour allowance.

## Prioritized work plan

1. **This week:** send one written query to the organizers' contact. Ask about:
   - the submission interface and launch (ranks, environment, tier selection)
   - the 10-RHS model and reuse legality
   - phase-11 enforcement
   - the T2 nullspace convention
   - the scoring platform(s) and allowance
   - the exact close time

   The unsent draft (`docs/回复毛润彰_待审核_2026-09-25.md`) covers only domestic-CPU onboarding.
2. Make the validated settings the source defaults. Prove each with a no-environment acceptance run.
3. Run the phase-11 probe on T9 and T6. Decide the direct-solver strategy, and keep the current results as the fallback.
4. Test T5's margin on a second node and rank count, and measure a higher iteration cap.
5. Run the T3 diagnostic, the T4 direct-estimate probe and a T1 tier-1 structure-aware trial. Hold T2-high tuning until the organizers reply.
6. Have a teammate do a clean-clone reproduction of the passing set. Check MPICH if the portal uses it. Identify the published MD5 targets and compare the corresponding objects.
7. Draft the technical report from the template, and the package once the interface is known. Decide which team contacts and application originals belong in any externally shared package.
8. Defer HIP/DCU work and the T7/T2 micro-tuning until items 1–5 are settled.

## Coordinator verification

The seven passing items are local numerical acceptance results. No accepted submission or official score is evidenced. The driver checks the original system after the fifth solve; five completion markers do not constitute five separately checked residuals. MPI memory summaries sum each rank’s historical peak, and GNU time covers the complete process. These boundaries are retained in the English brief and baseline reports.

Codex verified source equivalence with `git diff --quiet 3970942 -- 资料/solverchallenge26_sample_code scripts tests` (exit 0), reconciled the T2 infeasibility claim with the measured near nullspace, checked the direct-stage options and T4 control flow, and corrected the deadline wording against the saved official page. The original two English responses and session metadata are retained in `.agents/collaboration/2026-09-30-claude-audit/`. The review used only local Read, Glob and Grep tools. Both turns completed in the same session; the final refreshed subscription session usage was 37%, below the 95% pause threshold.

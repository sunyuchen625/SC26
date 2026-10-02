# SolverChallenge26 remediation and execution plan

Date: 1 October 2026, Asia/Shanghai. Prepared by Claude Code, Claude Opus 5.5, max effort; reviewed and integrated by Codex.

Status: approved by the user on 1 October 2026 for execution in a new Codex session using GPT-6.1 Sol with max effort. Completed work will be audited by Claude Code before Codex pushes it to GitHub. The numerical implementation is unchanged at the time of approval.

Resource basis: [Compute status, 1 October](COMPUTE_STATUS_2026-10-01.md). Audit basis: [Independent audit, 30 September](reviews/CLAUDE_AUDIT_2026-09-30.md).

**Labels.** **[C]** means shown by local code or logs. **[H]** means a hypothesis that needs an experiment. **[O]** means it depends on the organizers or their interface. `SC/` stands for `资料/solverchallenge26_sample_code/`. Unqualified `solver.c` and `solver.h` refer to `SC/problems/cpu_baseline/`; short script names refer to `scripts/`.

**Planning assumptions:**
- The LX2 (Huawei domestic CPU) window runs from confirmed recovery to 30 October; its length is unknown.
- The DTK module label and the version hipcc reports are recorded separately. No environment fault is assumed.
- Every build runs inside an allocated batch job, as `scripts/stage2-small.sbatch:26-28` already does.
- The 1 October infrastructure facts are evidence from the thread and documents, not archived raw traces. The user’s approval authorizes probes and execution within the budgets and decision gates below.

**Ground rules for every package:**
- Existing logs and binaries stay untouched. New builds go in new build directories and new dated log directories.
- Implementation commit `3970942` remains the fallback reference.
- Only organizer machines are used, nothing runs on login nodes, and at most two single-node commercial CPU jobs run at once.

## 1. Numerical pass is not official eligibility

"Numerical pass" means the local float128 check on the original system. No accepted submission or official score is evidenced locally.

| Item | Numerical pass [C] | What still blocks eligibility |
|---|---|---|
| T10 (10 right-hand sides) | ≤7.41e-15 | **[C] Conflicts with the saved structure-only analysis rule.** `solver.c:56-57` turns on scaling and matching. The full-scale log prints "Scaling is turned ON / Matching is turned ON" and 37.66 s of matching/scaling inside PARDISO phase 11 (`logs/2026-09-26/stage2/runs/t10-direct-9193327/rhs-03/solver.log:12-13,26`). How the 10 right-hand sides are run is [O]. |
| T6, T8, T9 | 1.8e-12; 3.66e-16 (max-abs); ≤1.05e-15 | [C] Numerical matrix coefficients go into phase 11 (`solver.c:73-84,109`) under the library defaults (`:67`). Message level is 0 (`:30`), so the logs don't show whether scaling or matching ran. Compliance is therefore conditional. |
| T2 lower tier | 5.894e-7 | [C] The recorded lower-tier pass uses `SC26_PROJECT_CONSTANT=1` and `SC26_RTOL=1e-7` set by the script (`scripts/t2-baseline.sbatch:17,24-26`). How tiers are submitted is [O]. |
| T5 | 9.732e-9 (2.7% margin) | [C] Needs a separate build option (`SC/problems/cpu_baseline/CMakeLists.txt:6-12`). The solver never converged internally, and there is only one full-scale job. |
| T7 | 1.78e-9 | [C] Its tolerance comes from an environment variable. |
| All | — | [O] Submission interface, launch command (ranks, threads, MPI), timing boundaries and allowance. The official README requires MPICH (`SC/README.md:27-33`); our validation used OpenMPI. |

Relevant rules from the saved official page:
- Direct-method analysis must use structure only. It explicitly says PARDISO phase 11 can accept values but that is "not allowed" in this competition (`logs/2026-09-23/official-page.html:254`).
- Reading, format conversion, distribution, coordinate sorting and CPU–GPU transfer are not timed (`:244`).
- The competition site supplies input, output and timing, and accepts submitted execution code (`:101`).

## 2. Fixes for the completed work

### R1: Make direct-solver analysis structure-only (T10 first; T3, T6, T8, T9 share the code)

**Purpose:** eliminate value-dependent work from PARDISO phase 11, then revalidate each direct result under the structure-only rule.

**Files:** `SC/problems/cpu_baseline/solver.c` (`pardiso_phase`, `prepare_direct`, `factor_direct`), `solver.h` if index width changes become necessary, and the existing direct/complex baseline and small-case scripts.

**Minimal candidate:** explicitly set `iparm[10]=0` and `iparm[12]=0` for every direct problem, record the installed defaults and effective settings, and enable diagnostic library output for the probes. Retain the existing CSR representation, complex conversion and paired column/value sorting. Passing a values pointer is distinct from performing numerical operations during analysis; the installed library behaviour and organizer interpretation must be established by the probe and Q2.

**Experiments:**
- **E1a:** existing real, complex and unsorted-complex known-solution cases.
- **E1b:** one full-scale RHS each, in order T9 → T6 → T8 → T10. The probes test residuals, memory, factor sizes and actual phase behaviour.
- **E1c:** rerun all ten RHS of T8/T9/T10 once a final candidate is selected. Use the agreed multi-RHS invocation if known; otherwise retain the current per-RHS accounting without claiming official scoring.

**Conditional numerical follow-up:** if disabling value-dependent operations harms accuracy, test explicit diagonal equilibration in the numerical preparation stage, with corresponding RHS/solution transforms and original-system validation. If T6/T9 encounter the actual 32-bit factor-index limit, extend the existing 64-bit path to the affected problem. Both decisions depend on observed probe results and remain hypotheses until tested.

**Acceptance:** the correct original float128 metric is below threshold (T8 maximum absolute <1e-8; others relative <1e-8); five solves complete; process exit 0 and a new standalone job completes 0:0; effective options and phase diagnostics support structure-only analysis; T9 full-process peak stays <100 GB. Record perturbed pivots, factor nnz, timing, exact source/configuration and binary identity. Nonzero perturbed pivots are diagnostic evidence, not an additional official accuracy rule.

**Resources:** approximately 0.2 commercial CPU node-hours for E1a, 1 for E1b and 6–7 for E1c, using one node per job. These estimates use September whole-process timings; changed ordering may change both runtime and memory. Start with the probes, and confirm allowance before the full rerun.

**Decision:** select a candidate only after the probes pass and its analysis behaviour is understood. Preserve September results as numerical evidence. Review T10's compliant numerical alternatives by 14 October; if none passes, resolve Q2 before claiming that result eligible.

### R2: Put the passing configuration in the existing implementation and package it for the actual interface

**Purpose:** the selected problem build should reproduce the passing full-scale configuration without undocumented `SC26_*` environment settings.

**Current facts [C]:** tolerance defaults to 1e-11; T2 projection defaults off; T5 requires the separate MGR build; direct methods require one MPI rank. The root CMake redirects most slots to `cpu_baseline`, while the framework documentation describes per-slot implementations. The portal's required package is still [O].

**Files:** existing `cpu_baseline/solver.c`, its `CMakeLists.txt`, `problem02/solver.c`, relevant launch scripts and the README.

**Minimal changes:** use per-problem defaults directly in those existing files: T2-low tolerance 1e-7 and projection enabled, T5 MGR as its selected default, T7 ILU(0) retained, and the chosen T5 tolerance/cap from R4. Keep existing experiment overrides and record the effective configuration. T2's small Poisson and nonsymmetric cases must retain their existing explicit projection-off setting; Neumann retains projection-on. The upper-tier configuration remains explicit until Q4/Q5 are resolved.

**Packaging:** determine the official source/binary/link-file layout, allowed ranks, MPI and tier selection from Q1/Q4 before adapting the package. Use the existing implementation at the required integration point. A rank-gather adaptation is conditional on an actual multi-rank launch requirement, not part of the first changes.

**Acceptance:** clean batch builds from identified source/configuration; full T2-low and T7 acceptance with experiment overrides absent. R4 validates T5 and R1 validates direct builds under the same configuration scheme. Preserve the original system, metrics and five-repeat contract.

**Resources:** about 0.3 additional CPU node-hours, plus the shared R1/R4 runs. Any difference from the scripted baselines is investigated before adopting the defaults.

### R3: Timing and reuse for the ten right-hand sides

**Current behaviour [C]:**
- Each run takes one right-hand-side file (`SC/apps/MPI_direct_solver.c:54-55`).
- All three stages repeat five times (`:38,152-173`).
- PARDISO is always called with one right-hand side (`solver.c:24-30`).
- The factorization is released inside the timed solve step (`solver.c:137-139`).
- T10 per repetition is about 183 s analysis, 11 s factorization and 4.6 s solve. The sum over ten right-hand sides is 1,984 s.

**Open [O]:** whether the ten right-hand sides arrive in one run, whether analysis and factorization may be reused across them, and how times are combined.

**Plan:**
- Keep the per-RHS path as the validated fallback.
- Describe factor-once, solve-many against the actual harness only after Q3 identifies a supported invocation. Implement and validate reuse only if that rule permits it.
- Don't reuse work across the five timing repetitions.

**Cost:** about one day of code. [H] T10 would take roughly 240 s for all ten instead of 1,984 s.

**Decision:** if there is no reply by 20 October, retain the existing per-RHS candidate and defer reuse. Formal submission still uses the confirmed portal interface.

### R4: T5 convergence margin

**Current behaviour [C]:**
- All five repetitions stop at the 300-iteration cap with scaled residual 1.832e-8 and `converged=0` (`logs/2026-09-26/stage2/runs/t05-9193138/1e-12/solver.log:313`).
- Over the last 20 iterations the residual still shrinks by a factor of 0.88–0.94 per iteration (`:290-310`).
- Each iteration takes about 0.52 s (`:314`). The run used 96 ranks.

**Experiment:**
- With the cap now a per-problem default (from R2), run to scaled tolerances of 5e-9 and 2e-9 with a cap of 450.
- Repeat on a second node and at 64 ranks.
- [H] At the observed rate, tens of extra iterations should be enough.

**Depends on:** the T5-specific tolerance/cap selection in the existing implementation (R2).

**Accept when:**
- The final original float128 residual of each complete job is ≤5e-9 (a proposed 2× engineering margin); the official requirement remains <1e-8.
- All five internal solver records report `converged=1`. The framework still checks the original residual after the fifth solve.
- Five solves complete with exit 0.
- The result holds on two nodes and two rank counts.
- For a comparable 96-rank run, target mean time no more than about 20% above 167.2 s. The 64-rank runs test robustness and have their own recorded timings.

**Cost:** about 1.5 node-hours.

**Decision:**
- If the margin is reached, adopt it as the default.
- If not, try at most two MGR variants [H].
- Otherwise keep job 9193138's configuration as a documented thin pass.

### R5: Repair reproduction and maintain one numerical acceptance path

**Purpose:** a teammate can rebuild and validate the passing configurations, and the saved evidence distinguishes numerical acceptance, internal convergence, process/job status, memory and timing.

**Coordinator-verified defect [C]:** `scripts/t2-small.sbatch:30-33` supplies a fifth positional argument `unique` for the Poisson and nonsymmetric cases. `tests/check_result.py:12` permits only the optional `constant-nullspace` token. The current caller therefore conflicts with the checker. Historical residual logs remain valid.

**Minimal fix:** omit the optional token for unique-solution systems, and supply `constant-nullspace` only for Neumann. Reuse the existing six T2 cases (three systems, one/four ranks) to validate the correction after approval.

**Files and evidence changes:** retain `tests/check_result.py` as the numerical checker. Maintain the existing archived multi-run verification logic in a small run-verification script, covering the actual T8/T9/T10 sets and recording process exits, job states, memory, phase counts and pivots. Extend existing job metadata to tie binary identity to the exact source/configuration used; retain documented account/path settings in the existing launch scripts.

**Validation boundaries:** a completed driver can return 0 despite a failed residual, so its printed original-system residual still controls numerical acceptance. Internal non-convergence is reported separately; it does not erase a historical T5 pass. The original residual is checked after the fifth solve, MPI memory sums rank peaks, GNU time covers the complete process, and six-decimal answer files do not replace the in-memory check.

**Reproduction:** a teammate follows the README for T2-low, T7, stable T5 and the selected T9 RHS01 candidate. Use the verified account unless a separate team account is actually available. If the portal requires MPICH, verify an installed module and run T2-low/T7 with it; otherwise retain OpenMPI evidence and resolve Q1.

**Acceptance:** the repaired caller passes all six existing cases; the maintained checker/verification path reproduces the recorded numerical verdicts, rejects a known failing residual and reports metadata boundaries correctly. Fresh runs record five solves, the correct metric, full-process exit/state, applicable T1/T9 memory limits and source/configuration provenance.

**Resources:** approximately 1.5–2 CPU node-hours including teammate/MPI reproduction. No numerical production change is needed for the documented five-versus-ten help-text discrepancy.

### R6: Bounded performance work (optional, after R1 and R2)

**Candidates:**
- **T10/T8 ordering:** T10's phase 11 spends 19.2 s building the symmetric pattern and 79.5 s in METIS reordering (`rhs-03/solver.log:21-22`). Test MKL's documented parallel nested-dissection setting for `iparm[1]` and thread placement, on right-hand side 01 only. [H] Confirm the setting against the installed MKL 2022.0 first.
- **T2:** AMG setup takes 85% of the time at 32 ranks; try 64 and 96 ranks and one setup variant.
- **T7:** try a looser internal tolerance while keeping at least 10× margin on the original check.

**Accept when:** the framework mean is at least 10% faster and all acceptance checks still pass.

**Cost:** at most 3 node-hours.

**Decision:** stop on 22 October.

### R7: Update audit statements that current files have superseded (documents only)

**Superseded:**
- Domestic CPU stuck at 401, and no DCU region (audit finding 7).
- The dated audit's GPU feasibility assessment must be read with the new allocated-resource evidence and the timeboxed GPU branch in section 4.
- Platform choice: now partly settled by the "fastest of three" statement.
- Personal application files: excluded by `.gitignore`; only the official guide is in the Git index.

**Still open:**
- Team contact details in the tracked `docs/算力申请与使用方案.md` §2. Decide before sharing anything externally.
- Stale lines at `docs/项目背景与下一步工作方案.md:21-22,64`.
- `docs/PROJECT_BRIEF.md` needs a "superseded" note on its compute section.
- The unsent domestic-CPU draft needs the current backend-connection/recovery questions. Section 6 contains the proposed combined organizer questions for user review.
- Current navigation and plans should point to the 1 October compute status; retain dated audit and experiment records as history.

**Accept when:** current-state entrypoints reflect the latest observations and clearly distinguish dated history.

## 3. Bounded work on the unsolved problems

**U1: T3**, the most tractable.
- **Situation:** the factorization is healthy, but refinement stalls at 2.74e-5 and diagonal entries reach 1e30.
- **Plan:** one diagnostic job logging each refinement step, ‖x‖∞ and ‖|A||x|‖∞/‖b‖. That separates a representation floor from ill-conditioning [H]. If it isn't a floor, try compliant preparation-stage scaling plus the PARDISO factor as a GMRES preconditioner on the original system [H].
- **Files:** `solver.c` (`finish_direct`, `iparm[7]`) and `scripts/direct-baseline.sbatch`.
- **Depends on:** R1.
- **Accept when:** relative residual <1e-8 with five solves.
- **Cost:** about three 10-minute jobs.
- **Decide by:** 18 October.

**U2: T1 lower tier** (memory limit 9 GB).
- **Situation:** the solver stagnates completely (rate 1.0000). Each rank holds a full-length scale vector (`solver.c:220`).
- **Plan:** first test a variable-aware configuration using the three contiguous temperature blocks within the already memory-compliant eight-rank envelope [H]. Use the observed convergence and memory results to decide whether a wider-rank trial is useful. Replace replicated scaling with local/neighbor data only if the selected experiment actually needs that change to stay within 9 GB.
- **Files:** `solver.c:219-245,304-317` and `scripts/initial-baseline.sbatch:44-52`.
- **Accept when:** relative residual <1e-4 and memory ≤9 GB by both the framework report and the conservative per-rank sum.
- **Cost:** about 4 jobs.
- **Decide by:** 20 October.

**U3: T4.**
- **Plan:** add an analysis-only exit that reports the value-free memory estimate. Today the code continues into factorization whenever the estimate is under 400 GiB (`solver.c:116-121`). Run one probe, and factorize once only if the estimate fits.
- **Decide by:** 20 October.

**U4: T2 upper tier.** The residual floor equals the constant component of b, and the matrix has a near-nullspace. That doesn't prove the tier is impossible. No compute until Q5 is answered.

## 4. Platform branches

### GPU feasibility (optional, timeboxed, never blocks R1–R5)

**Why it is limited to T2-low and T7 [C]:**
- The current direct implementation calls CPU MKL PARDISO and contains no HIP/DCU solver path.
- T5 (about 203 GB summed peaks) and T10 (about 124.8 GiB) exceed or approach the 128 GB host.
- T1, T3 and T4 are unsolved.
- T2-low and T7 use HYPRE, and the local HYPRE 2.33.0 source has a `HYPRE_ENABLE_HIP` option (`资料/dependencies/hypre-2.33.0/src/CMakeLists.txt:158`).
- The framework's GPU harness (`SC/apps/MPI_GPU_*`, `gpu_direct_solver_api.h:32-43`) excludes transfer time. Its CMake requires a CUDA compiler (`SC/CMakeLists.txt:24-36`); whether that works under DTK is [H].
- A GPU result only helps if it beats the CPU time: 20.9 s for T2-low, 6.2 s for T7.

**Steps:**

| Step | Proposed work | Limit and decision |
| --- | --- | --- |
| G0 | One allocated job through SCNet web E-Shell, one DCU within the granted CPU allocation (at most the recorded 32-core competition specification). Record module label, actual compiler, device model/architecture/memory, HIP libraries, MPI and job state. | ≤15 min; actual allocation controls subsequent builds |
| G1 | Build the local HYPRE HIP configuration and test the smallest adapter/settings changes needed for device execution. Inspect the current CUDA-only framework build boundary before choosing the integration point. T7 also needs its unconditional MKL build dependency separated from the iterative target if MKL is unavailable. | ≤2 days and ≤2 allocated node-hours; continue only if the existing solver can be exercised without a new solver stack or broad kernel rewrite |
| G2 | Start with T2-low; verify actual device execution, original float128 <1e-6, five solves, CPU/device memory and exit/state. Compare the whole solver under a stated timing boundary. A T7 probe is optional if its incremental work fits the remaining budget; T2 being slower is not itself proof that T7 will be slower. | Go/no-go by 20 October; GPU branch total ≤4.5 allocated node-hours |

Likely local changes are the selected adapter or existing HYPRE solver initialization, the relevant CMake dependency/target selection and a dedicated SCNet job script using the observed queue/data path. Whether the current `MPI_GPU_*` interface or the existing C driver is the right prototype is determined by G1; prototype timing does not establish formal scoring eligibility. Successful compilation alone is insufficient evidence of device execution.

Two cards are used only if Q6 confirms it's allowed. The pool's eight-card listing is not the team's quota.

### Domestic CPU (LX2, conditional)

- No access attempts until staff confirm recovery and supply the compute-node host, port, account and authentication.
- The window runs from that confirmation to 30 October.
- Once available:
  - L0: inventory of CPU architecture, compilers, MPI, scheduler, data path and allowance.
  - L1: HYPRE build in a batch job.
  - L2: one passing iterative problem (T7 or T2-low).
- MKL availability on LX2 is unknown, so the direct problems may not port.
- Internal cutoff: validated by 27 October.

## 5. Sequence to 30 October

**Can start right after approval, no replies needed:** R7, R5 tooling, R2 defaults, R1 E1a and E1b, R4, G0, and then U1 after E1b.

**Needs organizer replies:**

| Question | What waits on it |
|---|---|
| Q1 | Package shape and how the direct solver handles ranks |
| Q2 | What to do if T10 can't be made compliant |
| Q3 | Reuse across right-hand sides |
| Q4 | How tiers are submitted |
| Q5 | T2 upper tier |
| Q6 | Allowance and use of two cards |
| Q7 | Untimed steps and the exact closing time |
| Q8 | LX2 connection details |

| Window | Work | Gate |
|---|---|---|
| 2–9 Oct | R7; R5 caller repair, verification and provenance; R2 defaults; R1 E1a then E1b; R4 on a second node; G0 | 9 Oct: compliant probes pass? T5 margin reached? |
| 10–18 Oct | R1 E1c (reuse model if Q3 is answered by 12 Oct, otherwise per-RHS); R2 no-override runs; U1–U3; G1; R3 only if permitted; MPICH check | 14 Oct: T10 fallback decision. 18 Oct: T3 decision |
| 19–25 Oct | Package according to Q1; draft the technical report from `SC/SolverChallenge26报告模板.docx`, including memory use (`official-page.html:121`); R6 until 22 Oct; teammate reproduction; G2 decision on 20 Oct; LX2 if it has recovered | 25 Oct: main deliverable frozen |
| 26–29 Oct | Acceptance runs on the frozen package. Rerun all ten right-hand sides only if the direct code changed after E1c. Portal submission on your explicit go-ahead | 29 Oct: submission verified |
| 30 Oct | Buffer only; exact closing time is [O] | — |

**Commercial CPU budget:** about 18–25 node-hours with per-RHS runs.

| Package | Node-hours |
|---|---|
| R1 | about 8 |
| R4 | about 1.5 |
| R5 | about 2 |
| U1–U3 | about 3 |
| R6 | at most 3 |
| Final acceptance | about 1.5–7 |

Execution resource update, 1 October: the user confirmed that the commercial CPU has no platform machine-time quota. The approved project budget remains 18–25 node-hours and at most two running single-node CPU jobs. The GPU branch needs at most about 4.5 node-hours; GPU and LX2 allowances remain unknown.

## 6. Draft questions for the organizers (for your review; none sent)

1. **Submission:** What exactly do we submit: framework source with per-problem slots, binaries, or link files? Which driver runs each problem, with what command line (MPI ranks, OpenMP threads, environment variables)? Is MPICH required? May each problem use its own CMake options?
2. **Structure-only analysis:** Our candidate explicitly disables value-dependent scaling and matching in PARDISO phase 11. Which effective options and evidence are required to verify structure-only analysis? May explicit diagonal equilibration happen in the numerical preparation stage? How is compliance checked?
3. **Multiple right-hand sides (T8/T9/T10):** Are the ten right-hand sides given in one run or ten? May analysis and factorization be reused across them, and how are the times combined?
4. **Accuracy tiers (T1/T2):** Is each tier a separate run? May each tier use a different configuration? How is a tier that does not meet its residual threshold treated?
5. **T2 convention:** We measure ‖A·1‖₂ ≈ ‖Aᵀ·1‖₂ ≈ 6.94e-19, and the constant component of b is about 5.87e-7 of ‖b‖₂. Is the 1e-10 tier checked against the original b, or is a residual projected for compatibility accepted?
6. **Platforms and allowance:** Is "fastest of the three platforms" applied per problem? May a team use only some of the platforms? What machine time and expiry apply on each platform? How many CPU cores and DCUs may one GPU job use?
7. **Timing and deadline:** Format conversion and coordinate sorting are listed as untimed. Our CPU direct adapter performs complex conversion and T10 sorting inside timed callbacks. How should these operations be placed in the official harness? What is the exact closing time on 30 October?
8. **Huawei:** After the maintenance, please tell us the recovery date and the compute-node address, port, account and login method.

## 7. What you are approving

- **Fixes to completed work (recommended):**
  - R1: direct-analysis compliance and revalidation
  - R2: settings as source defaults, with packaging after Q1
  - R4: T5 margin
  - R5: validation, provenance and teammate reproduction
  - R7: document updates
  - R3: reuse prepared but gated on Q3
- **Optional optimization:** R6, and R3 reuse if the organizers allow it.
- **Unsolved-problem work:** U1 (T3), U2 (T1 lower tier), U3 (T4 probe). U4 (T2 upper tier) is a question only.
- **Platform branches:** the timeboxed GPU steps G0–G2, and the conditional LX2 track.
- **Your part:**
  - review the section 6 questions and decide how they should be sent
  - approve this plan and any increase to the node-hour budget
  - review the final submission package before its portal submission

Code changes, jobs, platform work and any messages start only after you approve.

## Coordinator verification and approval boundary

Codex verified the T2 caller/checker mismatch, the existing T2 projection overrides in the small tests, the direct-stage options and index-width branches, the GPU CUDA/MKL build boundaries, and the existing single-check/five-repeat validation contract. Current source, scripts and tests are unchanged against implementation commit `3970942`. The resource updates come from the specified conversation and current local records; no new compute probe was run for this plan.

The budget and dates are proposed planning limits, not confirmed platform entitlements or maintenance recovery dates. Approving this plan starts the agreed implementation and experiments; the optional branches can be included or excluded in that approval. Dependent steps wait for the required interface or resource facts. Until that approval, the deliverable remains a proposed plan.

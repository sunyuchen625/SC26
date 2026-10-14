# SC26 next execution plan and acceptance criteria

Date: 9 October 2026, Asia/Shanghai. Basis: [integrated Claude audit](reviews/CLAUDE_PROJECT_AUDIT_2026-10-09.md), followed by English cross-discussion in the same Claude Opus 5.5/max conversation. Status: approved by the user's instruction to open a new session and execute this plan on 9 October. The new session follows the gates and budgets below.

## Current state

The tested CPU candidate and launch campaign pass their documented scope. G1's synthetic single-process/single-DCU repeat passes. T2 HIP is prepared and statically ready, but its build, actual application execution, full-scale accuracy and performance are unverified. T1, T3 and T2-high remain numerically unresolved. Official integration, genuine teammate reproduction and LX2 compute access remain incomplete.

The next priority is one bounded T2 build/test, with the edited CPU path checked in parallel. Formal-contract and reproduction work proceeds alongside these tests. The frozen CPU candidate remains available throughout.

## Ordered work and gates

| Work | Completion criterion | Bound / dependency |
| --- | --- | --- |
| **S0: prepare the one pending script and current records** | Correct G1/accounting text; verify library/source/script identities; retain HIP/non-unified feature evidence; reuse nonempty checker arguments; successful shell syntax and allocated-node guard checks | Local preparation; no separate preflight allocation |
| **S1: HIP build and three known systems** | Successful configure/link; all three systems pass five solves each, original float128 relative residual <1e-10, known-solution error ≤1e-6; correct projection/tolerance; complete device/provenance/exit records | One node, one MPI process, four CPUs, one actually granted DCU; up to two 15-minute attempts, each retry addressing an observed cause |
| **S2: edited CPU T2 regression** | HIP disabled with the CPU HYPRE; existing Poisson/nonsymmetric/Neumann cases at 1/4 ranks all pass their checker and five-solve gates using a freshly identified binary | Parallel with GPU work; approximately 15 minutes; gates publication of edited common source |
| **S3: original full T2-low on one DCU** | Five complete converged solves; original-system in-memory float128 relative residual <1e-6; exact data/source/library/binary identity; device evidence; clean execution; memory within actual allocation | Starts after S1; first full allocation capped at 45 minutes; one cause-specific corrective retry if justified |
| **S4: performance decision** | Passing candidate compared under an explicit completed-work timing scope against the fastest permitted CPU control, with the uncertainty rule below | By 20 October; one targeted repeat only when needed |
| **S5: actual contract and independent reproduction** | Answers or provided harness; selected package passes under its allowed environment; teammate supplies their own build/job/check records | Begin now; internal review checkpoint 22 October |
| **S6: freeze and final delivery** | Selected validated candidate source/artifacts frozen with eligibility status explicit; actual contract verified before official delivery; final checks and authorized submission receipt | Freeze 25 October, final acceptance 29 October, recorded submission day 30 October; closing time to confirm |

### S0–S1: one prepared trial

Keep the source package immutable unless source code actually changes. Script-only provenance/checker changes alter the script fingerprint, not the source archive. Check install-892588's recorded library SHA before linking and retain installed HIP/device/unified-memory definitions. Python, GNU time and the real link are already checked by the pending build job; use that allocation rather than queueing a separate preflight.

Upload the selected source and script through an observable file-transfer route and verify the transferred bytes. When E-Shell delivery is unreliable, use a single complete manual command with observable output. Avoid duplicate submissions while a job is pending. Configure/build failures should expose their cause and preserve full logs.

All three small systems use internal tolerance 1e-11. Projection is off for the unique systems and on for Neumann; only Neumann gets the checker's constant-nullspace token. Require five complete callbacks and five device-policy records per case, zero solver exits, empty runtime error files and Slurm `COMPLETED 0:0`. Library, archive/manifest, CMake cache and executable fingerprints must agree. Compilation alone is not S1 acceptance; the previous PCG/l1-Jacobi example is not evidence for this GMRES/relax-6/RAP2 implementation.

### S2: bind the regression to the edited snapshot

Build only the relevant T2 target from the same 89-file source package, with HIP off and the validated CPU dependency. Use the existing six-case logic and checker, from the snapshot working directory with explicit `SC26_ROOT`/`SC26_BUILD_DIR`. Record the test-script, cache and executable hashes; verify that the cases run the freshly built binary. Default paths must not silently select an older build. A whole 24-case/30-RHS rerun is unnecessary unless a real new concern warrants it.

S2 protects publication of the edited common source; it does not need to delay the independent DCU trial. A failed CPU regression leaves the frozen CPU release in place until the observed defect is resolved.

### S3: original problem, device and resources

Use the S1 executable without rebuilding; match its fingerprint. Use actual T2 files with dimensions and recorded input identities matching the CPU problem. Restore the source-default full-problem settings: tolerance 1e-7 and the recorded projection policy. Record all five convergence/phase rows and the original float128 check after solve five.

The application-specific device evidence chain is:

1. The loaded library fingerprint and feature definitions establish a HIP, non-unified-memory build.
2. Archive/manifest, dependency path, cache and executable fingerprints identify the exact application.
3. The HIP branch and successful migrations execute, with device/device policy records for all five rounds.
4. The supported HYPRE memory-location dispatch connects those device-resident objects to the device numerical path.

This is source/runtime-backed evidence; available activity traces may corroborate it. Allocation growth or policy readback alone is insufficient. Phase VRAM observations support the chain and resource diagnosis. Unexpected retained memory at a later ANALYSE baseline should be investigated; a raw growth pattern or a particular byte inequality is not itself proof of a leak or a numerical failure.

Request host memory explicitly within the actual grant and data footprint. Capture complete-process host RSS peak and phase-labelled GPU snapshots/capacity. Reject actual OOM, allocation failure, resource overrun, nonzero exits or failed original residuals. The snapshots and local GPU helper's sampled observed delta are not continuous device peaks. Implement a more specific memory metric only when an actual applicable contract requires it. Use reliable capacity records, not the erroneous HYPRE device-info memory field.

### S4: a predeclared performance decision

Use the fastest CPU setting allowed by the actual contract. The present experimental reference is T2-low at 96 ranks: **7.036402 seconds**. Its 16-rank same-allocation control is 24.355135 seconds; the older delivered 16-rank mean is historical context, not the winning comparison control.

Record all five times and the mean. Label the current CPU-driver HIP measurement as prototype-inclusive of its transfers/diagnostics. Its host copy and finalization complete the device work for the total measurement; phase splits remain indicative. Transfer-subtracted official timing needs the actual integration contract. The provided GPU driver explicitly measures upload/download separately and exposes sampled memory hooks; ask whether a HIP solution using the CPU driver is admissible or must implement that adapter.

The proposed engineering decision is fixed before the full trial:

- A fully validated GPU mean at least 10% below the permitted reference is a performance candidate. Against the present reference this preferred target is approximately **6.333 seconds**; it is not an official eligibility rule.
- A smaller measured advantage receives at most one identical GPU repeat in another allocation and one contemporaneous T2 CPU control if needed. Retain it as reproducibly faster only if both GPU five-round means beat the fresh permitted T2 control and the observed per-round ranges are separated. Otherwise record performance as inconclusive and retain the CPU choice. Record every attempted run.
- A passing numerical candidate with no demonstrated timing advantage remains valid numerical evidence, but does not justify switching the selected performance implementation. Timing uncertainty may justify one scoped timing rerun within budget after the contract is known.

This rule uses the actual T2 control and recorded variation; it does not derive a T2 uncertainty bound from another problem's timing. Any official speedup or score remains a separate contract-dependent result.

## Budget, integration and deadlines

Count failed allocations in the original **4.5 GPU node-hour** branch cap and **two-hour build/integration** cap. Recorded consumption is 1024 seconds, including 1009 seconds of library build/relink. Two small attempts, two possible full allocations and one uncertain-decision repeat fit approximately 3.04 GPU node-hours including current consumption; remaining budget is not a reason for a broad parameter sweep. Keep at most two concurrent SC26 CPU jobs, preserve other projects' jobs, and use the configured compute credentials privately.

Suggested checkpoints: local preparation and contract draft 9–10 October; small-case and CPU regression gates by 12 October; first full T2 assessment by 16 October; GPU technical decision by 20 October. Resolve GPU eligibility by 24 October for inclusion in the 25 October freeze. If the organizer has not answered by the 22 October review, retain a documented CPU candidate under known public assumptions without declaring it eligible or inventing a replacement contract.

LX2 goes forward only with actual backend host/account/scheduler/data/toolchain facts. Decide by 21 October and validate by 24 October for main-package inclusion; otherwise it does not delay the freeze. The 27 October checkpoint verifies already-frozen artifacts. T7 GPU remains a separately scoped optional opportunity after T2, requiring a concrete minimal plan, remaining budget and execution authorization. Unsolved T1/T3/T2-high and unavailable optional platforms limit coverage; they are not newly imposed submission prerequisites for passed CPU problems.

The standing completion pipeline remains actual validation, local English Claude audit and Codex integration/push after audit PASS. Organizer/teammate messages and portal submission require their own explicit authorization. This plan was fixed before the next-phase numerical execution. Subsequent evidence is recorded in the [T2 execution record](T2_HIP_RESULTS_2026-10-09.md).

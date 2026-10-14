# SC26 project audit — 9 October 2026

Reviewer: local Claude Code, `claude-opus-5-5`, max effort, existing Claude Pro subscription. Codex verified the findings and integrated the subsequent English cross-discussion. Evidence: execution chat `01a0f7c8-a5a7-7b62-b30c-67c393ac081c`, local commit `d1c5bd160b5fd823c24e9f0f125f1f19cb7704e4`, its uncommitted T2 HIP changes and saved job records. Review tools were limited to scoped local Read/Glob/Grep.

## Scoped judgments

| Scope | Judgment | Evidence boundary |
| --- | --- | --- |
| Delivered CPU implementation and next-phase candidate | **PASS** | Eight numerically passing problem numbers, T2 lower tier only; the fourteen frozen-method launch records pass numerical, execution and provenance checks |
| G0 and G1 synthetic single-DCU feasibility | **PASS** | Inventory, HIP kernel and clean HYPRE example under the tested single-process configuration |
| Current T2 HIP source and build script | **Statically ready for the small-case trial** | APIs, supported settings and proposed link design are consistent with pinned HYPRE; compilation and execution are unverified |
| Full-scale T2 GPU accuracy and performance | **Unverified** | No T2 HIP build, known-case or full-data result exists |
| Formal submission readiness | **Not ready** | Actual submission/launcher/MPI/timing/eligibility contract and submission evidence remain incomplete |

The uncompiled working-tree changes do not revoke the frozen CPU results. They also do not inherit those results merely because their parent commit is tested.

## Current completed evidence

The original CPU release passes T2-low, T4, T5, T6, T7 and all ten right-hand sides of T8/T9/T10. The subsequent CPU campaign accepted fourteen configurations. In allocation 9213608, the fastest observed means were T2-low **7.036402 s** at 96 ranks, T7 **5.869507 s** at 96 ranks and T6 **35.427933 s** at 96 threads. Same-allocation reductions were 71.11%, 65.88% and 23.07%. Formal adoption of launch settings remains conditional on the organizer's contract.

The T1 diagnostic completed below 9 GB but retained original relative residual approximately 1104.663. Its dominant bin held 98.799% of original error energy and 58.870% of scaled error energy, so the predeclared 90%/10% trigger was false. This closes that tested metric hypothesis; T1 remains numerically unsolved. T3 and T2-high also remain unsolved.

G1's final repeat **893006** completed `0:0` on `f11r2n10` in two seconds. It verified the same example binary from 892588, registered isolated singleton mode, solver exit zero, twelve iterations, reported relative residual **2.016065e-9**, empty batch stderr and zero-byte runtime stderr. Its scope is an 8×8×8 AMG-PCG/l1-Jacobi example. It does not test the proposed T2 GMRES/relax-6/RAP2 path or the original contest system. The earlier daemon cleanup error remains historical evidence; its general cause was not established.

GPU accounting covers thirteen allocations, including failures, totaling **1024 seconds**; HYPRE build/relink work accounts for 1009 seconds. CPU accounting totals 12.2936 node-hours; the completed performance campaign used 0.785 node-hours. These are engineering-budget records, not a commercial-CPU platform quota.

## Findings and their consequences

1. **Prototype timing has a defined inclusive scope.** T2 `solver.c` includes migrations, device initialization and diagnostic output inside timed callbacks. Such time is valid as a labelled prototype measurement. It cannot establish official timing or a score. The provided MPI GPU driver separates upload/download and excludes them from its accumulated time; accepting a HIP implementation through the CPU driver needs an explicit integration answer. GPU work must have completed at the timing boundary. A bound obtained by subtracting overhead applies only to the same implementation/workload.

2. **Device evidence needs the complete application chain.** Five policy readbacks alone are not independent kernel evidence. Validation should connect the actual HIP/non-unified-memory library and executable fingerprints, successful migrations, executed HIP branch and supported memory-location dispatch. Full-scale VRAM observations corroborate this chain. Kernel traces can add evidence but are not a required new tool stack. VRAM growth alone cannot prove computation.

3. **Memory measurements have different meanings.** GNU time supplies full-process host RSS peak. HYPRE supplies phase snapshots of device-wide memory use. The local GPU helper similarly distinguishes tracked bytes from observed sampled memory delta; it is not a continuous device-peak tracker. The pinned `general.c:483–484` passes an integer memory expression to `%.2f`, so that device-info capacity field is unusable. Use validated capacity data and correctly defined usage measurements. Applicable official memory requirements must be confirmed rather than invented.

4. **The edited common source needs a CPU publication gate.** The new package is parent commit d1c5bd1 plus uncommitted changes. Its archive SHA and 89-file manifest identify the actual bytes. A later commit inherits test evidence only if it matches those tested bytes. The edited T2 CPU path, with HIP disabled and the actual CPU HYPRE, needs its existing six-case regression. Until then, the frozen CPU candidate remains the tested release.

5. **The reused dependency needs an identity check.** A prior relink changed a library archive in place. The ready T2 script names install-892588 but does not verify its recorded `libHYPRE.a` fingerprint. A direct checksum check and installed feature record are proportionate additions before the next build, without rebuilding or changing the provider stack speculatively.

6. **Current-entry documentation needs the final G1 result.** The next-phase result record still described 893006 as prepared and the older cleanup issue as current. The nine-October supplied output closes that tested configuration. The corrected record distinguishes the earlier failure, the successful isolated repeat and the uncompiled T2 prototype.

7. **Small preparation changes can reduce avoidable retrieval rounds.** The new build script's empty optional argument array fails under the locally observed Bash 3.2 nounset behavior; the SCNet shell version is not recorded, so remote failure is not established. Reusing the existing nonempty checker-argument pattern is a minimal way to keep the actual three-case invocation clear. Configure/build failures can expose a short failure summary while retaining full logs and their original exit status.

## Verified source facts

The HIP API signatures are present in HYPRE 2.33.0. Migration is in place; the solution is returned to host before `GetValues`; fresh initialization after finalization creates a new handle. Original matrix/RHS data are preserved and the existing float128 checker reloads the original system after solve five. GPU-supported PMIS 8, interpolation 6 and relaxation 6 are selected. The pinned constructor's relaxation order is already zero, and the coarse relaxation is explicitly six; no additional setter is needed.

The C++ link design, `hip::host` and observed Clang-runtime directory match the successful dependency build. The actual T2 configure/link step still has to confirm the complete executable, including the GCC-built float128 helpers. Codex checked the 51,702-byte source archive and all 89 manifest entries against current files; all matched. The archive is identified by SHA256 `9708c99de61699a0c9d7452503ab07c97284ed3287b57185a816947d8de58ee0`.

## Outstanding conditions

Formal package shape, launcher/MPI, analysis/scaling placement, timing, tiers, ten-RHS handling, HIP/CPU-driver admissibility and the exact 30 October closing time need actual answers or an organizer harness. Genuine teammate reproduction remains the project's internal acceptance gate. Unsolved tiers and unverified optional platforms limit coverage; no supplied rule makes them mandatory prerequisites for submitting eligible CPU problems. LX2 has a working desktop entry but no confirmed compute backend details.

Complete prompts, original audit, two discussion replies and verification metadata are preserved in `.agents/collaboration/2026-10-09-audit-plan/`. The proposed execution gates are in [the next plan](../NEXT_PLAN_ACCEPTANCE_2026-10-09.md).

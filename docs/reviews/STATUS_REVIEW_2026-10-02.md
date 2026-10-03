# SC26 current-state judgment and next work

Evidence date: 2 October 2026. Cross-discussion completed: 3 October 2026, Asia/Shanghai. Source chat: `01a0f7c8-a5a7-7b62-b30c-67c393ac081c`, “执行 SC26 计划并完成 Claude 审计与推送”. Delivered commit: `6b7f675ecaa6949815a3a77f95467fc35f8d5bbf`.

**The delivered CPU remediation milestone passes. The complete execution program remains partly finished, and official submission conditions are not yet satisfied.** Codex and Claude agree on the verdict, the evidence boundaries and the next sequence below. Two English discussion rounds with local Claude Code Opus 5.5/max are complete, with no remaining disagreement. On 3 October, the user authorized execution of this plan in the existing execution chat.

## Current result and evidence

Eight problem numbers have an original-system numerical pass: T2 lower tier, T4, T5, T6, T7, T8, T9 and T10. T1's two tiers, T2 upper tier and T3 remain unsolved. The execution chat records a successful GitHub push and a matching remote commit. No official score or accepted contest submission is evidenced.

| Problem | Completed evidence |
| --- | --- |
| T2 lower tier | Original relative residual 5.885605e-7; source defaults, 16 ranks |
| T4 | Original relative residual 1.170601e-12; five complete solves, 64-bit factor indices |
| T5 | Selected default residual 2.576043e-9; four margin jobs across two nodes and 64/96 ranks, five internal convergence flags per job |
| T6 | Original relative residual 1.834771e-12 |
| T7 | Original relative residual 1.601450e-9; source defaults |
| T8, ten RHS | Maximum absolute residual at most 3.537289e-16 |
| T9, ten RHS | Relative residual at most 1.051758e-15; largest full-process peak 24.636 GB, below 100 GB |
| T10, ten RHS | Relative residual at most 7.521765e-15; largest full-process peak 128.830 GB |

Direct phase 11 receives a NULL coefficient pointer, with library scaling and matching disabled. T10's reciprocal row pairs depend only on CSR indices. Numerical preparation forms D(PA)D and DPb; x=Dy is restored before original-system validation. T4 uses the existing wide-index path because full-scale factor indices actually overflowed 32 bits. Passing source defaults, T5 convergence margin and the T2 small-case checker caller have been validated.

Codex re-ran the existing archived-run verifier on 2 October: all 30 full-RHS records, both default records, all four T5 margin records and all five selected direct records passed; all ten known experimental failures were rejected. Each full-RHS record has five complete phase records, a zero process exit, Slurm completion and an original-system float128 check after solve five. All 118 frozen v19 source entries passed independent hash verification and byte comparison to the current production source/scripts/tests. The final build recorded nine targets and 24 known-solution cases.

These checks used saved local logs; they are not fresh full-scale computations. MPI memory remains the conservative sum of rank peaks. The three ten-RHS sums are per-RHS accounting, not official scores. Execution consumed 11.4861 tracked single-node hours. The user's confirmation that commercial CPU has no platform machine-time quota is distinct from the project's experiment budgets and shared-account concurrency limit.

Evidence: [execution results](../EXECUTION_RESULTS_2026-10-02.md), [prior execution audit](CLAUDE_EXECUTION_AUDIT_2026-10-02.md), [30-RHS verification](../../logs/2026-10-01/execution/full-rhs-verification.json), [T5 margin verification](../../logs/2026-10-01/execution/t5-margin-verification.json), and [approved plan](../EXECUTION_PLAN_2026-10-01.md).

## What has passed, and what remains

The CPU implementation and archived acceptance evidence are sound within their stated scope. No new observed blocking production defect was found. The original analysis conflict, T5's thin margin, source-default reproducibility and the actual checker-call mismatch are resolved.

The original program still has unfinished integration and reproduction work. Root CMake redirects multiple slots to the shared CPU implementation, while the saved framework describes per-slot customization. Direct solvers accept one MPI rank, while the framework README gives a two-rank example. The README states MPICH; recorded runs use OpenMPI. Package layout, actual launch settings, T10 numerical-preparation scaling, conversion/sorting timing, tier handling and ten-RHS reuse/score aggregation need the organizer's actual contract. Independent teammate reproduction, alternate-platform validation and portal acceptance are also outstanding.

## Approved next sequence

### 1. Resolve the submission contract and assemble a local candidate

Consolidate the existing organizer questions into a short reviewable sheet: source/binary/package shape, ranks/threads/MPI, structure-only analysis and numerical scaling placement, untimed conversion/sorting, ten-RHS invocation/reuse/aggregation, accuracy tiers and T2 compatibility, T3 expected precision/output convention, and the exact 30 October closing time.

Prepare the candidate from the delivered commit, selected per-problem configurations and technical report. Adapt integration only to supplied answers or the actual harness. Acceptance means the candidate builds and passes under that contract. Organizer communication and official submission remain separate authorized actions.

### 2. Obtain genuine teammate reproduction

A teammate independently rebuilds and runs the 24 known cases, T2-low, T7, selected T5 and T9 RHS01 on organizer resources, recording their own source/configuration/binary identities, job IDs and complete acceptance logs. Begin with the validated OpenMPI stack when a teammate is available; add the required MPI stack when the actual contract identifies it. Codex's own repeated execution does not supply independent teammate evidence.

### 3. Select launch settings through a bounded comparative campaign

Use the frozen numerical methods and comparable runs in the same node allocation:

- T7: start with 16 versus 96 ranks; 64 is conditional on useful measured information.
- T2-low: start with 16 versus the historically validated 32 ranks; 64/96 are conditional on the measured trend and remaining budget.
- T6: compare 32/64/96 threads only if the same campaign budget permits it.

Cap the campaign at three additional single-node hours and at most two concurrent SC26 jobs. Require original numerical acceptance, five solves, exits/states, memory and provenance for each configuration. The speed target is at least 10% under comparable conditions. Historical timings motivate the test; they do not guarantee the result. Official adoption follows the allowed launch contract; exploratory launch results can be documented separately while it is pending. Retain the validated T5 method and margin. Stop by 22 October.

### 4. Use a discriminating T1 diagnostic; defer new T3/T2-high solver work

For T1, run one allocated diagnostic with the current method at eight ranks, reporting original r=b−Ax and scaled Dr by temperature block and row-maximum magnitude bins. Report the original/scaled RHS norms as well. This tests whether the scaled metric underweights the rows that dominate original error. The proposed 90% original-error/10% scaled-error split is a heuristic trigger, not proof that metric choice is the only cause; coupling, anisotropy and preconditioner quality may coexist. A subsequent original-residual-minimizing experiment is a separate proposed branch, with an explicit hypothesis, approval, measured memory at most 9 GB and original lower-tier residual below 1e-4. Failure of this diagnostic closes that branch rather than establishing that T1 cannot be solved.

For T3, retain the measured refinement stagnation near 2.7e-5 and double-output sensitivity as observations. The archived v12 original-system GMRES already accumulated matrix products in float128, then cast the products and returned iterate to double. The next delivery milestone schedules no additional T3 solver jobs by default. Ask about the expected precision/output convention; reopen numerical work only with a genuinely discriminating, separately approved hypothesis. A noise-scale estimate or one rounded candidate is not a universal lower bound for every double-representable solution.

One distinct reopening hypothesis would keep the iterate in wide precision across corrections, then compare its original-system float128 residual with the residual of its double-rounded output. Stagnation in both locates a limitation earlier in that candidate; a passing wide iterate with a failing rounded output identifies rounding of that candidate as the limiting step; passing both supplies a candidate for normal five-solve acceptance. These outcomes concern the tested candidate, not the attainability of every possible double solution.

For T2-high, retain the measured near-nullspace and projected-method floor; wait for the original-system compatibility convention. A small nonzero Aᵀ1 does not alone establish a universal floor without a bound on x. The upper tier is not declared mathematically impossible.

### 5. Keep alternate platforms conditional

GPU work begins with observable output from one actually granted DCU allocation, then the approved minimal HYPRE HIP feasibility boundary and 4.5 allocated-node-hour cap, with actual device execution and original-system checks. LX2 begins after confirmed maintenance recovery and backend details. Neither branch blocks the CPU candidate. T10 ordering optimization remains conditional on the multi-RHS contract and a compliant numerical candidate. Existing 20 October GPU, 25 October main-freeze, 27 October LX2 and 29 October final-acceptance checkpoints remain; 30 October's exact closing time still needs confirmation.

## Agreed cross-discussion conclusion

Both rounds conclude **CPU delivery: PASS; official readiness: NOT READY**. The agreed priority is the submission-contract sheet and package candidate, genuine teammate reproduction, the paired launch campaign, then the proposed T1 residual-metric diagnostic. New T3 solver work and T2-high compute are deferred as specified above. GPU/LX2 remain conditional.

Claude explicitly agrees that T3's noise scale and T2's near-nullspace observations do not establish universal impossibility; performance adoption requires fresh paired measurements, including T2's known 32-rank setting; and the T1 bin test discriminates a proposed branch rather than proving a sole cause. There is no remaining disagreement on these boundaries or priorities.

The complete English prompts, replies and verified interaction metadata are preserved locally in `.agents/collaboration/2026-10-02-status-review/`. The reviewer was limited to project-local Read/Glob/Grep, with zero web search/fetch requests. Codex owns the evidence checks and final integration; Claude supplied the independent judgment and critical discussion.

# Claude execution audit — 2 October 2026

Reviewer: Claude Code, `claude-opus-5-5`, effort `max`, through the existing local subscription. Session: `c8524e4a-ddcf-4342-bda5-2a44e19e92a3`; completed with exit 0. The session exposed only Read, Glob and Grep over local evidence. Audit base: `9773d00888b95c7e3404f191c2457f7a767b144a` plus the completed working-tree changes.

The complete reviewer response follows. Its verdict covers the locally validated CPU implementation, archived evidence and report. The formal interface and platform gates are stated in the response.

# SC26 completed-implementation audit (read-only, 2 October 2026)

There are no blocking defects. The final code, the saved evidence and the report agree with each other and with the raw logs. Two current documents still contain status lines from before the October results; they understate, but should be fixed with the push. Priorities: P1 blocks the push, P2 should be fixed with the push, P3 is optional.

## Blocking findings (P1)
None.

## Non-blocking findings (P2, fix with the push)

**F1 — `docs/项目背景与下一步工作方案.md`:19, 43, 60–62.** `README.md:26` links this file as 项目计划, but it still describes the pre-fix state:
- **:19** says T4 未达标. Job 9211739 passed at 1.170601e-12.
- **:43** still lists T4 as a current focus.
- **:60** says T10's PARDISO analysis "明确启用数值缩放与匹配，与保存的结构分析规则有冲突". This contradicts the delivered code:
  - `solver.c:23` passes `NULL` values to phase 11.
  - `solver.c:125–126` sets `iparm[10]` and `iparm[12]` to 0.
  - The runs print `scaling=0 matching=0 analysis_values=null` (`batch/sc26_t10_rhs_01-9211884.out:157`).
- **:61** still says T5 has a 2.7% margin at the 300-iteration cap.
- **:62** still gives T4's residual as 0.1150246.

**Why it matters:** the approved plan's R7 acceptance (`EXECUTION_PLAN:173`) requires current entry points to reflect the latest observations. A teammate reading this file would think the compliance defect R1 fixed is still in the code.

**Why it does not block:** the file is dated 2026-10-01, was accurate on that date, and only understates the results.

**F2 — `docs/COMPUTE_STATUS_2026-10-01.md:30`.** It says the results record "T4's single-solve pass and the remaining acceptance work". The results document records T4's normal five-solve acceptance (`EXECUTION_RESULTS:42`) and all thirty RHS accepted (`:71–75`). Calling the one-factor diagnostic "T4's pass" also blurs the line between diagnostic runs and normal acceptance.

## Optional suggestions (P3)
- **O1 — `EXECUTION_RESULTS:28`.** The T10 RHS 01 row cites v18 job 9211791. That build still contained a generic augmenting-path branch that never ran (`search_edges=0`) and was later removed. Line 34 excludes T10 from the binary-equivalence claim, so this row is not final-source evidence. Annotate it, or cite the v19 RHS 01 job 9211884 (7.227728e-15, 188.761426 s, 128,812,560,384 B).
- **O2 — `solver.c:112–113`.** `matched=%d` always prints `rows`, so it carries no information; the name is left over from the rejected v17 matching. `nearby_pairs` always equals `missing_diagonal`, because each missing-diagonal row is paired once or the process exits (`:95–101`).
- **O3 — `remediation-build.sbatch:10`, `remediation-baseline.sbatch:10`.** The hard-coded `--chdir=.../execution-20261001` is an old experiment root, and every documented submission overrides it (`README:89, 96–101`). Removing the line gives the same behaviour.
- **O4 — `README:94–102`.** Plan line 139 lists stable T5 for teammate reproduction, but the README has no T5 launch line. It would be `--ntasks=96 --cpus-per-task=1`; the script's default 450G covers the ~203 GB summed peak. This only matters for the separately gated teammate reproduction.
- **O5 — `content.json:8–28`.** Report table rows 1 and 3 name trial-only methods (T1 MGR from v9, T3 original-system GMRES from v12) that are not in the delivered source. The body already calls them trials; a "试验" marker in the method cell would make that explicit.

## Verified without findings
1. **Direct solvers**
   - Phase 11 gets `NULL` values with scaling and matching set to 0 for every direct problem. Complex conversion and paired column/value sorting are kept (`solver.c:140–181`).
   - T10's row permutation reads only `row_ptr` and `col_idx` (`:67–111`). Diagonal rows stay in place. Each missing-diagonal row swaps with its nearest unused diagonal row that has a reciprocal entry, so both rows end up with structural diagonals.
   - The owned CSR, complex A and b are copied in the same row order (`:104–111, 146–153`). D(PA)D and DPb are formed in the factorization stage (`:202–221`), and x=Dy is restored (`:241–246`).
   - The driver re-reads the original files for its single check after the fifth solve (`apps/MPI_direct_solver.c:154–173, 239–288`).
   - Only T4 joined the 64-bit path (`solver.h:14`). The logged overflow is exact: 9,539,544,996 mod 2³² = 949,610,404.
   - Perturbed pivots are recorded per factorization (T4 0, T6 0, T8 60, T9 168, T10 1). Plan line 57 treats them as diagnostics, not an accuracy rule.
2. **Source defaults**
   - T2 defaults to tolerance 1e-7 with projection on (`problem02:53, 94`). T5 defaults to 5e-9 with a 450-iteration cap; T7 to 1e-12 (`solver.c:286–287, 424`).
   - The CMake caches show `SC26_FIELD_SPLIT=ON` for T5 only.
   - The T2 small cases set projection off for the unique-solution systems and on for Neumann (`t2-small:21–22`).
   - The default-run batch logs (9210626, 9210627, 9210478, 9210708) print no `SC26_*` variables; only 9210707 and 9210709 show `SC26_RTOL=2e-9`.
   - T5 holds its margin on c3n29 at 96 ranks and c3n90 at 64 ranks: residuals 2.576e-9, 1.115e-9, 2.704e-9 and 8.507e-10, each with five `converged=1`.
3. **Acceptance logic**
   - `check_result.py` requires exactly one float128 check and five solves. It uses the maximum absolute residual for T8 and accepts only the `constant-nullspace` token (`:12`).
   - `verify_runs.py` reports numerical, convergence, exit, Slurm, provenance and memory results separately (T1 summed peak ≤ 9e9 bytes, T9 < 1e11).
   - The T4 one-factor and T3 refinement diagnostics are reported separately from normal acceptance.
4. **All-RHS acceptance and provenance**
   - The full-RHS manifest requires exactly RHS 01–10 for T8, T9 and T10, and all 30 records are accepted.
   - I recomputed every aggregate the results document reports and all match:

     | Problem | Max residual | Per-RHS mean range | Sum of means | Largest peak |
     | --- | ---: | ---: | ---: | ---: |
     | T8 | 3.537289e-16 (max abs) | 79.191692–79.560917 s | 793.459075 s | 40,099,975,168 B |
     | T9 | 1.051758e-15 | 75.559040–75.954751 s | 757.628227 s | 24,635,875,328 B |
     | T10 | 7.521765e-15 | 181.421–214.132749 s | 2004.431736 s | 128,830,332,928 B |

   - Manifest job states match the accounting log.
   - The v19 snapshot matches the current production files, scripts and tests by content. The v19 build log shows all 118 manifest entries OK (manifest `bf8148b5…`).
   - Each accepted binary's hash appears in its build log and again in its run's batch log, for the v4, v15 and v19 builds.
   - In the binary comparison, the only differing bytes are two per binary inside the non-loaded `.comment` section (the startup-object GCC version string). T4 is byte-identical.
5. **Tests and archived verification**
   - The v19 build 9211860 has 24 `KNOWN_SOLUTION_PASS` lines: 6 T2, 14 direct, 4 field systems. The earlier builds 9210469 and 9211738 have 20 and 23.
   - `complex_structural` exercises a real missing diagonal, a reciprocal pair and unsorted rows (`missing_diagonal=1 rows_moved=2`, `SORT rows=2`).
   - Historical verification rejects the T5-ILU failure and the cancelled T9 job and keeps the missing-metadata (`null`) boundaries. All ten experimental failures are rejected.
6. **Resources, docs and report**
   - The tracked jobs' elapsed time sums to 41,350 s = 11.4861 h, and no more than two SC26 jobs ever ran at once.
   - The docs assume no quota, official score, MPI requirement, GPU quota, LX2 date or new interface; the organizer letters remain drafts.
   - The README launch lines match the 16-rank T2/T7 runs. Their memory values (60G/75G) come from the execution notes, not from raw Slurm records.
   - The report content and the v10 rendered pages match the records, and the T8/T9/T10 per-RHS sums are explicitly scoped to "正式计分聚合及因子复用仍以主办方接口为准".

## Audit limits
I compared the v19 snapshot to the current files by content; I could not recompute hashes, so hash provenance rests on the recorded batch logs. I checked the DOCX only through `content.json` and v10 render pages 1–3 and 5. No files were written.

**AUDIT VERDICT: PASS** — this covers the repository deliverable as a locally validated CPU implementation with its archived evidence. It does not cover these items, which remain open:
- official eligibility;
- organizer acceptance of T10's scaling in the numerical-preparation stage (Q2);
- conversion and sorting inside timed callbacks (Q7);
- multi-RHS reuse and score aggregation (Q3);
- MPI, packaging and accuracy-tier submission (Q1/Q4);
- teammate reproduction;
- GPU G0 observability;
- LX2 recovery;
- portal submission.

## Codex verification of the findings

The two P2 findings were verified against the current files and corrected before delivery. `项目背景与下一步工作方案.md` now records T4's five-solve pass, structure-only direct analysis, the validated T5 defaults and convergence margin, and the remaining numerical/interface work. `COMPUTE_STATUS_2026-10-01.md` now distinguishes the early T4 diagnostic from normal acceptance and records all thirty accepted RHS.

The T10 RHS 01 row in `EXECUTION_RESULTS_2026-10-02.md` now cites final-source job 9211884 and its verification manifest. The README includes the validated 96-rank T5 launch command. These are documentation changes; the frozen v19 source and accepted binaries retain their recorded identities.

Codex independently recomputed all 118 final-source manifest entries before the audit and inspected all six DOCX render pages, in addition to the reviewer's checks. The final DOCX preserves the original template's section and table geometry. The complete numerical, execution and provenance acceptance remains linked from the execution results.

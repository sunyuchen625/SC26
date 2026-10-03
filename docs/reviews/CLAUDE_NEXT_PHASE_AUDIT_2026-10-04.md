# Claude Opus 5.5/max next-phase execution audit

Date: 4 October 2026, Asia/Shanghai. Numerical source: `6b7f675ecaa6949815a3a77f95467fc35f8d5bbf`.

**Release verdict: PASS.** Two completed native Claude Code reviews found no blocking issue in the bounded CPU/candidate phase. The final focused review found no actionable findings. Official submission conditions, independent teammate reproduction, GPU allocation/control and LX2 recovery remain open.

## Review setup and independent validation

The reviewer used native Claude Code 2.1.288, Opus 5.5/max and the existing Claude Pro subscription. Its only available tools were local Read, Glob and Grep. Codex retained all file edits, computations, jobs and Git operations. [Native-session metadata](../../logs/2026-10-03/next-phase/claude-audit-metadata-20261004.json) records model/tool identity, completion, read scope and usage.

Codex validated all fourteen accepted launch configurations with the existing checker and archived-run verifier; the completed numerical part of failed allocation 9213582 remains rejected for execution. New CPU allocations total 2,907 seconds, including the failed allocation and T1 diagnostic. The T1 grouped-energy trigger is false and its measured memory is below 9 GB. See [phase results](../NEXT_PHASE_RESULTS_2026-10-04.md) and [verification](../../logs/2026-10-03/next-phase/launch-verification.json).

The final [candidate package check](../../logs/2026-10-03/next-phase/candidate-package-check-20261004.json) verifies all 118 frozen source entries, the delivered report and the 16-thread T9 guide inside the archive. Local and remote archive SHA256 agree: `dae96e3fa5c8dc4cf8d66469b34797a84a0f3d741d0f8f4d8b4884f16206a111`. The archived-source hash listing passes independently and matches the corresponding recorded batch hashes.

## Final corrections

- Both T9 reproduction guides use the delivered 16-thread configuration.
- The five archived helper-script hashes are recorded in `source-sha256.txt`.
- `bin-summary.json` records the exact group-selection rule; its numerical fields are unchanged.
- Queued G0 job 883172 has no observed allocation or device/toolchain output. Its output and stderr must be read together when available.

## Read scope and evidentiary limits

The first review made three repository-wide searches which covered the excluded private-application subtree and returned no content there. The final review used an explicit private-path Read deny and scoped searches. Codex checked every recorded final tool call: all paths stayed within this workspace, none read or searched `资料/`, and none searched the repository root. The reviewer's shell, write, web, job and delegation tools were unavailable.

The reviewer could read saved checks but could not compute hashes or open the archive. Codex performed those package checks separately. The first response's finer-row-subset assertion is a reviewer statement; the delivered T1 conclusion uses only the archived grouped-energy rule. The complete responses follow, with link targets normalized to repository files.

## Complete first review

**AUDIT VERDICT: PASS.** The completed next-phase deliverables check out against local evidence. There are no blocking findings, and four non-blocking ones are listed below.

This verdict covers only the bounded phase. It doesn't establish readiness for an official submission, and the unresolved outside conditions are listed at the end.

## Blocking findings

None.

## Non-blocking findings

1. **The teammate guide's T9 thread count disagrees with the candidate's stated configuration.**
   - [REPRODUCE_CPU_2026-10-03.md:51](../../docs/REPRODUCE_CPU_2026-10-03.md#L51) (and line 51 of the candidate's own `REPRODUCE.md`) submits T9 RHS01 with `--cpus-per-task=32`. [remediation-baseline.sbatch:31](../../scripts/remediation-baseline.sbatch#L31) turns that into 32 OpenMP/MKL threads.
   - [SUBMISSION_CANDIDATE_2026-10-03.md:24](../../docs/SUBMISSION_CANDIDATE_2026-10-03.md#L24) (and the candidate README) lists T8/T9 at 16 threads. That matches the delivered ten-RHS records (`full-rhs-runs.json:9`: job 9210630, 16 threads).
   - 32 threads matches only the earlier selected record 9210479 ([EXECUTION_RESULTS:27](../../docs/EXECUTION_RESULTS_2026-10-02.md#L27)).
   - This also contradicts the sentence "The teammate guide retains the delivered configurations" at [NEXT_PHASE_RESULTS:35](../../docs/NEXT_PHASE_RESULTS_2026-10-04.md#L35).
   - Both settings passed and the acceptance criteria are unaffected. **Fix before handing the package to a teammate:** either set 16 threads, or state that this step reproduces 9210479 at 32 threads. Apply the fix to both copies; the archive includes `REPRODUCE.md`, so its recorded SHA would need re-recording.

2. **The GPU inventory script stops at its first failure.** [scnet-g0.sbatch:11](../../scripts/scnet-g0.sbatch#L11) uses `set -e`.
   - The `grep` at line 18 exits 1 if nothing matches. A failed `module load`, `hipcc` or `hy-smi` (lines 19–22) would skip the device variables, `rocminfo` and the MPI probes.
   - The risk is low, because job 874184 on 1 October ran this same partition, `dcu:Hygon:1` and `compiler/dtk/25.04.2` sequence successfully.
   - When reading 883172's output: if it stops early, check the `.err` file and do not conclude "no device".
   - For any resubmission, run the device probes before the module load and don't abort on a single failed probe.

3. **The archived launch-script copies aren't checked against their recorded hashes.**
   - The batch logs record the v1 hash `11584dfa…` (9213575, line 57) and the v2 hash `0d55fdd5…` (9213582 and 9213608).
   - [verify_runs.py:38-46](../../scripts/verify_runs.py#L38) doesn't check `launch_script_sha256`, and there's no hash listing for `source/`.
   - By reading, v2 matches `scripts/launch-comparison.sbatch`, and v1 differs only in the wall-time limit and the T6 branch.
   - Saving a `sha256sum` of `source/*` would make "exact v1/v2" checkable locally.

4. **The script that produced `bin-summary.json` isn't archived.** I recomputed all four of its fields by hand from `solver.log` and they match. Recording the rule in one line would be enough.

## Verified

- **Same-allocation comparisons**
  - 9213575 ran on c3n182 with v1; 9213608 ran on c3n39 with v2 and `ExcNodeList=c3n200`.
  - Both used Xeon 8488C, 96 CPUs and 450G.
  - All 14 records show 5 phases, `OFFICIAL_RESIDUAL_PASS`, zero process and rank exits, `COMPLETED 0:0`, and the source manifest `bf8148b5…` with every entry OK.
  - Memory limits in the verifier apply only to T01 and T09 (lines 33–34). The documents don't claim limits for T2, T6 or T7.
- **Frozen binaries**
  - The T7, T2 and T6 hashes equal `final_binary_sha256` from v19 build 9211860.
  - They differ from the accepted binaries only in the ELF `.comment` section.
  - T2-low and T7 at 16 ranks reproduce the delivered residuals exactly.
  - T6 at 32 threads gives 1.795509e-12 against the delivered 1.834771e-12. That is run-to-run variation from multithreaded PARDISO, not a method change.
- **Binding and threads**
  - Each iterative rank N is bound to core N (rank 95 to core 95).
  - All three T6 launches report "not bound".
  - PARDISO reports running on 32, 64 and 96 OpenMP threads, 15 times per run.
- **Reductions:** I recomputed 65.88%, 71.11% and 23.07% within 9213608, each against the delivered count.
- **Failed job 9213582**
  - The 64-rank launch shows bus errors and `rank-*.time` I/O errors, and exec failing with "Cannot send after transport endpoint shutdown".
  - Its 16-rank run passed numerically but is correctly `accepted: false`.
- **Budget**
  - Performance jobs: 610 + 654 + 1562 = 2826 s = 0.785 h.
  - With the T1 job: 2907 s = 0.8075 h.
  - Cumulative: 41,350 + 2,907 = 44,257 s = 12.2936 h.
  - At most two jobs ran at once, on different nodes.
- **T1 diagnostic**
  - The build flags match what CMake would give T1, and the frozen T1 solver is BoomerAMG-GMRES with KDim 30, max 300 iterations and rtol 1e-11.
  - The solver writes separate scaled arrays, so the `const` inputs the diagnostic reads stay original. D=1/√(row max) and x=Dy match `solver.c`.
  - The gather uses the same row partition as the loader.
  - Log cross-checks: the diagnostic's scaled residual 2.146581865425e-1 matches HYPRE's 2.146581865331e-1, and ‖Db‖ matches HYPRE's 3.297168. The original value 1.104663e3 matches the SDK check.
  - Each third holds 2,097,152 rows across 24 groups.
  - The bin shares recompute to 98.79896% and 58.86981%.
  - The "not met" result holds even for row subsets finer than the bins. Any rows carrying ≥90% of the original error carry more than 20% of the scaled error.
  - Memory: 5,677,342,720 and 5,677,342,681 bytes, both ≤9e9. The known-system control passed.
  - The documents keep their claims bounded: no sole cause, no claim T1 can't be solved, and no five-solve acceptance.
- **Candidate**
  - `SOURCE_COMMIT` is 6b7f675, the manifest has 118 entries with SHA `bf8148b5…`, and the README links all four new documents.

## Unresolved outside conditions

- The organizer contract is still open: package, MPI, launch settings, scaling placement, timing boundaries, tiers, ten-RHS handling, T3 precision and the deadline.
- Adopting the 96-rank and 96-thread settings depends on that contract.
- Independent teammate reproduction is pending.
- GPU job 883172's allocation and output are pending. No HIP solver or eligibility is claimed.
- LX2 still waits on recovery and backend details.
- T1, T3 and T2-high remain unsolved. T3 and T2-high jobs and T10 optimization stay deferred.
- No organizer or teammate messages and no portal submission are authorized.

## Limits of this audit

- I couldn't compute hashes, so the archive SHA, the byte-identity of the report and the archived script copies rest on recorded checks.
- Three repository-wide searches also scanned `资料/资源申请`, the private application originals. They matched nothing there and showed no content from it.
- In `.agents/`, I read only the candidate folder.
- I wrote no plan file and didn't call ExitPlanMode: your read-only instruction rules out writes, and neither tool is available in this session.

## Complete final focused review

**AUDIT VERDICT: PASS** for the corrected scope (items 1–4). Nothing is blocking and nothing needs to change. Codex edited the results doc during the audit; the final state passes.

## Findings

None blocking and none actionable.

## Verified

**1. T9 thread fix, archive SHA and candidate source**
- Both guide copies now read `--ntasks=1 --cpus-per-task=16 --mem=95G` at line 51: [REPRODUCE_CPU_2026-10-03.md:51](../../docs/REPRODUCE_CPU_2026-10-03.md#L51) and [candidate REPRODUCE.md:51](../../docs/REPRODUCE_CPU_2026-10-03.md#L51). The two copies are identical text. No `cpus-per-task=32` remains in `docs/` or in the candidate's Markdown files.
- The candidate's `remediation-baseline.sbatch:31` takes the OpenMP/MKL thread count from `SLURM_CPUS_PER_TASK`, so the guide now runs 16 threads. That matches:
  - the candidate's `README.md:24` and `SUBMISSION_CANDIDATE_2026-10-03.md:24`;
  - the delivered ten-RHS records in `full-rhs-runs.json`: T9 job 9210630 and T8 job 9210631 both record `"threads": 16`.
- The sentence at `NEXT_PHASE_RESULTS:35` ("the teammate guide retains the delivered configurations") is therefore now true.
- `NEXT_PHASE_RESULTS:66` gives `dae96e3f…a206a111`, the same value as `candidate-package-check-20261004.json:5`. The old `9860698b…` no longer appears in `docs/`, `README.md` or `logs/2026-10-03/`.
- The candidate's `source-sha256.txt` matches `logs/2026-10-01/execution/source/v19-selected/source-sha256.txt` line for line, all 118 entries.
  - The candidate's src/scripts/tests folders hold exactly those paths (91 + 22 + 5) and nothing else.
  - The manifest SHA `bf8148b5…` in `SOURCE_CHECK.txt` matches v19 build log 9211860, the next-phase batch logs and the package check.
  - `SOURCE_COMMIT` is 6b7f675.

**2. Archived source hashes**
- `source-sha256.txt` lists exactly the five files in `source/`. Each hash matches the raw logs:

| File | Hash | Raw record |
| --- | --- | --- |
| v1 launch script | `11584dfa…` | `9213575.out:57`; run-manifest records 1–4 |
| v2 launch script | `0d55fdd5…` | `9213582.out:57`, `9213608.out:57`; records 5–14; `failed-runs.json:23` |
| T1 `.c` | `3f4b1330…` | `9213576.out:57` |
| T1 `.sbatch` | `ab0015cd…` | `9213576.out:58` |
| `scnet-g0` | `65113fe1…` | No raw log yet, as expected, because 883172 hasn't run |

- By content, the archived v2, T1 `.c`/`.sbatch` and `scnet-g0` copies are identical to their `scripts/` versions. v1 differs only in `--time` (00:30 vs 00:45) and in lacking the T6 branch.

**3. `bin-summary.json`**
- `selection_rule` states the exact rule you specified.
- The first audit's log (`audit-1-stream.jsonl:305`) captured the 12-line file before the fix: `[[1,10]]`, `0.9879895795483219`, `0.5886980763839851`, `false`, `24`, with no `selection_rule` key. Those values are unchanged; the only edit is the added rule.
- Applying the rule to `solver.log:313-336`:
  - there are 24 nonempty bins;
  - block 1 / decade 10 alone holds at least 90% of ‖r‖², so the prefix is one bin;
  - that bin's Dr² share is about 58.9%, above 10%, so the trigger is `false`.
- This matches the predeclared heuristic in `STATUS_REVIEW_2026-10-02.md:60`. `NEXT_PHASE_RESULTS:60` closes the branch and claims neither a sole cause nor that T1 can't be solved.

**4. G0**
- `scripts/scnet-g0.sbatch` is unchanged and identical to its archived copy: 1 node, 1 task, 1 CPU, `dcu:Hygon:1`, `00:05:00`, a separate `.err` file, and `set -e` as before.
- `gpu-g0-status-20261004.json` shows 883172 `PENDING`, with 1/1/1 resources, 300 s, and no allocation or device output observed. That matches the script.
- The new `gpu-g0-observation-20261004.log` shows `None assigned`, and neither the `.out` nor the `.err` file exists yet. Nothing has been interpreted. The stderr requirement is recorded at `progress.md:3`.
- The only G0 job IDs in the next-phase logs are 882897 (immediate request, nodes busy) and 883172. `NEXT_PHASE_RESULTS:74` claims no resubmission, HIP build, GPU solver or eligibility.

## Observations (no action needed)
- [README.md:108](../../README.md#L108) still shows a T9 example at `--cpus-per-task=32`. It is the repository's general October deployment example (labelled "例如"). It matches accepted record 9210479 (`EXECUTION_RESULTS_2026-10-02.md:27`), says nothing about delivered configurations, and isn't in the archive. I'm noting it only so it isn't mistaken for a missed copy of the T9 fix; I couldn't diff it against HEAD.
- Files changed during this audit. `NEXT_PHASE_RESULTS` lines 66 and 74 were edited, and `candidate-package-check-20261004.json` and `gpu-g0-observation-20261004.log` appeared. I verified the final state. Re-reads confirmed the two guide copies, `bin-summary.json`, `source-sha256.txt`, `scnet-g0.sbatch` and the G0 status JSON were unchanged. Later edits aren't covered.

## Still open (external)
- The organizer contract: package, MPI/launch settings, scaling placement, timing boundaries, tiers, ten-RHS handling, T3 precision and closing time.
- Independent teammate reproduction.
- GPU job 883172's allocation and output, and working browser/terminal control.
- LX2 recovery and backend details.
- T1, T3 and T2-high remain unsolved. No organizer or teammate messages and no portal submission are authorized.

## Limits and read scope
- I can't compute hashes or open the tar.gz. The archive SHA, the report SHA `12c234ef…` (recorded nowhere else locally) and "16 threads inside the package" rest on Codex's recorded check. The staging copy does show 16.
- Every Glob/Grep had a scoped path: the task folder and candidate, `deliverables/`, `docs/`, and subfolders of `logs/`. I also read exact files: `README.md`, `STATUS_REVIEW_2026-10-02.md`, `EXECUTION_RESULTS_2026-10-02.md` and `full-rhs-runs.json`.
- I ran no repo-root searches, read or searched nothing under `资料/`, and hit no permission denials.
- I read `audit-1-stream.jsonl` only through narrow matches on the bin-summary keys. One match showed the parameters of the first audit's already-disclosed root search, with no private content.
- `audit-2-response.md` contains only a TLS connection error, with no review content.
- I wrote no plan file and didn't call ExitPlanMode, because those tools are unavailable and your instructions are read-only.

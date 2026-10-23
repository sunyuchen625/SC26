# Claude resource-optimization audit

Date: 23 October 2026, Asia/Shanghai. **Final verdict: PASS; no required fixes remain.**

Reviewer: local Claude Code **Opus 5.5 / max**, through the existing Claude Pro subscription. Codex implemented the change and verified the allocated runs. The final review covers **332 delivery paths**, based on `84fa8b60174509b0abb4409bb3fe48812fd103e4`. This report and the [audit trace](../../logs/2026-10-23/resource-optimization/claude-audit-verification.json) accompany that reviewed delivery. The trace records the exact hashes and tool targets.

The [GPU result](../T2_HIP_OPTIMIZATION_2026-10-23.md) demonstrates a same-allocation improvement from 12.739078 to 6.809676 s; exact final-source validation gives 6.860954 s. The [CPU controls](../T2_CPU_CONTROLS_2026-10-23.md), exact-source CPU regression and both GPU jobs complete 110 solves with their recorded numerical gates. The frozen CPU delivery remains the provisional primary submission path; S4 and formal eligibility retain their separate gates.

All interaction was in English. The first attempt was interrupted before a verdict after one filename-only `docs/*.md` query exceeded the narrow search list. The same conversation resumed with exact-file Read/Grep, returned PASS for 329 paths, then PASS for the final 332-path scope after provenance clarifications. All substantive file reads and the final-round tool targets were within the allowed local scope. The final trace records model `claude-opus-5-5`, plan mode, API key source `none` and no overage. Last server-reported session utilization was 22%, below the 95% pause threshold.

The final Claude response follows.

**Verdict: PASS.** The corrected 332-path delivery is accepted with no required fixes.

**Scope:** `review-scope.json` lists exactly 332 paths. The three new records are present (`:14`, `:15`, `:332`) with hashes at `:348`, `:349` and `:666`. Hashes are refreshed for the three edited files (`:344`, `:354`, `:375`). `docs/算力申请与使用方案.md` is still excluded (`:671`). `audit-3-fixes.diff` changes only those three files.

**Clarifications checked**
1. **GPU seconds:** `T2_HIP_RESULTS_2026-10-09.md:68` now reads 1,044 + 116 + 208 + 98 = 1,466 seconds, matching the ledger.
2. **CPU-control launch command:** `cpu-control-launch-command.txt:3-6` matches the run's own records on every point:
   - The batch hash `56063dac…` matches the executed copy (`sc26_launch_compare-9269822.out:57`) and the scope hash.
   - The frozen directory argument matches the binary and cache paths in the run output (`.out:179-180`).
   - The four configurations, 02:16 to 02:96, match the four launch-config lines.
   - `--mem=60G` explains the 450G script directive and matches the scheduler's request and allocation records (`.out:42-45`).

   `cpu-control-submission.log:4-5` shows the test-only 9269821 (a forecast start time, no allocation) and the actual job 9269822, consistent with the allocation ledger. I accept this as provenance from the executed payload. The payload file itself isn't published, but scheduler accounting and the batch output independently back it up.
3. **Final GPU accounting:** the follow-up query is now published (`scnet-962050-final-accounting.txt:1-2`), and `gpu-final-verification.json:232` points to it. The pasted row has exactly the requested 12 fields in order.
   - In `gpu-final-verification.json`, the source archive `b777cb…` stays nested (`:18`) and the evidence bundle has its own key (`:235`).
   - In `cpu-final-verification.json`, the source archive is nested at `:17` and the evidence bundle is at `:98`. That bundle hash `72d8ef3f…` matches `cpu-final-collection.log:5`.
4. **Warning locations:** `cpu-final-verification.json:96` now matches the raw records. Module lists and tar timestamp warnings are in the job stderr, OpenMPI warnings are in the small-case stderr, and the locale warnings are at `cpu-final-collection.log:1-2`.
5. **Garbled print label:** it correctly stays in the immutable submitted batch, and the hash assertion still governs.

**Old CPU identity — now settled.** In the 9213608 log, every T2 configuration (`sc26_launch_compare-9213608.out:1059-1063`, `1226-1230`, `1398-1402`, `1575-1579`) records:
- binary `bc629226…`
- cache `04a5885c…`
- inputs `ea937383…` and `3dc7f3a0…`

These are identical to 9269822. That confirms `T2_CPU_CONTROLS_2026-10-23.md:5` and `cpu-control-verification.json:9`. Only the node differs (c3n39 versus c3n17), and the docs don't claim the same node.

**Optional notes (not conditions)**
- `gpu-relax18-verification.json:13` and `cpu-control-verification.json:10` still use the top-level key `archive_sha256` for their evidence bundles. Neither file has a nested source-archive hash, and the docs call these "retrieved archive", so nothing is ambiguous.
- The output of the follow-up query's `date -Is` wasn't kept. The row carries its own scheduler timestamps, so this doesn't matter.

**Calendar correction:** my previous verdict wrongly implied the 18:00 result window had already closed. At 14:49:14 it was open, and all four jobs had finished by 14:17:51. No extension is needed for the completed work, and I'm not requiring any further runs.

**961897** remains only a dated test-only observation that consumed no allocation. I certify nothing beyond that.

**Still uncertified:** S4 and the platform choice, formal launcher/entry/timing eligibility, HIP admissibility, genuine teammate reproduction, LX2 native acceptance and portal submission. The frozen CPU delivery remains the provisional primary path.

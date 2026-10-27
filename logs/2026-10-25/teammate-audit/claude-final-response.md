## Final assessment: SC26 teammate audit (b83fe1c plus the CPU originals Codex retrieved)

I can now accept the CPU reproduction as computed, but the GitHub copy still needs repair. The broader F4 claim and the formal handoff are not accepted.

**What I checked myself in the originals:**
- **T2 memory:** the 16 per-rank peaks add up to 15,240,072 KiB, which is 15,605,833,728 B.
- **T7 memory:** the 16 per-rank peaks add up to 65,673,980 KiB, which is 67,250,155,520 B.
- **T9 memory:** `runs/t09-9275744/rhs-01/process.time:10` records 24,052,808 KiB, which is 24,630,075,392 B.
- **Exits:** all 33 of these timing records show `Exit status: 0`, and all four `process.exit` files contain `0`.

These match the replay and the teammate's `verify_runs_report.json`. So the summary's T2, T7 and T9 memory values are wrong.

**Other confirmations:**
- **Allocations:** the fresh sacct (`logs/2026-10-25/teammate-audit/cpu-current-sacct.log:4-8`) matches the guide's requests: 16 CPU/60G, 16/75G, 16/95G, 96/450G, and 4/16G for the build.
- **Stderr:** the `.err` files hold only OpenMPI openib/UCX device warnings and help-message notices. That includes an `ORTE_ERROR_LOG` line at `sc26_remediation-9275745.err:19`; with all 96 T5 ranks exiting 0, it has no effect on acceptance.
- **`solver.err`:** its absence is expected, because the script sends stderr to the Slurm `.err` file (`scripts/remediation-baseline.sbatch:12,56-59`).
- **Solver logs:** I agree there is no solver-log mismatch (`codex-delta-check.json:2`).

### Separate decisions
1. **CPU reproduction: accepted.** This is the CPU part of the internal F4 gate, not official eligibility (`verify_runs_report.json:328`).
   - These are new jobs, submitted 25 Oct at 16:30:36, so they are not the coordinator's earlier jobs (`docs/SC26_队友交接工单_2026-10-24.md:52`).
   - They ran after the 24 Oct 18:00 target (`工单:76`) but within the 29 Oct requirement (`docs/FORMAL_ENTRY_GPU_CONTRACT_2026-10-23.md:70`).
   - The Slurm user and account are the shared `sunyc` workspace that the guide prescribes (`docs/REPRODUCE_CPU_2026-10-03.md:9,19`). That the teammate personally ran the jobs rests on their statement and the dedicated `-scq` directory.
2. **Broader F4 claims (`docs/REPRODUCE_SCQ_2026-10-25.md:9`): not accepted.** There are no originals for GPU job 966565 or for LX2. F4's GPU part must also cover the *final* GPU source and an *accepted* launch (`FORMAL_ENTRY…:56`).
3. **Formal handoff: not accepted.** The contract items F1/F3-common and F2/F3-GPU are still open. Under `工单:76` and `FORMAL_ENTRY…:70`, GPU stays an experimental appendix unless the captain records a different decision. The frozen CPU package remains the provisional delivery.

### Remaining findings
- **P1: the portable CPU evidence is not on GitHub.** The paths at `logs/reproduce-scq-20261025/reproduction-runs.json:7,18-19` were not published, so the replay fails. Committing the retrieved originals fixes this; no new runs are needed.
- **P1: the GPU and LX2 completion claims have no raw evidence** (`REPRODUCE_SCQ…:9,24-35,45-48`). They are reported progress, not disproven.
- **P2: the summary table has wrong numbers** (`:19-21`). I downgraded this from my round-1 P1 because acceptance no longer depends on the summary.
- **P2: the GPU account and instant-queue advice** (`:44`) turns one unarchived submission attempt into a general rule.

### Next steps and acceptance criteria
1. **Publish the originals with a manifest whose paths resolve.** Done when, on a clean checkout, `scripts/verify_runs.py` exits 0, its output equals `verify_runs_report.json`, and the folder pointers in the summary resolve.
2. **Regenerate the summary table.** Done when it equals the replay output.
3. **Upload the 966565 originals.** That would establish an experimental reproduction of the 23 October preparation candidate. The GPU part of F4 additionally needs an accepted launch and the captain's selection.
4. **Upload a redacted LX2 transcript.** That would close only the credential/token item; `native_compute_ready: false` (`lx2-readiness-20261023.json:29`) still stands.
5. **Rewrite `:44` as a dated observation** that includes the Account and QOS from sacct.

### Review of `docs/reviews/TEAMMATE_PROGRESS_AUDIT_2026-10-25.md`
The report is fair: it accepts CPU on the strength of the originals, keeps evidence gaps separate from contract gates, and its findings are actionable. Exact corrections:
- **`:15`:** the uploaded `reproduction-sacct.log` has no Submit/Start/End columns. Say those times come from the new live query; only nodes, elapsed time and `COMPLETED 0:0` can be compared with the upload, and they match.
- **New sentence:** the CPU jobs ran 25 Oct 16:30:36–16:53:18, after the 24 Oct 18:00 target and before 29 Oct.
- **`:36` and `:75`:**
  - Add that the GPU part of F4 must cover the final source and an accepted launch.
  - Add that by default GPU stays an appendix unless the captain decides otherwise; the 966565 originals alone cannot make GPU eligible.
- **`:42`:** pin the archive identity: SHA256 `9425399b14fd759af2212aa808b6a604d0ea026e60e40325589ec44087f99e5d`, 69,392 bytes, 171 files (`cpu-original-collection.json:9-12`).
- **`:47`:** extract into a fresh empty directory (for example `d=$(mktemp -d)`) instead of `mkdir -p` on a fixed path.
- **`:69`:** "记录本次成功采用默认账户关联" states something not yet evidenced. Replace it with: record 966565's actual Account and QOS from sacct once provided.
- **Optional:** one clause noting what the `.err` files contain and that a missing `solver.err` is expected, since `cpu-original-collection.json:3-8` lists those files as "missing".

I used Read and Grep only and wrote no files.

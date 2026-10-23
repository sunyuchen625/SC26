# SC26 remaining plan and acceptance criteria

Date: 21 October 2026, Asia/Shanghai. **Status: approved for execution.** The user approved this revision and requested a new local project chat using GPT-6.1 Sol / max. This revision uses the [completed 14 October delivery](reviews/CLAUDE_EXECUTION_AUDIT_2026-10-14.md), the [14 October plan](NEXT_PLAN_ACCEPTANCE_2026-10-14.md), and the [dated resource/rule update](COMPUTE_STATUS_2026-10-21.md). Execute at the throughput permitted by actual platform grants and available capacity. Messages, official submission and changes to the work scope retain their own authorization boundaries.

## Judgment and priorities

The CPU candidate, report and reproduction preparation pass their recorded scope. Commit `5add951` was published after two local Claude review rounds ending in scoped PASS. The CPU archive's 118 entries and HIP archive's 89 entries match their accepted identities. S1 HIP known systems and S2 HIP-off CPU regression pass. These completed gates remain closed for their identified snapshots.

[Full original T2-low S3](T2_HIP_FULL_RESULTS_2026-10-21.md) now passes numerical acceptance in job 953826. Its prototype mean is 12.833244 s versus the experimental 96-rank CPU reference 7.036402 s. CPU retention is provisional against that reference until the actual contract identifies the permitted comparison setting. Native LX2 compute, actual formal-contract compliance, formal GPU timing/eligibility and genuine teammate reproduction remain incomplete. **The frozen CPU delivery remains the provisional primary path.** Optional work must fit the unchanged 24 October eligibility, 25 October freeze and 29 October acceptance milestones.


**23 October execution update:** [GPU preparation optimization](T2_GPU_PREPARATION_2026-10-23.md) passes 190 new solves. Exact preallocation/interpolation 18 gives 3.905254 s, repeated at 3.907222/3.903342 s. Exact-source HIP-off regression and two fresh 96-rank CPU controls pass, with actual round ranges recorded. Even the worst GPU mean is 44.471% below the faster historical 96-rank reference 7.036402 s. Experimental S4 performance passes against this measured setting. Formal permitted launcher/ranks, HIP entry/timing eligibility and genuine teammate reproduction remain open; the frozen CPU delivery remains provisional until the actual contract is settled. The 24 October eligibility and 25 October freeze gates retain their scope.

The previous **20 October GPU technical decision passed without S3/S4 completion**. The approved conditional reopening ends on 23 October. At the **21 October LX2 decision point**, authentication/toolchain/evidence readiness is insufficient: LX2 is an environment appendix by default. The inclusion opportunity below requires all readiness gates to be met promptly.

| Priority | Work | Decision / completion requirement |
| --- | --- | --- |
| 1 | CPU delivery and genuine teammate reproduction | Continue from the accepted frozen CPU package; settle formal entry/launcher/timing terms; obtain the independent build and four full-problem checks already defined in the reproduction guide. |
| 2 | GPU optimization and eligibility | Exact-source GPU/CPU validation and experimental S4 performance pass against measured 96-rank CPU. Settle actual permitted comparison setting and formal GPU entry/timing eligibility at the 24 October gate. |
| 3 | LX2 readiness checks; conditional minimal native T2-low | Resolve authentication, inbound transfer, native dependencies and permitted evidence retention by 22 October noon. Otherwise retain the environment appendix and close main-package porting for this submission. |

## Closed work and current evidence

| Gate | Result / identity | Treatment |
| --- | --- | --- |
| Frozen CPU release and launch campaign | Numerical source `6b7f675`; package/report/guide aligned in `5add951`. T2-low, T4–T7, and all ten RHS of T8–T10 pass. | Preserve the frozen archive and existing results. Choose original or later launch settings only with the corresponding report/job evidence and actual permission. |
| S1 HIP small systems | `897432`, `COMPLETED 0:0`, 20 allocated seconds; 3 systems × 5 solves, original float128 residuals <1e-10, known-solution errors ≤1e-6, device/provenance records verified. | Accepted for the identified source/library/binary. |
| S2 CPU regression | `9227847`, `COMPLETED 0:0`, 6 cases × 5 solves; maximum original residual `4.340013e-12`, maximum known-solution error `1.249001e-16`. | Accepted for that HIP-off snapshot. |
| S3 full T2-low | [953826](T2_HIP_FULL_RESULTS_2026-10-21.md), `COMPLETED 0:0`, 116 seconds, one DCU/16 CPUs/58 GiB, residual `5.938952e-7`; all source/device/memory/exit gates pass. | Numerical acceptance complete; prototype mean `12.833244 s` does not beat the experimental CPU reference. |
| LX2 | 21 October Kylin V10/aarch64 and proxy script verified; official ARM CMake ingress fails certificate-chain validation. Donau authentication and evidence route unresolved. | Environment appendix; native compute readiness remains open. |
| Publication audit | [14 October scoped PASS](reviews/CLAUDE_EXECUTION_AUDIT_2026-10-14.md), followed by push of `5add951`. | Covers that delivery scope. Subsequent changes need their own applicable validation/review. |

Accepted archive and binary identities are in the [T2 record](T2_HIP_RESULTS_2026-10-09.md) and [CPU candidate sheet](SUBMISSION_CANDIDATE_2026-10-03.md). T1, T3 and T2-high remain unresolved. The new residual-precision answer does not change that numerical result.

## Initial resource checks

Begin with focused read-only readiness checks on the relevant platforms. Record time, account, queried interface and actual output, and refresh observations when the platform state changes. Arrange independent compute jobs concurrently where verified grants and actual dependencies permit. Preserve other projects' allocations. An unchanged known failure returns a clear external blocker; it does not trigger repeated parameter or credential guesses.

**Commercial CPU:** the [21 October metadata check](../logs/2026-10-21/plan-execution/cpu-readiness.json) confirms the existing SSH route, empty own queue, UP partition, expected modules and unchanged package/dependency identities after Lustre maintenance. The scheduler's [test-only validation](../logs/2026-10-21/plan-execution/cpu-launch-validation.json) accepts the guide's build and four full-problem resource requests. Proceed to the genuine teammate's planned jobs under the actual grant; completed baseline checks retain their scope. Refresh the relevant environment facts if they change. The user reports that the committee has set no hard balance limit; expiry and actual platform restrictions remain to be checked.

**SCNet:** inspect only the team's current account/partition/QOS, single-DCU CPU/memory grant, expiry and own jobs through the configured observable route. A scheduler-accepted job ID establishes admission; a pending reason establishes queue status; assigned resources establish allocation. A valid pending job with `AssocGrpNodeLimit` is handled as a queue/limit condition requiring the actual scheduler/provider interpretation. The old account rejection cannot be explained solely by the group-wide queue notice. The fresh team query now directly allows the account, and job 953826 supplies actual admission, allocation and completion receipts.

**LX2:** use the already configured jumper/backend route. Recheck Donau token/authentication and `challenge26` access only after an actual changed state or provider correction; a new application-batch announcement alone does not justify repeating the three failed password attempts. Read installed authenticated CLI help or the provider's working template. Confirm the actual OS, native package route and a permitted installation prefix. Inspect the announced proxy script/instructions before using the inbound route. Keep credentials in their existing protected handling.

## GPU continuation, stop and appendix rules

The approved reopening replaced the expired 20 October decision window. Admission, first allocation and S3 numerical acceptance were achieved on 21 October; the observed comparison provisionally retains CPU against the experimental 96-rank reference. The original gates below remain the acceptance rules:

1. **By 22 October 12:00:** establish the team's effective grant and a valid single-DCU request. Reuse the verified S1 executable and matching installed HYPRE/source/data identities. The accepted 21 October request is 1 MPI process, 1 DCU, 16 CPUs and 58 GiB; the solver retains one OpenMP thread. It fits the current 3800-MiB-per-CPU rule and the observed 16-core socket layout. The allocated device first runs the three known systems with the accepted binary before full-data validation. Set job walltime from the workload and real platform limits. The tentative 32-core statement is not a configuration contract.
2. **Queue and allocation:** track accepted entries and their pending reasons, avoiding duplicate equivalent requests. Require the first full allocation to start by **23 October 12:00**. At that checkpoint, cancel this phase's still-pending full trial if it cannot enter the result window and close GPU main-package selection. Queue wait consumes calendar time, separately from allocation seconds. Retry an admission rejection after an actual correction to its cause.
3. **Complete S3 and the performance decision by 23 October 18:00.** Address observed runtime causes and repeat affected checks as needed. Revalidate affected S1/S2 evidence when source, dependency, toolchain or device changes invalidate it. Size and schedule the jobs according to measured requirements, platform capacity and the result deadline.
4. **Selection:** full numerical acceptance and the existing performance rule are both required for the GPU performance choice. Apply that rule to the fastest CPU setting permitted by the actual contract; the current CPU retention is provisional against the experimental 96-rank reference. Formal HIP entry/timing eligibility and the applicable local audit must be resolved by 24 October for inclusion.

A changed shared source requires the corresponding CPU regression evidence. Missing a dated admission/allocation/result gate ends this reopening; subsequent resource recovery can be recorded as an appendix without moving the freeze. Record all allocations and attempted runs, including failures.

**S3 acceptance remains unchanged:** five complete converged solves on original T2-low; default full-problem tolerance `1e-7` and recorded projection; original-system in-memory float128 relative residual `<1e-6`; matching input/source/library/cache/binary identities; source/runtime-backed checked device migrations and HYPRE dispatch with five policy/phase records; zero program/checker exits and actual successful scheduler completion. Record full-process host RSS within the real grant and honestly labelled GPU capacity/phase samples. OOM, allocation/resource overrun and failed numerical/exit gates fail the trial. The snapshots are sampled observations.

**S4 acceptance:** compare all five complete times and their mean with the fastest CPU setting permitted by the actual contract. The current experimental reference is 96-rank T2-low, `7.036402 s`. At least a 10% advantage is the preferred engineering target, approximately `6.333 s` against that reference. A smaller advantage needs identical GPU repeats and a contemporaneous T2 CPU control: the initial and reproduced GPU means must beat the fresh CPU mean with separated observed per-round ranges. Account for all comparable runs when deciding whether the advantage is reproducible. A result whose uncertainty remains unresolved at the decision deadline stays inconclusive. Preserve prototype-inclusive timing and formal transfer-excluded timing as their actual measured scopes.

The [same CPU comparison job](NEXT_PHASE_RESULTS_2026-10-04.md) measured `24.355135 s` at 16 ranks, `20.266965 s` at 32 ranks and `12.692410 s` at 64 ranks. GPU's `12.833244 s` prototype mean beats the 16- and 32-rank settings by more than 10%, so a contract capped at 32 ranks or fewer reopens S4 selection together with formal GPU entry/platform and transfer-excluded timing at the unchanged 24 October gate. CPU retention against the 96-rank experimental reference remains provisional until those terms are known.

## LX2 feasibility and acceptance

The newer transfer route is the 16 October instruction to source `/fs_real_a800/home/challenge26/env/set_proxy.sh` and bring files in over the internet. It supersedes planning around administrator-only upload. **Only inbound transfer is permitted.** Generated files/logs remain on the platform until a permitted verification/evidence arrangement is established. Existing Claude review remains local-only; an unavailable audit-evidence route is a real inclusion blocker.

By **22 October 12:00**, all four gates must be ready for any main-package porting:

| Gate | Required evidence |
| --- | --- |
| Authentication and compute | Valid Donau authentication, team queue/CPU/memory entitlement and an installed-help/provider-backed allocated-job route. |
| Inbound files | Accessible announced proxy/inbound source, exact identified project archive and dependency inputs; data archive read/extraction and identity verification planned on LX2. |
| Native dependency route | Actual OS/architecture compatibility, permitted install prefix, usable CMake ≥3.21, MPI and HYPRE, quadmath compile/link/run route, and real `.7z` extraction. Use compatible ARM packages or native builds. |
| Evidence and review | A resource-policy-compliant way to retain and review the identities, job/checker exits and raw numerical records required for acceptance and local audit. |

The announcement makes the contestants responsible for software installation. Read the [official requirements](https://www.hikunpeng.com/document/detail/zh/kunpenghpcs/hpckit/instg/KunpengHPCKit_install_004.html) against the actual OS before choosing a package or procedure. Start with the minimal T2-low MPI/HYPRE/quadmath build; use the existing internal BLAS/LAPACK configuration when applicable. A permission error on DevKit/OpenBLAS does not by itself require installing every suite component. x86 binaries/libraries cannot provide native ARM evidence.

When the readiness gates pass, build the native dependencies/application, run the known-system checks and validate original full T2-low on allocated compute nodes. Resolve observed defects and repeat affected checks as required. Use the actually granted cores, memory and job walltimes, with work scheduled to complete results by **23 October 18:00** and formal eligibility/auditable evidence by 24 October. Stop main-package work at a missed calendar gate; preserve the environment record as the appendix.

Native acceptance uses an identified ARM source/dependency/cache/binary chain, a successful allocated build and quadmath probe, three known systems with five solves each (original residual `<1e-10`, known-solution error `≤1e-6`, correct projection), then five complete full T2-low solves and original float128 residual `<1e-6`. Record real Donau completion/program/checker exits and memory within the actual grant. The existing 1/4-rank small-system cases are reused where the allocated MPI grant supports them; any untested rank setting remains outside the accepted scope. Evidence access must satisfy the inbound-only policy. An environment login or successful compilation alone is not full numerical acceptance.

Selecting an LX2 implementation additionally needs the actual allowed platform/scoring contract and its measured timing evidence. A native numerical pass alone does not replace the selected commercial CPU candidate.

## CPU delivery, contract and reproduction

Use `SC26_CPU_candidate_6b7f675.tar.gz`, SHA256 `dae96e3fa5c8dc4cf8d66469b34797a84a0f3d741d0f8f4d8b4884f16206a111`, as the preserved CPU basis. Original report settings and later measured 96-rank/thread settings already have separate source/job evidence in the candidate sheet. Match the final launch table and report to the actually allowed settings. Change code/dependencies only for an actual confirmed requirement, and validate the affected paths.

The existing [independent reproduction guide](REPRODUCE_CPU_2026-10-03.md) remains the internal project criterion: the teammate personally builds nine CPU targets, passes 24 known-solution cases and runs full T2-low, T7, T5 and T9 RHS01 in an independent directory. Require their own operator/date/account/directory, source manifest, cache and binary identities, new job IDs/resources/terminal states, five-solve records, original residuals and full-process memory/exit evidence. Preserve the guide's thresholds: T2-low/T7 `<1e-6`; T5 original residual `≤5e-9` plus all five internal convergence records; T9 RHS01 `<1e-8` and its recorded memory limit. Actual benign launcher warnings are retained with successful numerical/exit evidence. Repackaging prior Codex runs is not independent reproduction.

22 October remains the contract/reproduction review checkpoint: record what is received and who will complete the remaining work. Target full independent evidence by **24 October 18:00** for freeze preparation. The criterion is internal to this project; a delay is reported as an open gate, separately from any organizer rule.

The residual-precision question is partly resolved: the 15 October answer permits long double in the stated residual-validation context. Retain the existing float128 project checks and ask only the remaining output/check-interface questions. The T1 memory limit is **9 GiB**, per 19 October; preserve other problems' own limits. These two answers do not settle MPI, packaging, timing, tier selection or previously unresolved numerical cases. New T1/T3/T2-high or T7 GPU exploration requires its own work scope.

## Minimum external answers and reviewable drafts

The [updated recipient drafts](反馈稿_2026-10-14.md) contain the concrete questions. Sending remains a separate human-authorized action.

| Recipient | Smallest useful answer |
| --- | --- |
| SCNet resource provider | Current team account/partition/QOS and a 1-DCU/16-CPU/58-GiB allocation are verified; confirm the remaining authorization expiry. |
| LX2 resource provider | Correct team Donau authentication/queue access and give a working job/query example; supply the supported proxy CA/package route and the permitted evidence-retention/review method under inbound-only transfer. |
| Organizer test group | Provide the actual submission package/harness and per-problem launcher/check/timing contract, including permitted MPI/ranks/threads and platform/tier selection; confirm the task portal, timezone, final confirmation and receipt. The candidate sheet supplies the specific structural-analysis, transfer/units, multi-RHS and output questions where the supplied harness does not answer them. |
| Teammate | Confirm an actual independent reproduction operator/schedule and return the new build/job/check evidence by the stated checkpoint. |

## Calendar and resource use

All checkpoint times use **Asia/Shanghai**. The official portal timezone remains to be confirmed. The old 20 October GPU milestone is recorded as unmet; the conditional reopening above is the approved calendar change. The 21 October LX2 decision is recorded as appendix-by-default with a readiness opportunity. Resource recovery does not silently roll these windows forward.

| Date / time | Acceptance or decision |
| --- | --- |
| 21 October | Approved revision starts in a new project chat; CPU main path confirmed, completed S1/S2/publication scope retained. |
| 22 October 12:00 | GPU valid-grant/admission and LX2 four readiness gates close. Missing optional gates select appendix status. |
| 22 October | Existing contract/reproduction review; obtain actual answers/arrangements and list the residual gaps. |
| 23 October 12:00 | Latest first full GPU allocation start. |
| 23 October 18:00 | Optional full numerical/performance results close. |
| 24 October 18:00 | Main-package platform eligibility, applicable review and genuine reproduction evidence targeted complete; finalize selected configurations. Unready optional candidates become appendices. |
| 25 October | Freeze the selected validated CPU-based source/report/launch table and artifact identities. Unresolved contract/reproduction items remain explicitly open; artifact freeze alone does not establish official readiness. |
| 27 October | Verify already-frozen artifact identities, packaging and consistency. Required fixes are bounded to actual acceptance defects and receive affected checks/review. |
| 29 October | Final acceptance: numerical evidence, independent reproduction, actual contract, permitted configuration, report/package identities and submission procedure. An unresolved gate is reported to the user with its exact impact. |
| 30 October | Authorized official submission and receipt collection under the confirmed portal terms. The [official conference page](https://solver-conference.cn/solver26/index.html), read on 21 October, lists **30 October 24:00**. Prepare the verified package before the closing day. |

Recorded GPU use is **1160 seconds** over 15 completed allocations, including earlier failed allocations. The 21 October full trial adds 116 seconds and performs no compilation. Historical build/integration remains 1029 seconds; new device revalidation and full solving share the additional allocation, as recorded in the [ledger](../logs/2026-10-21/plan-execution/gpu-allocation-ledger.json). Track new use, including failures, and verify actual platform expiry and job-resource restrictions. Rejected submissions consume no allocation seconds; queue wait remains calendar time.

Recorded commercial CPU use is **12.3136 node-hours**. Use available verified CPU/GPU/LX2 capacity for the actual work and record each platform's allocations separately. Schedule independent tasks concurrently where allowed and preserve other projects' jobs. Compilation/numerical work always runs on allocated compute nodes. Readiness inspection, source/report preparation and metadata checks remain lightweight.

## Publication and authorization

Preserve current independent work, especially `docs/算力申请与使用方案.md`. Scope-specific source/dependency/contract changes receive the necessary affected validation. After actual validation, use the existing local Claude Code Opus 5.5/max subscription workflow for the exact deliverable scope: English interactions, plan/read-only, scoped local Read/Glob/Grep; no GitHub/web/cloud, credentials, private resource-application originals, commands, writes or delegation. Check the collaboration DISABLED file/charter and fresh native usage before calls and between rounds. At **95% session use**, pause and save the checkpoint.

The 14 October audit result remains historical acceptance for its reviewed scope. New material cannot inherit that verdict automatically. Codex resolves actual findings, obtains scoped PASS and then commits/pushes the reviewed changes under the standing conditional authorization. Formal portal submission requires the user's own instruction and actual final readiness.

## Changes from 14 October

- Close CPU delivery preparation, S1/S2 identity checks and publication at `5add951`; replace preparation work with genuine reproduction and actual-contract closure.
- Incorporate the restored-but-queued GPU announcements, preserve this team's different admission error, and execute the approved reopening after the missed 20 October decision.
- Incorporate LX2 internet ingress, inbound-only restriction and self-install responsibility; make authentication, native dependencies and auditable evidence joint readiness gates.
- Treat commercial CPU maintenance as past; request a minimal current readiness check instead of repeating completed baselines.
- Record long double and T1 9 GiB clarifications within their actual scope; keep existing numerical standards and the 25/29/30 October delivery calendar.

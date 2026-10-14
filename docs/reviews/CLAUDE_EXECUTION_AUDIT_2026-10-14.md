# SC26 publication audit

Date: 14 October 2026, Asia/Shanghai. Reviewer: local Claude Code **Opus 5.5 / max**, through the existing Claude Pro subscription. Conversation: `41a5c8f5-952a-49c3-9107-97b47130df39`. Final verdict: **PASS for the reviewed publication scope**.

The scope contains the T2 HIP implementation and batch entry points, S1/S2 numerical and provenance evidence, GPU build/location records, CPU delivery preparation, reproduction instructions, contract questions, feedback drafts and the approved plans. The final review covers 197 indexed paths against `d1c5bd160b5fd823c24e9f0f125f1f19cb7704e4`; the audit report and trace summary accompany that scope.

| Gate | Audit judgment | Evidence / limit |
| --- | --- | --- |
| Frozen CPU delivery preparation | PASS | [Cloud package check](../../logs/2026-10-14/plan-execution/cpu-candidate-check.json): 118 entries match accepted v19; archive/report identities preserved. [Candidate sheet](../SUBMISSION_CANDIDATE_2026-10-03.md) binds original report settings and later measured launch settings to their own jobs. |
| S1 HIP known systems | PASS | `897432`, `COMPLETED 0:0`, 20 seconds, one MPI process/one DCU. All three systems have five solves, policies and phases, zero exits, empty runtime errors and original float128 residuals below 1e-10. |
| S2 edited-source HIPOFF CPU regression | PASS | `9227847`, `COMPLETED 0:0`, 25 seconds; six cases and 30 solves. Fresh binary, CPU HYPRE, source manifest and submitted batch match the [identity check](../../logs/2026-10-14/plan-execution/delivery-identity-check.json). Captured OpenFabrics warnings are consistent with successful launcher/checker exits. |
| S3 full T2-low entry point | Statically ready; execution blocked | Same S1 binary, five solves, original residual <1e-6, identity/device/RSS gates and 45-minute bound. The corrected request was rejected for the account/partition combination before allocation. |
| S4 performance | Pending | Requires passing full-data S3 and the fastest CPU setting allowed by the actual contract. The experimental T2 reference remains 7.036402 s; the fixed decision rule remains in the [approved plan](../NEXT_PLAN_ACCEPTANCE_2026-10-14.md). |
| LX2 | Compute readiness unverified | SSH/node76/aarch64 confirmed; Donau authentication and usable native toolchain remain unresolved. |
| Formal delivery and teammate reproduction | Pending | Actual package/launcher/timing answers, portal timezone/receipt and genuine teammate build/job/check records remain open. |

The reviewer confirmed the HIP lifecycle, source-default CPU behavior, exact submitted S1/S2 scripts and library identities, current public timing/output differences, all budget arithmetic and the standalone organizer draft. Public plan links resolve to indexed records. The seven reviewed screenshots contain terminal evidence and no credentials.

The pinned HYPRE 2.33.0 matrix/vector migration entry points and matvec dispatch were read directly in the final review. Successful checked migrations, the identified HIP/non-unified library, the application source and the S1 device-policy records support the device path. This is source/runtime-backed evidence; GPU phase observations remain samples. The utility header declares the execution-policy helpers; their bodies were outside the final review's exact-file list.

Claude used only local Read/Glob/Grep in plan mode. [Trace verification](../../logs/2026-10-14/plan-execution/claude-audit-verification.json) records the two successful rounds, tool paths and usage observations. The fresh native usage display was checked before the audit and between rounds; the 95% pause threshold was not reached. Codex owns implementation, verification and Git integration.

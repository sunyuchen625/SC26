# SC26 full-data publication audit

Date: 23 October 2026, Asia/Shanghai. Reviewer: local Claude Code **Opus 5.5 / max**, through the existing Claude Pro subscription. Conversation: `e6a08391-f62a-4c75-bba1-f69667aaf7e0`. Final verdict: **PASS for the corrected 52-path publication scope. No required fix remains.**

The reviewed scope contains the full T2-low batch and job 953826 evidence, the conditional CPU/GPU comparison, dated CPU/SCNet/LX2 readiness records, delivery and reproduction preparation, feedback drafts and the approved plan. The 52 reviewed paths are bound to base `5add951dd7f3fb14ae92e726458373602ee0da6e` by the [trace verification and file hashes](../../logs/2026-10-23/plan-execution/claude-audit-verification.json). This report and that trace summary accompany the reviewed scope.

| Gate | Audit judgment | Evidence / limit |
| --- | --- | --- |
| Full original T2-low S3 | PASS | Job 953826, `COMPLETED 0:0`, 116 allocated seconds, one DCU / 16 CPUs / 58 GiB. Five complete solves, original in-memory float128 relative residual `5.938952e-7`, peak host RSS `5,651,876 KiB`, matching source/cache/library/binary/input/batch identities and successful checker exits. |
| Allocated-device checks | PASS | The accepted binary passed three known systems, five solves each, before the full problem. The identified HIP/non-unified HYPRE migration and execution-policy helper bodies and device matvec dispatch were read directly. Phase VRAM observations remain samples. |
| CPU/GPU performance choice | Provisional | GPU prototype mean `12.833244 s` trails the experimental 96-rank CPU reference `7.036402 s`, but beats the measured 16- and 32-rank CPU settings by more than 10%. Final S4 depends on the fastest CPU setting permitted by the actual contract and formal GPU entry/timing. The unchanged 24 October eligibility gate governs the conditional selection. |
| CPU delivery preparation | Accepted recorded scope | Frozen package/report identities and prior S1/S2 acceptance are preserved. The 21 October resource validations are `--test-only` non-allocations. Genuine teammate reproduction remains open. |
| LX2 | Environment appendix | Captured OS/proxy/certificate metadata is consistent. Native authentication, dependency and numerical acceptance remain unresolved; the 22 October readiness gate elapsed without the required evidence. |
| Formal delivery | Open | Actual launcher/platform/timing and submission contract, genuine reproduction and final configuration acceptance remain outstanding. |

The [full result](../T2_HIP_FULL_RESULTS_2026-10-21.md) distinguishes callback sums from the driver's outer five-round mean and links the matching CPU input hashes. The resource record attributes the captured node pin and `BadConstraints` reason to job 953802; job 953805 retains its own recorded accounting fields. CPU launch/query logs are labelled as extracts with the accounting command supplied.

Claude used local Read/Glob/Grep in plan mode. The trace records the actual scoped file queries, model, subscription channel and usage observations. The initial 21 October attempt stopped at the required 95% threshold; the same conversation resumed after the user's 23 October instruction. Fresh native usage after the final verdict was 25% session / 21% week. Codex owns implementation, verification and Git integration.

This PASS accepts the identified S3 evidence and consistency of the reviewed records. Final S4, the actual formal contract, genuine teammate reproduction, LX2 native acceptance and live resource state on 23 October remain outside that acceptance. The [approved plan](../NEXT_PLAN_ACCEPTANCE_2026-10-21.md) retains the remaining calendar gates.

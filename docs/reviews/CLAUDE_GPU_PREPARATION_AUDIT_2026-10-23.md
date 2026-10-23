# T2 GPU preparation — Claude publication audit

Date: 23 October 2026, Asia/Shanghai. **Final verdict: PASS for the scoped publication. No required fixes remain.**

Claude Code **Opus 5.5 / max** reviewed the local source and evidence through the existing Claude Pro subscription, conversation `ef1db968-de76-4675-954f-2de0efe1b081`. Both rounds used plan mode with only exact-file Read/Grep. The [verified trace](../../logs/2026-10-23/gpu-preparation/claude-audit-verification.json) records every tool target, source/artifact hashes and native usage observations. All requests stayed within the approved local scope; API key source was `none`, web requests were zero and no overage was used. Maximum streamed five-hour session use was **64%**, below the user's 95% pause threshold. Codex owns implementation, verification and Git publication.

The [result report](../T2_GPU_PREPARATION_2026-10-23.md) and its 577 frozen publication paths are accepted within this scope:

- HIP exact diagonal/offdiagonal row preallocation, interpolation 18 and complete per-round timing preserve the validated solver lifecycle. The source archive's 89 manifested entries and 91 members match the tested and staged source identities.
- GPU jobs `962398` and `962526` pass 150 new solves. Exact-source CPU regression `9270818` and repeated full control `9270819` pass another 40. Recovered job `960428` adds 40 separately recorded historical solves.
- Exact GPU means **3.905254 / 3.907222 / 3.903342 s** and all fifteen rounds are supported by the raw evidence. Even the worst mean is **44.4713%** below the fastest recorded 96-rank CPU reference, **7.036402 s**. GPU rounds **3.868–4.056 s** are fully separated from the ten fresh CPU rounds **8.356–9.683 s**. Experimental S4 passes for the stated prototype timing and measured CPU setting.
- The allocation reconciliation supports **2664 cumulative GPU seconds / 20 terminal allocations**, including prior failures, and **339 new CPU single-node seconds**, bringing tracked approximate CPU use to **12.574433 node-hours**.

The final review closes the documentation corrections: all eight historical logs are retained and parsed; the structural scan's **0.127542 s** cost and small convergence changes from HYPRE row ordering are quantified. Parent-source and diff review confirms that both round barriers and the complex-vector reset predate this change. The two timing reductions retain their distinct scopes. CPU timing drift is recorded without an unsupported causal explanation, and the faster historical comparison remains decisive.

Claude's final response states: “The documentation fixes are closed and the CPU evidence is complete and consistent. The experimental S4 performance result holds.” Codex independently checked all 192 CPU rank exits, source/archive identity, local document links and exact index bytes against the frozen review map. The unrelated resource-plan edit is preserved and excluded from publication.

Formal permitted launcher/ranks and comparison setting, HIP entry admissibility, transfer-excluded timing, official parser acceptance and genuine teammate reproduction remain open. The frozen CPU package remains the provisional formal delivery until those gates are settled. This audit accepts the documented numerical/performance publication; it does not certify an official competition score or multi-rank HIP.

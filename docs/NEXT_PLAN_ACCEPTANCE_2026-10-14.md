# SC26 execution plan and acceptance criteria

Date: 14 October 2026, Asia/Shanghai. Execution authorized by the user's instruction to open a new project chat and execute the plan. This update continues the [9 October approved plan](NEXT_PLAN_ACCEPTANCE_2026-10-09.md) using the completed tests and resource observations below. Its numerical, provenance, device and performance criteria continue to apply.

## Verified starting state

| Work / resource | Latest evidence | Execution consequence |
| --- | --- | --- |
| CPU candidate and launch campaign | Accepted within their recorded scope; implementation `6b7f675`, measurement/documentation HEAD `d1c5bd1`. T2-low, T4–T7 and all ten right-hand sides of T8–T10 pass. T1, T3 and T2-high remain unresolved. | Prepare the validated CPU delivery while resolving the actual submission contract. |
| S1 HIP small systems | Job `897432`, `COMPLETED 0:0`, 20 allocated seconds; three systems, five solves each; raw evidence retrieved and verified. | Close S1 for the identified source/library/binary. |
| S2 HIP-off CPU regression | Job `9227847`, `COMPLETED 0:0`, six cases and 30 solves from the same source archive. Maximum original residual `4.340013e-12`; maximum known-solution error `1.249001e-16`. | Close S2 for that snapshot. |
| S3 full T2 HIP | Both submissions were rejected before allocation. The corrected 18-CPU, 64-GiB request returns `Invalid account or account/partition combination specified`. The partition is UP; direct account membership is absent, while effective inheritance and the cause remain unknown. | Obtain effective account/partition/QOS and resource-grant facts before submitting the full trial. |
| LX2 | SSH login and password change complete; `node76`, `aarch64`, and the ten data-archive names verified. Donau scheduler authentication failed three times. Default CMake 3.16.6 has a missing root and is below the project's 3.21 minimum. MPI/HYPRE/7z and a usable CMake location remain unverified. | Resolve scheduler authentication and toolchain access before an allocated native ARM build. |
| Formal integration | Public-source receipts and a CPU reproduction guide exist. Actual launcher/package/precision/timing answers and genuine teammate build/job records remain incomplete. | These tasks proceed independently of optional platform recovery. |

The [T2 execution record](T2_HIP_RESULTS_2026-10-09.md), [LX2 record](华为平台接入进度.md) and [submission contract sheet](SUBMISSION_CANDIDATE_2026-10-03.md) contain the underlying evidence and identities. The source archive is `SC26_T2_HIP_source_20261009.tar.gz`, SHA256 `9708c99de61699a0c9d7452503ab07c97284ed3287b57185a816947d8de58ee0`. The accepted HIP executable is `7f02c33a25b0f30b80224b505e73a63a8f2dbda3f3cddd064003743fd6ea168d`.

## Execution order

1. Advance S5 CPU delivery preparation immediately: reconcile the candidate, selected launch settings, report and reproduction instructions with the actual contract evidence. Prepare focused organizer/resource questions and a teammate handoff. Outgoing messages and official portal submission each require the user's explicit authorization. The frozen candidate remains available while contract details are resolved.
2. Resume S3 when SCNet access is demonstrably restored. Ask the resource provider to verify the team's effective account/partition/QOS, currently allowed single-DCU CPU/memory request, balance and expiry. The 64-GiB request requires at least 18 CPUs under the observed 3800-MiB-per-CPU rule; actual permission for that combination still needs confirmation. Reuse the S1 binary and full script after checking transferred identities and the applicable allocation. Repeat affected tests only if source, dependency, device or toolchain changes create a real new validation need.
3. Resume LX2 after the provider supplies valid Donau authentication/queue access and readable software paths or a working submission example. Read the authenticated installed CLI help before writing the job entry. Start with T2-low's native ARM MPI/HYPRE/quadmath path, using internal BLAS/LAPACK where the existing HYPRE configuration supports it. Establish accessible CMake ≥3.21, MPI, HYPRE and a real 7z/extracted-data route. Build, link and run the float128 check in an allocated compute job. Then run bounded known-system checks before any full original T2-low trial.
4. Apply S4 to a passing full GPU candidate, and S6 to the selected validated submission candidate. Independent reproduction and formal eligibility are recorded separately from numerical acceptance.

All compilation and numerical work belongs on allocated cloud/organizer compute nodes. Scheduler-specific allocation and completion evidence must identify the actual host, resources and program/checker exits. LX2 uses its verified Donau interface; its receipt is evaluated according to that scheduler's actual states and exit reporting.

## Remaining acceptance gates

**S3, full T2-low:** one MPI process and one granted DCU; first allocation at most 45 minutes; default full-problem tolerance `1e-7` and recorded projection policy. Five complete converged solves and an original-system in-memory float128 relative residual `<1e-6` are required. Bind the data, source, dependency, cache and executable to the accepted snapshot. Retain source/runtime-backed device migrations and HYPRE device dispatch evidence, all five policy/phase records, actual scheduler completion and zero program/checker exits. Full-process host RSS must fit the actual allocation. GPU phase observations and capacity are labelled as samples. Actual OOM, resource overrun or solver/checker failure fails the gate. At most one corrective runtime retry may address an observed cause within the approved budget.

**CPU and LX2 regression:** evaluate actual program/checker status, original-system precision, five-solve completeness and matching provenance. Capture runtime warnings with the result; the already understood benign OpenFabrics warnings do not invalidate successful CPU checks. The unchanged S2 snapshot already passed. A native LX2 build must identify its own ARM dependencies/binary and validate its original data identities before full-scale acceptance.

**S4, performance:** compare the five complete solve times and mean with the fastest setting permitted by the actual contract. The current experimental CPU reference is T2-low at 96 ranks, `7.036402 s`. A validated mean at least 10% below the permitted reference is the preferred engineering target; approximately `6.333 s` against that current reference. A smaller advantage receives at most one identical GPU repeat and one contemporaneous T2 CPU control if needed. Both GPU means must beat the fresh CPU mean, with separated observed per-round ranges, to select the smaller advantage as reproducible. Record all attempts and the timing scope. Prototype timing includes its transfers/diagnostics; official transfer exclusion and HIP adapter admissibility depend on the actual contract.

**S5–S6, delivery:** settle the actual package and entry points, allowed MPI/ranks/threads, structural-analysis and numeric-preparation conventions, conversion/transfer timing, multi-RHS aggregation, tier selection and output/check precision. Validate the selected package under those agreed conditions. Obtain genuine teammate build/job/check evidence. The teammate gate is an internal project criterion. Unresolved problems and optional platform availability remain explicit coverage limits. Actual official eligibility requires actual contract evidence.

## Budget and schedule

The [GPU ledger](../logs/2026-10-14/plan-execution/gpu-budget.json) records 14 completed allocations, including failures: **1044 seconds** of the **16200-second (4.5-node-hour)** branch cap, and **1029 seconds** of the **7200-second (two-hour)** build/integration cap. Remaining engineering budget is **15156 seconds** and **6171 seconds**, respectively. Rejected submissions have zero allocated time. These engineering caps are separate from the platform's actual remaining credit. Tracked CPU use is **12.3136 node-hours**; retain the existing 18–25-node-hour planning range and at most two concurrent SC26 CPU jobs. Preserve other projects' allocations.

| Date | Checkpoint |
| --- | --- |
| 14–16 October | CPU delivery preparation, formal-question consolidation and reproduction handoff ready; check resource updates against actual submissions/authentication. |
| 16 October | Review whether GPU/LX2 access has recovered. If recovery is still blocked, continue the CPU delivery tasks and record the provider-dependent items. |
| By 20 October | Finish the bounded GPU technical/performance decision. A branch without full-data acceptance remains experimental evidence. |
| By 21 October | Decide LX2 inclusion feasibility from authenticated scheduling and a usable native toolchain. |
| 22 October | Review contract answers and genuine reproduction evidence. Unanswered items remain explicit assumptions/blockers. |
| By 24 October | Complete LX2 main-package validation and resolve GPU eligibility for inclusion. |
| 25 October | Freeze the selected validated candidate and its source/artifact identities. |
| 27 October | Verify the already-frozen artifacts. |
| 29 October | Final acceptance and submission readiness check. |
| 30 October | The 9 October official conference-page receipt records task submission at 24:00. Confirm the portal timezone, final confirmation and receipt procedure before official delivery. |

The CPU candidate remains the delivery basis if optional platforms do not recover in time. GPU timing or official speedup cannot be claimed from small systems alone. T7 GPU and new unresolved-problem experiments retain their separately scoped authorization requirement.

## Audit and integration

After the required validation for the delivered scope, Codex prepares the local evidence and exact diff for Claude Code **Opus 5.5 / max** through the existing subscription. Claude interactions are in English, use scoped local Read/Glob/Grep in plan/read-only mode, and exclude GitHub, web/cloud, credentials and private resource-application originals. Codex owns implementation and integration. Read the collaboration charter and check its global DISABLED file before any Harness call. Read fresh native session usage before the audit and between rounds; at **95%**, pause and save the exact checkpoint.

Resolve actual audit findings and obtain a scoped PASS before Codex commits and pushes the reviewed changes to the existing GitHub remote under the standing authorization. Numerical, performance, publication and official submission conclusions retain their own evidence scopes.

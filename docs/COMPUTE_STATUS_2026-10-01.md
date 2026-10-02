# SolverChallenge26 compute status

Infrastructure status date: 1 October 2026; execution update: 2 October 2026, Asia/Shanghai. Team: CUDA OOM!, Ocean University of China.

This document reconciles the latest updates in the Codex chat “核查竞赛群算力资源” (thread `01a0d246-ce59-7b90-85ab-854b63965a46`) with the current local resource records. The thread's completed checks are the evidence; this document does not represent a new connection or numerical experiment. It supersedes the compute-access section of the 30 September project brief for the planning task.

## Current availability

| Platform | Demonstrated state | Remaining boundary |
| --- | --- | --- |
| Commercial CPU, Yancheng | Login, Slurm partition and all ten input directories checked again on 1 October; existing full-scale numerical baselines available | Expiry and formal submission interface unknown |
| Domestic GPU, SCNet/Hygon | Team login, data-directory access and an allocated one-DCU scheduler job demonstrated on 1 October | No HIP solver or full-scale numerical result yet; team quota, expiry and two-card allocation unknown |
| Domestic CPU, Huawei/LX2 | Application, jumper authorization, Windows desktop and MobaXterm access completed | Compute environment scheduled for holiday maintenance; backend node details and actual computation unverified |

The domestic CPU outage is expected from the staff notice, rather than an unresolved application submission. The user approved the execution plan on 1 October. Commercial CPU work and the scoped GPU feasibility branch can proceed within its budgets and gates. Domestic CPU work should wait for recovery and backend connection information.

## Commercial CPU

The 1 October resource chat records successful SSH login to `c3ln01` as `sunyc`, partition `qhn` in the `up` state, and all ten problem directories readable. The account had no active jobs at that check.

- Connection: `sunyc@122.228.252.34`, port `6084`; staff confirmed direct SSH without a VPN.
- Work directory: `/data/home/sunyc/solverchallenge26`.
- Competition data: `/data/home/maorz/SolverChallenge26-TenProblems`.
- Recorded competition specification: Intel Xeon Platinum 8488C, 96 cores, 512 GB DDR5.
- Validated baseline toolchain: GCC 11.3.0, OpenMPI 4.1.8, CMake 3.24.2, HYPRE 2.33.0 and oneMKL 2022.0.0.
- Existing direct runs: one MPI rank and 96 OpenMP threads. Iterative rank counts are recorded per problem, including 32 for T2 and 8 for the T1 memory-constrained trial.
- The user confirmed on 1 October during execution that the commercial CPU has no platform machine-time quota. The approved project budget remains 18–25 node-hours.
- The account association previously allowed up to four nodes across the user's projects. Each competition experiment uses one node. That association is not a competition allowance, and other projects must not be disturbed.

The September original-system float128 checks pass for T2-low, T5, T6, T7, and all ten RHS of T8, T9 and T10. The [2 October execution results](EXECUTION_RESULTS_2026-10-02.md) record normal five-solve acceptance for the revised T2-low/T4/T5/T6/T7 configurations and all thirty RHS of T8/T9/T10, plus T5's convergence margin on two nodes and at 64/96 ranks. These are local numerical results, with no accepted formal submission or official score evidenced.

Execution access update, 2 October: SSH recovered after the user's midday update. The [recovered job accounting](../logs/2026-10-01/execution/jobs-recovery-20261002.log) confirms completed T8/T9 all-RHS jobs and all four T5 margin runs. The [final accounting](../logs/2026-10-01/execution/jobs-final-accounting-20261002.log) includes the ten completed final-source T10 jobs; all current results are archived. Execution used 11.4861 tracked single-node hours with at most two running SC26 jobs. The [01:50 refusal](../logs/2026-10-01/execution/connection-status-20261002.log) records the earlier access interruption.

## Domestic GPU: an allocated single card has been verified

Staff announced GPU resource distribution on 29 September at 15:54 and confirmed the manual's web workflow at 17:53. The 1 October resource thread then established the team's actual access:

- SCNet web username: `TravisSun`; Linux user: `travissun`.
- Region: 华中一区【A区】 (Central China Region 1, Area A).
- Login node: `zz-login01`.
- Slurm partition: `hx1hdnormal`, reported `up`, maximum time `3-00:00:00`.
- Data: `/public/share/ac3k88uz8y/SolverChallenge26-TenProblems`; all ten directories listed successfully.
- The pool reports node GRES `dcu:Hygon:8`. This describes a pool node, not the team's entitlement or the allowed competition configuration.

Job `874184` requested one node, one CPU and one Hygon DCU with a one-minute limit, using `srun --immediate=10 -p hx1hdnormal -N 1 -n 1 -c 1 --gres=dcu:Hygon:1 -t 00:01:00`. It ran hostname, compiler-version and device-state checks on `f11r2n01`, completed in two seconds with state `COMPLETED` and exit `0:0`, and released its resources. The account queue was empty afterward.

The loaded module was `compiler/dtk/25.04.2`; `hipcc --version` reported dcc `25.08.0-0` and clang `17.0.0`. The module name and reported compiler version are distinct observations. `hy-smi` reported one visible device in the `Normal` state. This is infrastructure verification, not compilation or execution of a solver kernel.

The earlier saved competition specification is 32 CPU cores, 128 GB host memory and two BW1000 DCUs. The saved manual lists 64 GiB per card and target architecture `gfx936`. Actual hardware and the permitted CPU/card allocation must be checked before a solver build or benchmark. A visible single-card allocation does not prove a two-card allocation, and the pool's eight-card GRES must not be treated as permission to use eight cards.

This access changes the 30 September audit's GPU availability assessment. It makes a bounded porting feasibility experiment possible; it does not show that the current CPU algorithms, MKL dependency or their memory footprint fit the GPU platform. Existing T5 MGR process-peak sums are about 203 GB and T10 process peak is about 124.845 GiB, so their current CPU memory use cannot be assumed compatible with a 128 GB host.

## Domestic CPU: access authorized, computation deferred during maintenance

The three individual undertakings and application were submitted on 25 September at 14:42. Staff's 29 September notice said to use the application-time jumper account and change the initial password after login. Passwords are outside this planning document.

On 1 October the user completed login. The jumper page showed “欢迎 travissun” and `10.15.83.48_RDP`. Windows desktop access and MobaXterm Professional were subsequently verified. The older 401 unauthorized result is superseded by these observations.

`10.15.83.48` is the Windows jump desktop, not a demonstrated compute-node endpoint. Its RDP link displayed expiry `2026-11-26 00:00:00`; this is the link's validity, not a confirmed compute allowance or lease. MobaXterm's `User sessions` list was empty. No backend compute-node IP, SSH port, account or authentication method was available in the observed window.

On 30 September at 14:36, staff said the Huawei environment would power down for maintenance on 1 October and recover after the holiday. No exact recovery date was supplied. The desktop remaining accessible does not establish that the backend is running. The latest resource-thread conclusion is to defer domestic CPU computation until staff confirms recovery and supplies the missing connection information. Do not assume an 8 October restart or repeatedly retry the same access during the announced outage.

The saved competition specification is LX2, 608 cores, 1024 GB DDR5 plus 64 GB HBM. No toolchain, scheduler, input path or successful solver job has been established on that backend.

## Organizer statements relevant to planning

The resource thread records these group statements:

- 29 September 17:51: commercial CPU access uses direct SSH, without a VPN.
- 29 September 18:10: computation must not run on any login node.
- 29 September 15:54 and 17:53: GPU resources distributed; use the manual's web workflow.
- 30 September 13:38: use organizer-provided machines; across the three platforms, the fastest time is preferred.
- 30 September 14:36: Huawei maintenance on 1 October, recovery after the holiday, without a date.

The fastest-platform principle resolves the audit's high-level uncertainty about choosing among the three platforms. Per-problem aggregation, accuracy-tier submission, multi-RHS invocation/reuse and the formal portal interface remain unverified. It does not establish that all three platforms are mandatory.

## Relationship to the audit and planning scope

The 30 September audit remains the numerical and code-review starting point. Resource claims that have changed are explicitly reconciled here:

| Audit issue | Current evidence |
| --- | --- |
| No allocated GPU region demonstrated | Closed at infrastructure level by login and job 874184; solver portability remains open |
| Domestic CPU jumper authorization absent | Authorization and desktop access demonstrated; backend access and holiday recovery remain open |
| Platform selection rule unclear | Staff's fastest-of-three statement is available; formal scoring mechanics still need confirmation |
| Commercial CPU allowance | User confirmed no platform machine-time quota; project budget remains bounded |
| GPU/LX2 allowance, expiry and platform-specific submission requirements | Still unknown |
| Personal application files not excluded from version control | Current local `.gitignore` now excludes personal undertakings and the application receipt; the official access guide is retained |
| Structure-only direct analysis, source defaults and T5 margin | Current CPU implementation and numerical acceptance completed; see the 2 October results and audit |
| Formal eligibility, multi-RHS timing/reuse and teammate reproduction | Still require organizer interface confirmation and independent teammate evidence |

The user approved [the execution plan](EXECUTION_PLAN_2026-10-01.md) on 1 October. Required CPU validation is complete and the [local Claude Opus 5.5 max audit](reviews/CLAUDE_EXECUTION_AUDIT_2026-10-02.md) returned PASS. GitHub delivery is authorized following this validation and audit. Organizer messages and formal portal submission require separate authorization.

## Local evidence

- Source conversation: `codex://threads/01a0d246-ce59-7b90-85ab-854b63965a46`, “核查竞赛群算力资源”, latest completed resource updates on 1 October.
- [Current resource record](算力申请与使用方案.md).
- [Huawei access progress](华为平台接入进度.md).
- [30 September project brief](PROJECT_BRIEF.md), a dated background snapshot.
- [30 September independent audit](reviews/CLAUDE_AUDIT_2026-09-30.md).
- [Baseline reports](baselines/), original numerical logs under `logs/`, and current source/scripts/tests.

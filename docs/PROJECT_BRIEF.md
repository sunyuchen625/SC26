# SolverChallenge26 project brief

Current protocol: **27 October 2026, after the 15:38 official test-flow update**, Asia/Shanghai. CUDA OOM! is an Ocean University of China team. Sun Yuchen coordinates the team; Zhou Junzhe and Su Chengqi are teammates. Start with the [delivery plan](DELIVERY_PLAN_2026-10-27.md), [work order](SC26_队友交接工单_2026-10-27.md) and [current rules](OFFICIAL_TESTING_RULES_2026-10-27.md).

## Current formal protocol

The [new official template](../资料/SolverChallenge26报告模板_2026-10-27流程更新.docx) requires five complete warmup runs followed by five consecutive official runs. Start the official timer before run 6 and stop after run 10 completes. The reported score is the official accumulated time divided by five, in **milliseconds**.

Initialization, data allocation, solver/matrix/vector handle creation and destruction, and CPU-to-GPU transfer are excluded. Each of all ten runs must independently redo its necessary analysis, factorization, preprocessing and solve. Handle reuse is not permission to reuse numerical factors, preconditioners or an earlier solution. Coordinate-preserving storage conversion may be excluded; row/column permutations remain counted. Official correctness and memory interfaces are required.

The existing driver and callback structure still implement the old five-run experiment. No compliant new 5+5 score has been observed. Merely increasing the loop bound or multiplying old seconds by 1000 is insufficient. The work order assigns the smallest boundary/lifecycle adaptation, affected small-system checks, new complete measurements and videos, final implementation reproduction and evidence validation. Numerical algorithms, input identities and dependencies need not be redesigned for this change.

## Historical evidence that remains valid in its scope

CPU candidate `SC26_CPU_candidate_6b7f675.tar.gz`, SHA256 `dae96e3fa5c8dc4cf8d66469b34797a84a0f3d741d0f8f4d8b4884f16206a111`, has 118 manifested entries from 6b7f675. Old-protocol full-scale records pass T2-low, T4–T7 and ten RHS each for T8/T9/T10. T1, T3 and T2-high remain unresolved. Su Chengqi's build 9275741 passed 24 known cases; four CPU reproduction jobs have portable original records and accepted archival replay.

GPU candidate `SC26_T2_HIP_preparation_20261023.tar.gz`, SHA256 `f9482721a702b88d4e1b5e87957f59a8391215eb1938a8599bfc055e1e1c1e3a`, has 89 manifested entries. The old T2 experiment optimized IJ preallocation, interpolation 18 and l1-Jacobi 18. Independent job 966565 has a new build, three on-node known-solution receipts, five old-protocol full rounds averaging 3.902198 s, original float128 residual 5.896126e-7 and successful exit/accounting. The [historical summary](REPRODUCE_SCQ_2026-10-25.md) preserves these values without relabelling them as new scores. Job 966318 has a different manifest and stays separate. Small answer vectors were intentionally excluded; onsite receipts remain, while local elementwise comparison is unavailable. Binary identities use original receipts.

`verify_runs.py` and `audit_handoff.py` replay the historical five-round records. They do not qualify a new 5+5 result. Any changed final source, timer, entry, runtime or resources needs its affected validation and true operator-run evidence.

## Resources and delivery

CPU remains the delivery mainline, GPU T2 a conditional candidate. LX2 remains an [environment appendix](LX2_ENVIRONMENT_APPENDIX_2026-10-24.md): a captain-forwarded teammate transcription reports 24 October 22:01–22:14 SSH/dlogin and queue recovery, with screenshots/recording retained by the teammate. No native build or compute job exists; trusted proxy CA and aarch64 MPI/CMake/HYPRE remain unresolved. No restricted log export or new LX2 experiment is scheduled in this round.

The validated CPU stack includes GCC 11.3.0 / OpenMPI 4.1.8 / CMake 3.24.2 / HYPRE 2.33.0 / oneMKL 2022.0.0. GPU uses assigned SCNet BW1000/gfx936, DTK/HIP and the recorded HYPRE installation. Current queue/grant availability must be checked before new jobs. Builds and numerical runs use allocated compute nodes, preserving other project allocations.

The email entrance remains **solverchallenge@sina.com**, subject `SolverChallenge26材料提交_队伍名称_版本号`, archive `SolverChallenge26_队伍名称_版本号.zip`. Submit report, per-problem/platform source/scripts/Markdown instructions, and complete job-submission-to-success videos of the final flow. Large videos may use accessible links and extraction codes. The teacher's 25 October reply says routine unified online checking is not planned unless results are disputed.

On 27 October evening confirm task owners and timer boundaries; on 28 October pass affected small cases and start full5+5 recordings, especially long RHS tasks; on 29 October validate evidence and review the final report/package; target captain-confirmed email submission by 30 October 12:00. The existing published deadline is 30 October 24:00 without an explicit timezone; internal scheduling uses Asia/Shanghai. A seven-day extension is only a recommendation, not an approved change. No contest email is part of this documentation release.

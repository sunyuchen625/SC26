# SolverChallenge26 project brief

Updated 27 October 2026, Asia/Shanghai. CUDA OOM! is an Ocean University of China team implementing solvers for ten sparse engineering systems. Sun Yuchen coordinates the team; Zhou Junzhe and Su Chengqi are teammates. The current execution entry is the [delivery plan](DELIVERY_PLAN_2026-10-27.md) and [work order](SC26_队友交接工单_2026-10-24.md).

## Accepted experimental evidence

The CPU candidate `SC26_CPU_candidate_6b7f675.tar.gz`, SHA256 `dae96e3fa5c8dc4cf8d66469b34797a84a0f3d741d0f8f4d8b4884f16206a111`, retains 118 manifested source/script/test files from 6b7f675. T2-low, T4–T7 and ten RHS each for T8/T9/T10 have passing full-scale records. T1, T3 and T2-high remain unresolved. [CPU results](CPU_RESULTS.md) distinguish actual configurations.

The HIP candidate `SC26_T2_HIP_preparation_20261023.tar.gz`, SHA256 `f9482721a702b88d4e1b5e87957f59a8391215eb1938a8599bfc055e1e1c1e3a`, retains 89 manifested entries. Exact IJ preallocation, interpolation 18 and l1-Jacobi 18 produced the 23 October 3.903–3.907 s experimental repeats and S4 improvement over the measured CPU controls. Original-system float128 relative residual is 5.896126e-7.

Su Chengqi's independent CPU build 9275741 passed 24 known solutions. Four full CPU runs have portable provenance, timing, exits and successful accounting. GPU job 966565 in a separate directory has a new build, three on-node known-solution receipts, full T2-low residual/exit/accounting records and five rounds averaging 3.902198 s. The [reproduction summary](REPRODUCE_SCQ_2026-10-25.md) and `scripts/audit_handoff.py` expose the replayed scope. GPU 966318 has a different manifest and is retained separately. Binary identities use original receipts; deliberately excluded small-case vectors cannot be compared elementwise locally.

## Current submission requirements

The [official report template](../资料/SolverChallenge26报告模板_2026-10-26官网下载.docx) supplies the email entrance **solverchallenge@sina.com**, subject `SolverChallenge26材料提交_队伍名称_版本号`, and archive name `SolverChallenge26_队伍名称_版本号.zip`. It requires report, source/run scripts with per-problem/platform Markdown instructions, and complete job-submission-to-success videos. Large videos may use accessible links and extraction codes in the email. The teacher's25October reply says routine unified online checking is not planned unless results are disputed.

There are exactly five trials INCLUDING hardware warmup, averaged together. Each trial constructs, solves with and releases its components. CPU-to-GPU transfer is excluded; coordinate-preserving storage conversion may be excluded, while row/column permutations and numerical setup remain counted. Official example correctness and memory interfaces are required; checking precision may differ from solve precision. [Requirements and remaining checks](FORMAL_ENTRY_GPU_CONTRACT_2026-10-23.md) identify the final timer, HIP entry, device completion and actual resource/metrics questions.

## Remaining delivery work

CPU remains the mainline and GPU T2 a conditional choice for the captain. Existing archival acceptance does not establish final video availability or qualify a changed source/entry/runtime/resource configuration. Reuse applicable evidence and validate only affected changes. Record memory metrics separately: official framework output, conservative rank RSS sum and sampled device use have different meanings.

On 27 October, assign the final configuration/video/report tasks. Complete necessary alignment, recording and report work on 28 October; review and accept on 29 October; target captain-confirmed email submission by 30 October 12:00 Asia/Shanghai. The latest successfully checked official notice says 30 October 24:00 without explicit timezone. A seven-day extension is recommended, not approved; if officially granted from 30 October, the date would be 6 November. Continue the original schedule until a new notice is received.

LX2 stays an [environment appendix](LX2_ENVIRONMENT_APPENDIX_2026-10-24.md). A teammate terminal transcription supplied by the captain reports 24 October 22:01–22:14 SSH/dlogin and queue/node queries succeeding, with original screenshots/recording retained by the teammate. It is not a fresh observation of capacity. No native build or computation has been submitted; trusted proxy CA and aarch64 MPI/CMake/HYPRE remain unresolved.

Current solver source is under `资料/solverchallenge26_sample_code/`, based on upstream b66421483501021dd84aa10fc494f1dbf8e65958 with its MIT license. Validated CPU software includes GCC 11.3.0 / OpenMPI 4.1.8 / CMake 3.24.2 / HYPRE 2.33.0 / oneMKL 2022.0.0. GPU uses the assigned SCNet BW1000/gfx936 device, DTK/HIP and the recorded HYPRE install. Builds and solvers run on allocated compute nodes. Credentials are handed over privately.

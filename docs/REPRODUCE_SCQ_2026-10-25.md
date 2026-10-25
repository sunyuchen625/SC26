# CUDA OOM! 队友独立复现记录与平台实操避坑指南（执行人：`scq`）

日期：2026-10-25（Asia/Shanghai）  
执行人：苏承起（`scq`）  
对照工单：[SC26 正式交付收尾工单](SC26_队友交接工单_2026-10-24.md)、[CPU 独立复现指南](REPRODUCE_CPU_2026-10-03.md)、[交付候选与配置](SUBMISSION_CANDIDATE_2026-10-03.md)

## 一、独立复现总体结论

已在商用 CPU（`qhn`）与国产 GPU（SCNet 华中一区【A区】`hx1hdnormal`）各自的本人独立目录下，从冻结候选包与 GPU 准备优化候选源码完成了全新编译、已知解验证与全量五轮求解。所有复现项均一次性通过 `scripts/verify_runs.py` 与 `tests/check_result.py` 校验（`accepted: true`），内部独立复现门禁（F4）已闭环。同时已完成国产 CPU（LX2 `node76`）密码重置后的 SSH 与 Donau `dlogin` 调度 token 认证核验。

## 二、商用 CPU 四项全量复现结果 (`logs/2026-10-25/reproduce-scq/cpu/`)

- **独立工作目录**：`/data/home/sunyc/solverchallenge26/reproduce-20261024-scq`
- **候选包身份**：`SC26_CPU_candidate_6b7f675.tar.gz`（SHA256: `dae96e3fa5c8dc4cf8d66469b34797a84a0f3d741d0f8f4d8b4884f16206a111`，`SOURCE_COMMIT`: `6b7f675ecaa6949815a3a77f95467fc35f8d5bbf`，118 项源码清单 `bf8148b56bf20d4c0249b24c8d9540c4212cec153760944f5b38b20137ee68a9` 全数校验通过）
- **构建与已知解作业**：Job `9275741`（节点 `c3n91`，状态 `COMPLETED 0:0`，耗时 `00:00:37`，9 个 CPU 目标构建成功，24 个已知解案例 `KNOWN_SOLUTION_PASS` 24/24 通过）

| 赛题 | 作业号 | 节点 | 进程 × 线程 | 五轮阶段均时 (`analyse` / `prep`或`factor` / `solve`) | 框架五轮均时 (`framework_mean_seconds`) | 原始系统 `float128` 相对残差 | 全程各进程峰值内存求和 | `verify_runs.py` 结论 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **T2 低档** | `9275742` | `c3n06` | `16 × 1` | `0.008189 s` / `21.742048 s` / `6.548338 s` | `28.390603 s` | `5.885605e-07` (`< 1e-6`) | `15,603,830,784 B` (15.604 GB) | `accepted: true` |
| **T7** | `9275743` | `c3n06` | `16 × 1` | `0.010479 s` / `4.454046 s` / `17.554666 s` | `22.023256 s` | `1.601450e-09` (`< 1e-6`, `conv=[1]*5`) | `67,259,156,480 B` (67.259 GB) | `accepted: true` |
| **T9 RHS01** | `9275744` | `c3n24` | `1 × 16` | `67.691993 s` / `9.049722 s` / `1.557171 s` | `78.363634 s` | `1.407011e-16` (`< 1e-8`, `pivots=[168]*5`) | `24,636,076,032 B` (24.636 GB `< 100 GB`) | `accepted: true` |
| **T5** | `9275745` | `c3n99` | `96 × 1` | `0.003328 s` / `10.312005 s` / `176.673475 s` | `186.989168 s` | `2.576043e-09` (`≤ 5e-9`, `conv=[1]*5`) | `202,786,639,872 B` (202.787 GB) | `accepted: true` |

## 三、国产 GPU (SCNet DCU) T2 低档独立复现结果 (`logs/2026-10-25/reproduce-scq/gpu/`)

- **独立工作目录**：`/public/home/travissun/sc26-hip-20261007/reproduce-gpu-20261024-scq`
- **源码身份**：父提交 `d09163c18ce629d65d55c0e6316b9755b7e2975d`，`source-sha256.txt` 为 `edcbf44abeee448a736cc01bfe16ac58a052a74e44a132a2d67a2f35e0080d6b`（89 项全 `OK`），`src/problems/problem02/solver.c` 为 `ea585ebaf584fa059946ba40371378a03b5404629f841e66c286eb1a8f2856f4`，`src/apps/MPI_iterative_solver.c` 为 `34f19d4985ded7685eeca2f1f07e6dfec0af91c9039dba668be75a6dedf2a6d0`。
- **新构建身份（Job `966565`）**：
  - `build/CMakeCache.txt`: `d0d3561801829f7e376f82f9abe2280d5279c10dcbe05e15f9f4c7a52f608d9d`
  - `build/bin/MPI_iterative_solver`: `8e309cee272eeaeb95cf410a5112e8657c2c6a5b8dba56fe825b68921539f273`
- **全量求解结果（Job `966565`，节点 `f11r1n20`，1 DCU / 1 MPI rank / 16 CPUs / 58 GiB，状态 `COMPLETED 0:0`，耗时 `81s`）**：
  - 五轮逐轮耗时：`4.040780419 s`, `3.870947209 s`, `3.865038419 s`, `3.865082410 s`, `3.869141394 s`
  - 框架五轮均值（`CHECK end to end time`）：**`3.902198 s`**
  - 原始系统 `float128` 相对残差（`Q-Check ||b - Ax||_2 / ||b||_2`）：**`5.896126e-07`**（`< 1e-6`）
  - 全程主机峰值内存（`Maximum resident set size`）：`4,866,080 KiB`（约 `4.64 GiB` `< 58 GiB`），`process.exit = 0`。

## 四、给队友的运行过程经验与避坑建议

1. **商用 CPU (`c3ln01`) 候选包位置与登录节点 Python 版本注意事项**：
   - 冻结候选包已存放在服务器 `/data/home/sunyc/solverchallenge26/next-phase-20261003/SC26_CPU_candidate_6b7f675.tar.gz`，无需从本地重复 `scp` 上传。
   - 登录节点 `c3ln01` 默认的 `/usr/bin/python3` 为 Python 3.6，直接运行 `scripts/verify_runs.py` 会因不支持 `subprocess.run(..., capture_output=True, text=True)` 报错；在登录节点执行核验脚本前，**务必先执行 `module load miniforge3/24.3.0`**。
   - T5 全量 96 进程五轮求解总耗时约 20 分钟（Job `9275745` 实测 `00:20:01`），期间 `sacct` 显示 `.batch` 与 `.extern` 子步骤处于 `RUNNING` 属于正常现象。
2. **国产 GPU (SCNet) Slurm 脚本头部注意事项**：
   - 在 SCNet `hx1hdnormal` 分区提交作业时，**不要在 `.sbatch` 脚本中显式添加 `#SBATCH --account=ac3k88uz8y` 或固定 `--nodelist`**（会导致 Slurm 报 `Requested node configuration is not available`）；保持默认账户关联与 `user_travissun` QOS，请求 `--nodes=1 --ntasks=1 --cpus-per-task=16 --gres=dcu:Hygon:1 --mem=58G` 即可秒级排入空闲节点。
3. **国产 CPU (LX2 `node76`) 认证与调度状态**：
   - 组委会已于 10 月 24 日协助重置 `travissun@152.11.26.76` 计算账号密码（凭据见队内安全交接记录）。
   - 2026-10-24 22:01–22:14 实测确认：**Linux SSH 登录与 Donau Scheduler `dlogin` 共用同一套密码**，在 `node76` 执行 `dlogin` 已成功返回 `The token is obtained successfully.`。
   - `dqueue` 确认 `challenge26` 队列状态为 `OPEN,ACTIVE`；`dnode` 确认公告节点 `J003H1S10N05`–`J003H1S10N08` 均为 `OK` 且 `608` 核空闲。

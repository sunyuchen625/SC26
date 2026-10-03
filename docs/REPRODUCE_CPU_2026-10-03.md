# CUDA OOM! CPU 独立重建与复现

日期：2026-10-03。源码版本：`6b7f675ecaa6949815a3a77f95467fc35f8d5bbf`。执行人由队友本人填写。完成状态依据该执行人的新构建、新作业和检查记录。

## 环境及准备

使用组织方商用 CPU 的单节点资源，沿用已验证 GCC 11.3.0、OpenMPI 4.1.8、CMake 3.24.2、HYPRE 2.33.0 和 oneMKL 2022.0.0。正式 MPI 要求以主办方启动合同为准；当前复现路径使用 OpenMPI。

本队已验证工作区为 `/data/home/sunyc/solverchallenge26`，HYPRE 在其 `deps/hypre`，GNU time 在 `deps/gnu-time/time`。官方输入在 `/data/home/maorz/SolverChallenge26-TenProblems`。沿用已有认证连接。每人建立单独目录，构建及求解均由 Slurm 作业执行；同一时间最多运行两项 SC26 作业。

从已授权读取的本队仓库取得该提交，或解压随附候选包。仓库来源操作：

```bash
git switch --detach 6b7f675ecaa6949815a3a77f95467fc35f8d5bbf
repo_root=$PWD
participant_id=填写本人标识
work=/data/home/sunyc/solverchallenge26/reproduce-20261003-$participant_id
mkdir -p "$work"/{src,scripts,tests,logs}
cp -R "$repo_root/资料/solverchallenge26_sample_code/." "$work/src/"
cp -R "$repo_root/scripts/." "$work/scripts/"
cp -R "$repo_root/tests/." "$work/tests/"
git rev-parse HEAD > "$work/parent-commit.txt"
cd "$work"
find src scripts tests -type f -print0 | sort -z | xargs -0 sha256sum > source-sha256.txt
```

候选包已包含 `src/scripts/tests` 布局，直接复制到独立工作目录，并保留包中的 `SOURCE_COMMIT`、来源清单和校验记录。

## 新构建与 24 个已知解样例

```bash
build_job=$(sbatch --parsable --chdir="$PWD" scripts/remediation-build.sbatch)
printf '%s\n' "$build_job" > rebuild-job-id.txt
```

构建作业生成九个 CPU 目标，运行六个 T2、十四个直接法及四个耦合场已知解样例。保存构建日志与 CMake 缓存，并确认 `COMPLETED 0:0`、24 条 `KNOWN_SOLUTION_PASS`、源码清单检查通过及二进制哈希。

## 四个正式规模复现

下列依赖形成两条作业链。请先确认账号没有其他正在运行的 SC26 作业，再提交；构建失败则后续作业等待处理。

```bash
unset SC26_RTOL SC26_PROJECT_CONSTANT
t2_job=$(sbatch --parsable --dependency=afterok:$build_job \
  --chdir="$PWD" --ntasks=16 --cpus-per-task=1 --mem=60G \
  scripts/remediation-baseline.sbatch 02 01)
t7_job=$(sbatch --parsable --dependency=afterok:$t2_job \
  --chdir="$PWD" --ntasks=16 --cpus-per-task=1 --mem=75G \
  scripts/remediation-baseline.sbatch 07 01)
t9_job=$(sbatch --parsable --dependency=afterok:$t7_job \
  --chdir="$PWD" --ntasks=1 --cpus-per-task=16 --mem=95G \
  scripts/remediation-baseline.sbatch 09 01)
t5_job=$(sbatch --parsable --dependency=afterok:$build_job \
  --chdir="$PWD" --ntasks=96 --cpus-per-task=1 \
  scripts/remediation-baseline.sbatch 05 01)
printf '%s\n' "$t2_job" "$t7_job" "$t9_job" "$t5_job" > reproduction-job-ids.txt
```

| 复现项 | 验收条件 |
| --- | --- |
| T2 低档 | 五次完整求解，原始 float128 相对残差 <1e-6；源码默认投影/容差 |
| T7 | 五次完整求解，原始 float128 相对残差 <1e-6；源码默认 ILU(0)/容差 |
| T5 | 五次完整求解，原始相对残差 ≤5e-9，五次内部 `converged=1`；默认 MGR/450/5e-9 |
| T9 RHS01 | 五次完整求解，原始相对残差 <1e-8，全程峰值内存 <100 GB |

每项还需要进程退出 0、Slurm `COMPLETED 0:0`、完整阶段计数和源码/配置/二进制来源证据。原始系统 float128 检查发生在第五次求解之后；MPI 内存记录为各进程 GNU time 峰值的保守求和。

## 队友交回的记录

| 内容 | 由执行人填写 / 保存 |
| --- | --- |
| 执行人、执行日期、使用账号 | 本人实际信息 |
| 独立工作目录、源码提交及清单 | `parent-commit.txt` 或 `SOURCE_COMMIT`、`source-sha256.txt` |
| 构建 | 作业号、终态、构建日志、24 个已知解结果 |
| 配置与二进制 | 四题 CMake 缓存、二进制哈希、实际模块与启动参数 |
| 全量求解 | 四题作业号、节点、退出码、五阶段记录、原始残差、耗时和全程内存 |
| 原始附件 | `.out/.err`、`solver.log`、`rank-*.time` 或 `process.time`、`process.exit` |
| 汇总核对 | 依据实际日志填写四项运行清单，用既有 `scripts/verify_runs.py` 检查，T5 设置工程余量门槛 |

运行清单字段示例见仓库 `logs/2026-10-01/execution/defaults-runs.json`、`t5-margin-runs.json` 和 `selected-runs.json`。清单填写新的作业、目录和哈希，并附实际构建/运行日志。原始矩阵、右端和大体积答案文件保留在计算平台。

队友本人独立取得以上完整证据后，才能将本项标记为完成。

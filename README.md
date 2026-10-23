# SolverChallenge26 · CUDA OOM!

线性解法器竞赛的 CPU 求解实现、实验脚本与基线记录。更新日期：2026-10-23。

10 月 23 日国产 GPU 平滑器对照通过 40 次求解，同一分配中的 T2 低档均时从 12.739 s 降至 6.810 s。最终 HIP 源码与 CPU 回归复验均已通过，最终 HIP 均时 6.861 s，正式平台选择仍待资格、计时合同及 S4 验收。详见[GPU 优化结果](docs/T2_HIP_OPTIMIZATION_2026-10-23.md)、[同期 CPU 对照](docs/T2_CPU_CONTROLS_2026-10-23.md)与[LX2 核查](docs/华为平台接入进度.md)。

9 月归档基线中，在比赛 CPU 平台通过参考框架原始系统残差检查的结果：

| 题目 | 方法 | 验收残差 | 五轮平均时间 |
| --- | --- | ---: | ---: |
| T2 低精度档 | HYPRE GMRES + BoomerAMG | 相对 5.894250e-7 | 20.884207 s |
| T5 | HYPRE GMRES + 压力 MGR | 相对 9.732279e-9 | 167.237252 s |
| T6 | oneMKL PARDISO 复数直接法 | 相对 1.801880e-12 | 35.216142 s |
| T7 | HYPRE GMRES + ILU(0) | 相对 1.777361e-9 | 6.190578 s |
| T8（10 个右端） | oneMKL PARDISO 复数直接法 | 最大绝对残差最高 3.657010e-16 | 每右端 75.24～76.55 s |
| T9（10 个右端） | oneMKL PARDISO 实数直接法 | 相对残差最高 1.045516e-15 | 每右端 73.41～75.03 s |
| T10（10 个右端） | oneMKL PARDISO 64 位复数直接法 | 相对残差最高 7.406004e-15 | 每右端 196.74～200.67 s |

上述表格为 9 月结果。10 月当前配置已完成 T2 低档、T4、T5、T6、T7 及 T8/T9/T10 全十个右端的五次验收。T4 使用 64 位索引，相对残差为 1.170601e-12，平均 114.69 s；T10 使用结构行配对与数值准备阶段缩放，十个右端最高相对残差 7.521765e-15。T1、T3 及 T2 高精度档未达标；所有结果均以原始矩阵、原始右端的官方 float128 验证为准。

9 月的 T8、T9、T10 均有十个右端的逐项数值记录；10 月 T8/T9 的全右端复跑全部通过。T5 在两节点、64/96 进程下的四组运行均达到原系统余量且五次均报收敛，96 进程默认配置平均 186.84 s。最新完成结果和当前验收边界见下方执行结果。已有结果尚需完成正式提交链路验收。

10 月修订将直接法分析阶段的系数指针设为 `NULL`，显式关闭数值缩放和匹配；T2 低档的投影与容差、T7 的容差已设为源码默认值。T5 默认使用压力 MGR、450 次迭代上限与 5e-9 容差，已通过正式规模余量验证。新实验记录位于 `logs/2026-10-01/execution/`。

- [已批准执行计划（English）](docs/EXECUTION_PLAN_2026-10-01.md)
- [已批准的下一阶段计划（English）](docs/reviews/STATUS_REVIEW_2026-10-02.md)
- [下一阶段结果与同节点配置比较（English）](docs/NEXT_PHASE_RESULTS_2026-10-04.md)
- [Claude Opus 5.5 max 下一阶段审计（English）](docs/reviews/CLAUDE_NEXT_PHASE_AUDIT_2026-10-04.md)
- [CPU 提交候选与主办方问题单](docs/SUBMISSION_CANDIDATE_2026-10-03.md)
- [队友独立重建与复现步骤](docs/REPRODUCE_CPU_2026-10-03.md)
- [当前执行结果（English）](docs/EXECUTION_RESULTS_2026-10-02.md)
- [Claude Opus 5.5 max 执行审计（English）](docs/reviews/CLAUDE_EXECUTION_AUDIT_2026-10-02.md)
- [技术报告](docs/SC26技术报告_2026-10-02.docx)
- [算力状态与正式合同（English）](docs/COMPUTE_STATUS_2026-10-21.md)
- [项目计划](docs/项目背景与下一步工作方案.md)
- [English project brief](docs/PROJECT_BRIEF.md)
- [Claude Sonnet 5.5 max 项目审计（English）](docs/reviews/CLAUDE_AUDIT_2026-09-30.md)
- [全部赛题与推进顺序](docs/全部赛题与选题方案.md)
- [计算资源状态与使用方案](docs/算力申请与使用方案.md)
- [华为平台接入进度](docs/华为平台接入进度.md)
- [T2 基线、依赖构建与复现](docs/baselines/T2数值基线_2026-09-22.md)
- [T1/T3/T6 扩展实验、编译与复现](docs/baselines/初步阶段扩展基线_2026-09-23.md)
- [T4/T9 数值基线与十右端验证](docs/baselines/T4_T9数值基线_2026-09-23.md)
- [T5/T7/T8/T10 数值基线与作业记录](docs/baselines/T5_T7_T8_T10数值基线_2026-09-26.md)
- [官方框架接入说明](资料/官方框架接入说明.md)
- [Grok 4.7 xhigh 独立校验](docs/reviews/校验记录_2026-09-23.md)

## 代码与实验

`资料/solverchallenge26_sample_code/` 基于[官方参考框架](https://gitee.com/godjs/solverchallenge26_sample_code)提交 `b66421483501021dd84aa10fc494f1dbf8e65958`，保留其 MIT 许可证。T2 实现位于 `problems/problem02/`，其余九题的 CPU 实现位于 `problems/cpu_baseline/`。

`docs/` 保存项目计划，`docs/baselines/` 保存数值基线，`docs/reviews/` 保存审查记录，`docs/archive/` 保留历史资源核查。平台手册位于 `资料/`，资源申请文件与提交凭证位于 `资料/资源申请/`。

`scripts/` 包含 Slurm 实验脚本，`tests/` 生成已知解系统并核对结果。`logs/` 保存原始日志、资源消耗、代码快照和结果汇总。实际全量输入使用官方计算平台的数据目录，运行环境和命令见各基线报告。

HYPRE 使用 [v2.33.0 发布源码](https://github.com/hypre-space/hypre/archive/refs/tags/v2.33.0.tar.gz)，归档 SHA-256：`0f9103c34bce7a5dcbdb79a502720fc8aab4db9fd0146e0791cde7ec878f27da`。下载并解压到报告所示依赖目录后，按 T2 报告构建。oneMKL 使用比赛 CPU 平台现有的 2022.0.0 安装。

## 超算连接

盐城超算入口为 `sunyc@122.228.252.34:6084`。SC26、数理统计和 Projects 共用 macOS 钥匙串条目：service `codex-cloud-compute`，account `sunyc`；连接时将凭据直接读取到连接进程。2026-09-24 已更新集群密码及钥匙串，并通过独立密码登录验证。

## 部署到计算平台

在比赛 CPU 平台准备好本仓库目录后，从项目根目录执行：

```bash
repo_root=$PWD
work=/data/home/sunyc/solverchallenge26
mkdir -p "$work"/{src,scripts,tests,logs,deps}
cp -R "$repo_root/资料/solverchallenge26_sample_code/." "$work/src/"
cp -R "$repo_root/scripts/." "$work/scripts/"
cp -R "$repo_root/tests/." "$work/tests/"
cd "$work/deps"
curl -fL https://github.com/hypre-space/hypre/archive/refs/tags/v2.33.0.tar.gz \
  -o hypre-2.33.0.tar.gz
echo '0f9103c34bce7a5dcbdb79a502720fc8aab4db9fd0146e0791cde7ec878f27da  hypre-2.33.0.tar.gz' | sha256sum -c -
tar -xzf hypre-2.33.0.tar.gz
```

随后按 [T2 报告的依赖构建步骤](docs/baselines/T2数值基线_2026-09-22.md#复现)安装 HYPRE，再按 [扩展报告](docs/baselines/初步阶段扩展基线_2026-09-23.md#编译与复现)构建 T1/T3/T6 并提交小样例与全量作业。脚本使用本队 `sunyc` 账号和上述工作目录；其他账号复现时需对应修改 `#SBATCH --account`、`#SBATCH --chdir` 和 `root`。

构建前执行 `module purge`，再加载报告中的 GCC/OpenMPI/CMake 模块，并单独设置 `MKLROOT`。`intel/2022.1` 模块会通过 `CPATH` 引入 Intel MPI 头文件，与本项目使用的 OpenMPI 不匹配。

10 月修订使用新的实验目录。HYPRE 安装仍位于 `/data/home/sunyc/solverchallenge26/deps/hypre`。在登录节点复制平台提供的 GNU time 到共享依赖目录，以便计算节点使用同一个计时程序：

```bash
mkdir -p /data/home/sunyc/solverchallenge26/deps/gnu-time
cp /usr/bin/time /data/home/sunyc/solverchallenge26/deps/gnu-time/time
repo_root=$PWD
work=/data/home/sunyc/solverchallenge26/execution-$(date +%Y%m%d-%H%M%S)
mkdir -p "$work"/{src,scripts,tests,logs}
cp -R "$repo_root/资料/solverchallenge26_sample_code/." "$work/src/"
cp -R "$repo_root/scripts/." "$work/scripts/"
cp -R "$repo_root/tests/." "$work/tests/"
git rev-parse HEAD > "$work/parent-commit.txt"
cd "$work"
find src scripts tests -type f -print0 | sort -z | xargs -0 sha256sum > source-sha256.txt
sbatch --chdir="$PWD" scripts/remediation-build.sbatch
```

构建作业在计算节点构建九个目标并运行二十四个小样例。确认作业 `COMPLETED 0:0` 后，从同一实验目录提交全量验证，例如：

```bash
unset SC26_RTOL SC26_PROJECT_CONSTANT
sbatch --chdir="$PWD" --ntasks=16 --cpus-per-task=1 --mem=60G \
  scripts/remediation-baseline.sbatch 02 01
sbatch --chdir="$PWD" --ntasks=16 --cpus-per-task=1 --mem=75G \
  scripts/remediation-baseline.sbatch 07 01
sbatch --chdir="$PWD" --ntasks=96 --cpus-per-task=1 \
  scripts/remediation-baseline.sbatch 05 01
sbatch --chdir="$PWD" --ntasks=1 --cpus-per-task=32 --mem=95G \
  scripts/remediation-baseline.sbatch 09 01
```

每个右端仍独立执行五次完整求解。脚本保留源码清单、配置与二进制哈希、进程退出状态、全程峰值内存和原始系统残差；`scripts/verify_runs.py` 根据运行清单复核归档证据，并调用既有 `tests/check_result.py`。同一时间最多运行两项本项目作业。

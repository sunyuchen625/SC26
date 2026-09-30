# SolverChallenge26 · CUDA OOM!

线性解法器竞赛的 CPU 求解实现、实验脚本与基线记录。更新日期：2026-09-30。

当前在比赛 CPU 平台通过参考框架原始系统残差检查的结果：

| 题目 | 方法 | 验收残差 | 五轮平均时间 |
| --- | --- | ---: | ---: |
| T2 低精度档 | HYPRE GMRES + BoomerAMG | 相对 5.894250e-7 | 20.884207 s |
| T5 | HYPRE GMRES + 压力 MGR | 相对 9.732279e-9 | 167.237252 s |
| T6 | oneMKL PARDISO 复数直接法 | 相对 1.801880e-12 | 35.216142 s |
| T7 | HYPRE GMRES + ILU(0) | 相对 1.777361e-9 | 6.190578 s |
| T8（10 个右端） | oneMKL PARDISO 复数直接法 | 最大绝对残差最高 3.657010e-16 | 每右端 75.24～76.55 s |
| T9（10 个右端） | oneMKL PARDISO 实数直接法 | 相对残差最高 1.045516e-15 | 每右端 73.41～75.03 s |
| T10（10 个右端） | oneMKL PARDISO 64 位复数直接法 | 相对残差最高 7.406004e-15 | 每右端 196.74～200.67 s |

T1、T3、T4 和 T2 高精度档尚未达标；所有结果均以原始矩阵、原始右端的官方 float128 验证为准。

T8、T9、T10 均已完成十个右端的逐项验证。T5 当前残差距离阈值约 2.7%，下一步增加收敛余量、复现已通过配置，并推进 T1/T3/T4 与 T2 高档。已有结果尚需完成正式提交链路验收。

9 月 30 日审计将直接法分析阶段的合规性、正式入口配置及十右端计时列为优先核对项。T10 在分析阶段明确启用了数值缩放与匹配，与本地保存的结构分析规则有冲突；其余直接法需核对库默认参数。详见审计报告。

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

# SolverChallenge26 · CUDA OOM!

线性解法器竞赛的 CPU 求解实现、实验脚本与基线记录。

当前通过官方原始系统残差验收的结果：

| 题目 | 方法 | 相对残差 | 五轮平均时间 |
| --- | --- | ---: | ---: |
| T2 低精度档 | HYPRE GMRES + BoomerAMG | 5.894250e-7 | 20.884207 s |
| T6 | oneMKL PARDISO 复数直接法 | 1.801880e-12 | 35.216142 s |

T1、T3 和 T2 高精度档尚未达标；所有结果均以原始矩阵、原始右端的官方 float128 验证为准。

- [项目计划](项目背景与下一步工作方案.md)
- [全部赛题与推进顺序](全部赛题与选题方案.md)
- [T2 基线、依赖构建与复现](T2数值基线_2026-09-22.md)
- [T1/T3/T6 扩展实验、编译与复现](初步阶段扩展基线_2026-09-23.md)
- [官方框架接入说明](资料/官方框架接入说明.md)

## 代码与实验

`资料/solverchallenge26_sample_code/` 基于[官方参考框架](https://gitee.com/godjs/solverchallenge26_sample_code)提交 `b66421483501021dd84aa10fc494f1dbf8e65958`，保留其 MIT 许可证。T2 实现位于 `problems/problem02/`，T1/T3/T6 的 CPU 实现位于 `problems/cpu_baseline/`。

`scripts/` 包含 Slurm 实验脚本，`tests/` 生成已知解系统并核对结果。`logs/` 保存原始日志、资源消耗、代码快照和结果汇总。实际全量输入使用官方计算平台的数据目录，运行环境和命令见各基线报告。

HYPRE 使用 [v2.33.0 发布源码](https://github.com/hypre-space/hypre/archive/refs/tags/v2.33.0.tar.gz)，归档 SHA-256：`0f9103c34bce7a5dcbdb79a502720fc8aab4db9fd0146e0791cde7ec878f27da`。下载并解压到报告所示依赖目录后，按 T2 报告构建。oneMKL 使用比赛 CPU 平台现有的 2022.0.0 安装。

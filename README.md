# SolverChallenge26 · CUDA OOM!

中国海洋大学 CUDA OOM! 队参赛项目仓库。材料提交截止时间为北京时间 2026 年 11 月 13 日 24:00，提交邮箱为 **solverchallenge@sina.com**。

## 当前交付物与进展

1. **提交材料**：[提交包 v8](deliverables/SolverChallenge26_CUDA%20OOM!_v8.zip)包括[比赛报告](deliverables/SC26技术报告_v8.docx)、逐题源码及运行说明和 12 份作业录像，覆盖 10 题、37 个不同右端项。
2. **新规 5+5 全量实测与视频**：商业 CPU 上第 1、2 题的两档精度及第 3 至第 10 题的全部右端项均已通过 5 次预热、5 次正式运行和官方 float128 精度验收。第 1 题峰值内存为 5.32 GB，第 9 题为 24.64 GB，均满足各自上限。实测记录见[正式作业汇总](logs/formal-5plus5/2026-11-12/README.md)和[收尾作业](logs/formal-5plus5/2026-11-12/closeout/README.md)。
3. **第 2 题高档**：96 个 MPI 进程在原始系统上运行 binary128 FGMRES，使用双精度 BoomerAMG 右预处理。正式作业 `9322595` 平均 55,105.61 ms，官方相对残差 `5.748190e-12`，峰值内存 38.94 GB。[原始日志](logs/formal-5plus5/2026-11-12/closeout/T02-CPU-high-9322595/solver.log) · [连续录像](deliverables/SC26_求解视频_20261112/T02-CPU-high-9322595.mp4)
4. **国产 GPU 与历史实验**：第 2 题海光 DCU（HIP 后端）方案已完成五轮优化对比（约 3.90 s）与独立复现，详见[历史实验摘要](docs/REPRODUCE_SCQ_2026-10-25.md)和[GPU 优化记录](docs/T2_GPU_PREPARATION_2026-10-23.md)。国产 CPU（LX2）完成了登录与队列连通性核查，因节点缺少原生依赖与代理证书配置，未展开编译和计算，详见[LX2 环境附录](docs/LX2_ENVIRONMENT_APPENDIX_2026-10-24.md)。

## 计时与源码入口

- 通用 CPU 入口位于 `资料/solverchallenge26_sample_code/`（直接法为 `MPI_direct_solver`，迭代法为 `MPI_iterative_solver`）。T1 的场分块 Schur + FGMRES、T2 高档的 binary128 FGMRES 以及 T3 的双精度 PARDISO + binary128 精化入口随对应题目的源码和运行说明提供。
- 计时按[现行测试规则](docs/OFFICIAL_TESTING_RULES_2026-10-27.md)执行。句柄创建与销毁及数据读入在计时区间外。先跑 5 次完整预热，从第 6 次开始连续计时至第 10 次完成，正式总时间除以 5 后换算为毫秒输出（`CHECK end to end time`）。每轮均独立执行分析、分解、预处理与求解，第 2 题低档右端投影、高档 halo 索引与 AMG 层次重建、迭代法行列缩放及第 10 题行配对与均衡化均计入每轮用时。
- 各题的运行说明提供对应的 5+5 日志验收命令。第 2 题高档使用其源码目录内的 `tests/check_result.py --formal`。

## 历史归档验证与参考文档

以下命令用于回放检验 10 月的五轮历史归档（Python 3.7+；超算登录节点需先执行 `module load miniforge3/24.3.0`）：

```bash
python3 scripts/audit_handoff.py --output logs/2026-10-27/test-flow-update/historical-archive-replay.json
python3 -m unittest discover -s tests -p test_audit_handoff.py -v
```

| 文档 | 内容说明 |
| --- | --- |
| [现行测试规则](docs/OFFICIAL_TESTING_RULES_2026-10-27.md)、[交付计划](docs/DELIVERY_PLAN_2026-10-27.md) | 官方 5+5 计时边界、提交结构与打包规范 |
| [算力申请与使用方案](docs/算力申请与使用方案.md)、[LX2 环境附录](docs/LX2_ENVIRONMENT_APPENDIX_2026-10-24.md) | 商业 CPU、海光 DCU 与 LX2 平台环境说明 |
| [历史基线候选](docs/SUBMISSION_CANDIDATE_2026-10-03.md)、[CPU 历史结果](docs/CPU_RESULTS.md) | 10 月基线配置、并行扩展对照与旧规数值证据 |
| [GPU 优化记录](docs/T2_GPU_PREPARATION_2026-10-23.md)、[CPU 历史对照](docs/T2_CPU_CONTROLS_2026-10-23.md) | 第 2 题 HIP 精确预分配优化与 CPU 对比实验 |
| [历史复现摘要](docs/REPRODUCE_SCQ_2026-10-25.md)、[规则差异记录](logs/2026-10-27/test-flow-update/official-source-record.json) | 独立复现归档与 10 月底模板更新溯源 |

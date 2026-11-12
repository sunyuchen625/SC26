# SolverChallenge26 · CUDA OOM!

中国海洋大学 CUDA OOM! 队参赛项目仓库。材料提交截止时间为北京时间 2026 年 11 月 13 日 24:00，提交邮箱为 **solverchallenge@sina.com**。

## 当前交付物与进展

1. **提交材料**：[提交包 v4](deliverables/SolverChallenge26_CUDA%20OOM!_v4.zip)包括[比赛报告](deliverables/SC26技术报告_新规实测更新_20261112.docx)、逐题源码及运行说明和作业录像（含 10 题共计 37 个正式右端项）。
2. **新规 5+5 全量实测与视频**：商业 CPU 上的第 1 题两档（`1e-4`、`1e-8`，峰值内存 4.29 GB ≤ 9 GB）、第 2 题低档（`1e-6`）、第 3 至第 7 题以及第 8 至第 10 题的全部右端项均已通过“5 次预热 + 5 次正式运行”及官方 float128 精度验收。实测记录见 [正式作业汇总](logs/formal-5plus5/2026-11-12/README.md)和[收尾作业](logs/formal-5plus5/2026-11-12/closeout/README.md)，导出视频位于 [SC26_求解视频_20261112](deliverables/SC26_求解视频_20261112/)。
3. **当前未达标项**：仅第 2 题高档（`1e-10`）尚未达到精度门槛，已在报告中据实填报。
4. **国产 GPU 与历史实验**：第 2 题海光 DCU（HIP 后端）方案已完成五轮优化对比（约 3.90 s）与独立复现，详见[历史实验摘要](docs/REPRODUCE_SCQ_2026-10-25.md)和[GPU 优化记录](docs/T2_GPU_PREPARATION_2026-10-23.md)。国产 CPU（LX2）完成了登录与队列连通性核查，受限于原生依赖与代理证书环境暂未展开编译计算，详见[LX2 环境附录](docs/LX2_ENVIRONMENT_APPENDIX_2026-10-24.md)。

## 计时与源码入口

- 正式 CPU 入口位于 `资料/solverchallenge26_sample_code/`（直接法为 `MPI_direct_solver`，迭代法为 `MPI_iterative_solver`）。T1（场分块 Schur + FGMRES）和 T3（双精度 PARDISO + `binary128` 精化）入口随提交包对应题目的源码目录及运行说明提供。
- 计时按[现行测试规则](docs/OFFICIAL_TESTING_RULES_2026-10-27.md)执行：句柄创建/销毁与数据准备不计时；先跑 5 次完整预热，在第 6 次前启动计时、第 10 次完成后停止计时，正式总时间 ÷ 5 换算为毫秒输出（`CHECK end to end time`）。每轮均独立执行分析、分解、预处理与求解，第 2 题右端投影、迭代法行列缩放及第 10 题行配对与均衡化均计入每轮用时。
- 新规 5+5 实测日志使用 `tests/check_result.py --formal` 进行自动化验收。

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

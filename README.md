# SolverChallenge26 · CUDA OOM!

中国海洋大学 CUDA OOM! 队的解法器实现、验收证据和正式交付资料。更新：2026-10-24；计算与官方资料核查以各记录标注的实测日期为准。

## 队友从这里开始

1. 读[正式交付收尾工单](docs/SC26_队友交接工单_2026-10-24.md)，明确负责人、任务和回传记录。
2. 下载[交接资料包](deliverables/SC26_队友交接资料_20261024.zip)。其中包含当前说明、CPU/GPU 候选源码及必要证据；解压后先读 `docs/SC26_队友交接工单_2026-10-24.md`。
3. 按[CPU 独立复现指南](docs/REPRODUCE_CPU_2026-10-03.md)在独立目录重建，同时用[正式入口与计时合同问题稿](docs/FORMAL_ENTRY_GPU_CONTRACT_2026-10-23.md)联系测试组。

| 当前材料 | 用途 |
| --- | --- |
| [交付候选与配置](docs/SUBMISSION_CANDIDATE_2026-10-03.md) | 两份候选的身份、已验证设置与接入条件 |
| [CPU 结果](docs/CPU_RESULTS.md) | 已通过题目、全右端记录和 CPU 配置比较 |
| [GPU 准备优化与 S4](docs/T2_GPU_PREPARATION_2026-10-23.md) | 最终 HIP 候选、逐轮时间和重复对照 |
| [同期 CPU 对照](docs/T2_CPU_CONTROLS_2026-10-23.md) | 16/32/64/96 进程实测 |
| [计算资源](docs/算力申请与使用方案.md) | 已验证连接、环境、资源与剩余阻塞 |
| [English project brief](docs/PROJECT_BRIEF.md) | 当前项目背景与交接边界 |
| [GPU 审计](docs/reviews/CLAUDE_GPU_PREPARATION_AUDIT_2026-10-23.md)、[正式合同交叉讨论](docs/reviews/CLAUDE_FORMAL_CONTRACT_DISCUSSION_2026-10-23.md) | 已审查范围与验收标准 |

## 当前状态

CPU 已有 T2 低档、T4–T7，以及 T8/T9/T10 各十个右端的通过证据。T1、T3、T2 高档仍未达标。CPU 冻结包是正式交付主线。

T2 HIP 最终候选均时为 **3.905254 / 3.907222 / 3.903342 秒**，原始系统 float128 相对残差 **5.896126e-7**。190 次新求解检查通过，实验 S4 通过；正式入口、配置、计时合同及真实队友复现仍待闭环。数值与实验发布基线为 `038c0a8`，交接任务以当前 `main` 工单为准。

10 月 24 日 18:00 是 GPU 资格与审查判断点；25 日冻结，29 日最终验收。正式门户提交及最终平台选型由队长确认。完整判断和时间节点见工单。

## 文件位置

- `资料/solverchallenge26_sample_code/`：当前源码，基于官方提交 `b66421483501021dd84aa10fc494f1dbf8e65958`，保留 MIT 许可证。
- `deliverables/`：当前 CPU 冻结候选、GPU 准备优化候选及交接 ZIP。
- `scripts/`、`tests/`：构建、复现、验证工具；编译和求解由实际分配的计算节点执行。
- `logs/`：原始运行、构建配置、来源清单、调度账本与验收记录。
- `资料/`：DCU/CPU 平台手册和报告模板。凭据与本人授权由队长单独交接。

# SolverChallenge26 · CUDA OOM!

中国海洋大学 CUDA OOM! 队的解法器实现、复现实验和交付材料。更新：2026-10-27。

## 队友从这里开始

1. 读[当前交付计划](docs/DELIVERY_PLAN_2026-10-27.md)和[队友工单](docs/SC26_队友交接工单_2026-10-24.md)，认领最终配置核对、视频、报告与打包任务。
2. 读[修订复现摘要](docs/REPRODUCE_SCQ_2026-10-25.md)。CPU 四项复现及 GPU966565 的全量/三个小例原件可回放；LX2 为有来源说明的环境附录。
3. 下载[最新交接资料包](deliverables/SC26_队友交接资料_20261027.zip)，或直接从当前 `main` 读取完整记录。两份冻结 CPU/GPU 候选身份见[候选说明](docs/SUBMISSION_CANDIDATE_2026-10-03.md)。

## 当前进度与正式提交

CPU 已有 T2 低档、T4–T7、T8–T10 全右端通过证据；T1、T3、T2 高档仍未达标。队友 CPU 新构建与24个已知解、四项全量复现通过。GPU T2 独立复现实验均时 **3.902198秒**、原始 float128 残差 **5.896126e-7**；最终采用入口、计时/官方内存接口及选型仍按交付计划对齐。LX2 的10月24日认证和队列恢复按队长转交的队友终端实测转录记录，本轮维持环境附录。

[最新官方模板](资料/SolverChallenge26报告模板_2026-10-26官网下载.docx)明确：按题准备报告、源码/脚本/Markdown说明、从提交到求解成功的视频，发往 **solverchallenge@sina.com**。五次包含预热，全部取平均；每轮构建、求解并释放组件，使用官方正确性和内存检测接口。详见[提交规则与剩余接口核对](docs/FORMAL_ENTRY_GPU_CONTRACT_2026-10-23.md)。

当前按官网原“10月30日24:00”基线推进，内部争取30日12:00前由队长确认后邮件提交。**延期七天是建议，尚未获官方确认。** 27日盘点、28日完成必要验证/视频/报告、29日最终验收。已有实验归档通过与正式交付完成分别记录。

## 本地归档核查

核查工具使用 Python 3.7 及以上；在商用 CPU 登录节点先加载 `module load miniforge3/24.3.0`，再运行以下命令。

```bash
python3 scripts/audit_handoff.py --output logs/2026-10-27/delivery-update/archive-replay.json
python3 -m unittest discover -s tests -p test_audit_handoff.py -v
```

核查仅解析既有记录及候选来源，CPU四项和GPU四项通过不替代最终视频或规则对齐。编译与数值运行使用实际分配的计算节点。

| 当前材料 | 用途 |
| --- | --- |
| [CPU 结果](docs/CPU_RESULTS.md)、[CPU 复现指南](docs/REPRODUCE_CPU_2026-10-03.md) | 已验收数值、配置和独立重建方式 |
| [GPU 准备优化](docs/T2_GPU_PREPARATION_2026-10-23.md)、[同期 CPU 对照](docs/T2_CPU_CONTROLS_2026-10-23.md) | 既有阶段计时、重复对照及 S4 实验依据 |
| [计算资源](docs/算力申请与使用方案.md)、[LX2 环境附录](docs/LX2_ENVIRONMENT_APPENDIX_2026-10-24.md) | 已验证路线、授权与注明日期的环境观察 |
| [队长交接记录](docs/CAPTAIN_HANDOFF_2026-10-26.md) | 本次修订范围、来源与交付收尾 |
| [English project brief](docs/PROJECT_BRIEF.md) | 当前项目背景与验收范围 |

源码位于 `资料/solverchallenge26_sample_code/`，基于官方提交 `b66421483501021dd84aa10fc494f1dbf8e65958`，保留 MIT 许可证。`scripts/`、`tests/` 为构建/核查工具，`logs/` 保存原始证据；凭据由队长私下交接。

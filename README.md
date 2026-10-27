# SolverChallenge26 · CUDA OOM!

中国海洋大学 CUDA OOM! 队项目。**现行规则：2026-10-27 15:38流程更新版；10/28工单已纳入官方MPI单位与样板修复通知。**

## 从这里开始

1. 读[当前交付计划](docs/DELIVERY_PLAN_2026-10-27.md)和[队友工单](docs/SC26_队友交接工单_2026-10-27.md)，认领最小计时适配、新规实测/视频、报告及打包任务。
2. 以[现行测试规则](docs/OFFICIAL_TESTING_RULES_2026-10-27.md)和[新官方模板](资料/SolverChallenge26报告模板_2026-10-27流程更新.docx)为准：五次完整预热＋五次连续正式运行；第6次前到第10次后计时，正式累计÷5，成绩填写**毫秒（ms）**。
3. 下载[流程更新版交接包](deliverables/SC26_队友交接资料_20261027_流程更新.zip)，或直接从当前`main`读取材料。它是项目交接包，正式提交包按官方三个目录另行组装。

## 当前项目状态

CPU旧规已通过T2低档、T4–T7、T8–T10全右端；scq新构建、24个已知解及四项CPU独立复现有完整原件。GPU966565的全量/三个小例旧规归档通过，原均时3.902198秒、原始系统残差5.896126e-7。详见[历史实验摘要](docs/REPRODUCE_SCQ_2026-10-25.md)。

**现有求解驱动尚未完成新5+5适配；未见新规合格成绩。** 先合入官方最新样板的适用修复并重编译，再验证定制求解器边界。官方通知中的单位错误仅涉及旧MPI CPU样板；新版 `CHECK end to end time` 已是后五次平均ms，不再次换算。仅单位错误可修正，现有旧五轮记录仍须按新流程重测；历史摘要的秒值保持原样。算法、输入、依赖与原始数值证据可按范围复用，新的计时边界、十次流程、真实运行、完整视频和正式ms结果按工单取得。T1、T3、T2高档仍未达标。

初始化、数据分配、solver/矩阵/向量句柄创建和释放、CPU→GPU传输不计时；每次仍完整进行必要分析、分解、预处理及求解，不复用前次计算结果。坐标不变的存储转换可排除，行列置换必须计时。正确性和内存使用官方示例接口。

CPU保持主线，GPU为T2条件候选；LX2保持[环境附录](docs/LX2_ENVIRONMENT_APPENDIX_2026-10-24.md)，10/24认证恢复据队长转交的队友转录，原始截图/录屏由队友保留，尚无原生构建/计算。

提交邮箱仍为 **solverchallenge@sina.com**，按题准备报告、源码/脚本/Markdown及从提交到求解成功的视频。27日晚认领/适配清单，28日小例放行与实测录像，29日最终核验，争取30日12:00前由队长确认后提交。延期七天仍是建议，未获官方确认前按原截止推进。

## 历史归档回放

以下命令验证原五轮归档，不验收新5+5正式成绩。使用Python3.7及以上；商用CPU登录节点先加载`module load miniforge3/24.3.0`。

```bash
python3 scripts/audit_handoff.py --output logs/2026-10-27/test-flow-update/historical-archive-replay.json
python3 -m unittest discover -s tests -p test_audit_handoff.py -v
```

| 材料 | 用途 |
| --- | --- |
| [基线候选](docs/SUBMISSION_CANDIDATE_2026-10-03.md)、[CPU历史结果](docs/CPU_RESULTS.md) | 原源码/包身份和数值证据，当前仍是适配起点 |
| [CPU历史复现方法](docs/REPRODUCE_CPU_2026-10-03.md) | 旧冻结包的构建与五轮复现参考 |
| [GPU历史优化](docs/T2_GPU_PREPARATION_2026-10-23.md)、[CPU历史对照](docs/T2_CPU_CONTROLS_2026-10-23.md) | 保留原秒计时和比较范围 |
| [资源说明](docs/算力申请与使用方案.md)、[English brief](docs/PROJECT_BRIEF.md) | 当前资源证据与新任务范围 |
| [规则原件及逐段差异](logs/2026-10-27/test-flow-update/official-source-record.json) | 15:38新规替代旧版的来源记录 |

`资料/solverchallenge26_sample_code/`保留既有实现和MIT许可证；其旧驱动/运行说明不是已完成的新规入口。编译、全量数值与视频任务使用实际分配的计算节点；凭据私下交接。

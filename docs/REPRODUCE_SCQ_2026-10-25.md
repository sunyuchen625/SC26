# CUDA OOM! 队友独立复现记录与三平台实测原件汇总（执行人：`scq`）

日期：2026-10-25（Asia/Shanghai）  
执行人：苏承起（`scq`）  
对照工单：[SC26 正式交付收尾工单](SC26_队友交接工单_2026-10-24.md)、[CPU 独立复现指南](REPRODUCE_CPU_2026-10-03.md)、[交付候选与配置](SUBMISSION_CANDIDATE_2026-10-03.md)

## 一、独立复现总体结论

已在商用 CPU（`qhn`）与国产 GPU（SCNet 华中一区【A区】`hx1hdnormal`）各自的本人独立目录下，从冻结候选包与 GPU 准备优化候选源码完成了全新编译、已知解验证与全量五轮求解。

- **商用 CPU 独立复现归档**：位于 [`logs/reproduce-scq-20261025/`](../logs/reproduce-scq-20261025/)，包含完整 `runs/t*/rhs-01/{solver.log,process.exit,*.time}`（共 129 个 `.time` 文件）、`build-t*/CMakeCache.txt`、`logs/*.out` 及 `source-sha256.txt`。在仓库根目录直接执行：
  ```bash
  python3 scripts/verify_runs.py logs/reproduce-scq-20261025/reproduction-runs.json

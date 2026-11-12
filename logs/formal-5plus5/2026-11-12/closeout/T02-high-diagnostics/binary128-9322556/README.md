# T2 高档单轮试验 9322556

商业 CPU c3n16，单节点 96 MPI 进程，每进程 1 线程。使用原始矩阵与右端项，binary128 FGMRES（重启长度 72，最多 3 个周期），右预处理为 double BoomerAMG 单 V-cycle。原矩阵 CSR 乘法、正交化、解更新和真实残差计算使用 binary128。

48 步后重算的原系统相对残差为 `5.748190416805e-12`。官方 `check_correctness_q_xq` 得到 `5.748190e-12`，达到高档阈值 `1e-10`。官方内存统计为 34986.0508 MiB（36.69 GB）。作业状态为 `COMPLETED 0:0`，49.274556 s 为单次试验的外层求解耗时，正式计时另有 5+5 作业。

- [原始求解日志](runs/9322556/solver.log)
- [Slurm 作业记录](sacct.log)
- [源码和作业脚本](source.tar.gz)

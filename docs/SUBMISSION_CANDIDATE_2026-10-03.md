# SolverChallenge26 当前交付候选

更新：2026-10-27。从当前 `main` 的[交接工单](SC26_队友交接工单_2026-10-24.md)开始；`038c0a8` 是数值实现与已发布实验的基线。

## 候选身份

| 候选 | 文件与 SHA256 | 用途 |
| --- | --- | --- |
| CPU 冻结候选 | [SC26_CPU_candidate_6b7f675.tar.gz](../deliverables/SC26_CPU_candidate_6b7f675.tar.gz)，`dae96e3fa5c8dc4cf8d66469b34797a84a0f3d741d0f8f4d8b4884f16206a111` | 当前正式交付主线与独立复现起点；118 项源码/脚本/测试清单对应 v19，来源 `6b7f675ecaa6949815a3a77f95467fc35f8d5bbf` |
| HIP 准备优化候选 | [SC26_T2_HIP_preparation_20261023.tar.gz](../deliverables/SC26_T2_HIP_preparation_20261023.tar.gz)，`f9482721a702b88d4e1b5e87957f59a8391215eb1938a8599bfc055e1e1c1e3a` | 当前 T2 GPU 候选；89 项清单、91 个归档成员，包内父提交 `d09163c18ce629d65d55c0e6316b9755b7e2975d` |

CPU 包与既有实验 [技术报告](SC26技术报告_2026-10-02.docx)身份匹配，报告 SHA256 为 `12c234efccfee7b23f75ba4191c6bef3500de1a4e6d569d7689800e812471fc4`。GPU [身份记录](../logs/2026-10-23/gpu-preparation/source-identity.json)绑定当前源码、GPU 验证及 CPU 回归。两份包在独立目录解压并分别验证清单。

## 已验收设置

| 题目 | 冻结 CPU 交付设置 | 数值配置及覆盖 |
| --- | --- | --- |
| T2 低档 | 16 MPI 进程，每进程 1 线程 | 默认投影、容差1e-7，原始相对残差<1e-6 |
| T4 | 1 MPI 进程，32 线程 | 64 位 PARDISO，五次完整求解 |
| T5 | 96 MPI 进程，每进程 1 线程 | 默认压力 MGR、容差5e-9、上限450；两节点/64、96进程余量验证 |
| T6 | 1 MPI 进程，32 线程 | 复数 PARDISO，五次完整求解 |
| T7 | 16 MPI 进程，每进程 1 线程 | 默认 ILU(0)，容差1e-12 |
| T8 / T9 | 1 MPI 进程，16 线程 | 各十个右端，逐右端五次完整求解 |
| T10 | 1 MPI 进程，32 线程 | 结构行配对、数值准备缩放与还原解，十个右端 |

这些是冻结交付设置。另有同分配 CPU 比较支持 T2/T7 的96进程和 T6 的96线程设置，其正式采用取决于实际允许的启动配置。每份结果保留各自节点、来源、计时和内存口径，见 [CPU 结果](CPU_RESULTS.md)与[23日对照](T2_CPU_CONTROLS_2026-10-23.md)。T1、T3、T2高档仍未达标。

当前 HIP 采用 l1-Jacobi18、粗层relax6、插值18、RAP2开启、GMRES restart50和精确IJ预分配。三次五轮均时3.905254/3.907222/3.903342秒，原始残差5.896126e-7，详见[GPU结果](T2_GPU_PREPARATION_2026-10-23.md)。

## 构建与复现

苏承起已完成四项CPU与GPU966565的独立复现，见[修订摘要](REPRODUCE_SCQ_2026-10-25.md)。正式报告、完整视频和最终配置按[当前交付计划](DELIVERY_PLAN_2026-10-27.md)对齐。

CPU 从冻结包按[独立复现指南](REPRODUCE_CPU_2026-10-03.md)重建九个目标、24个已知解案例和四项全量检查。保留本人独立目录和真实新作业记录。

以下是最终 GPU 候选已经验证过的实验构建配置。候选解压后的 `src/`、`tests/` 和清单位于各自工作目录；在**实际分配的计算节点作业内**加载已验证 GCC/CMake/DTK/OpenMPI 模块，设置既有 MPI 组件路径与 singleton-isolated 模式，再执行：

```bash
mpi_prefix=/public/software/mpi/openmpi/openmpi-4.1.8
dtk_root=/public/software/compiler/dtk-25.04.2
hypre_prefix=/public/home/travissun/sc26-hip-20261007/install-892588
sha256sum -c source-sha256.txt
cmake -S src -B build -DCMAKE_BUILD_TYPE=Release \
  -DSC26_PROBLEM=02 -DSC26_T2_HIP=ON -DSC26_BUILD_MPI=ON \
  -DSC26_BUILD_MPI_GPU=OFF -DSC26_ENABLE_FLOAT128=ON \
  -DCMAKE_C_COMPILER="$mpi_prefix/bin/mpicc" \
  -DCMAKE_CXX_COMPILER="$dtk_root/llvm/bin/clang++" \
  -DCMAKE_HIP_COMPILER="$dtk_root/llvm/bin/clang++" \
  -DCMAKE_HIP_COMPILER_ROCM_ROOT="$dtk_root/hip" \
  -DCMAKE_HIP_ARCHITECTURES=gfx936 \
  -DCMAKE_HIP_FLAGS="--gpu-max-threads-per-block=1024" \
  -DCMAKE_EXE_LINKER_FLAGS="-L$dtk_root/llvm/lib/clang/17.0.0/lib/linux" \
  -DHYPRE_DIR="$hypre_prefix/lib/cmake/HYPRE" \
  -DROCM_PATH="$dtk_root/hip" -Dhip_DIR="$dtk_root/hip/lib/cmake/hip" \
  -Drocblas_DIR="$dtk_root/lib/cmake/rocblas" \
  -Drocsparse_DIR="$dtk_root/lib/cmake/rocsparse" \
  -Drocrand_DIR="$dtk_root/lib/cmake/rocrand"
cmake --build build --parallel "$SLURM_CPUS_PER_TASK" --target MPI_iterative_solver
```

原始命令、模块、环境及库身份见[已提交批处理](../logs/2026-10-23/gpu-preparation/exact/exact-962526/submitted.sbatch)和[输出](../logs/2026-10-23/gpu-preparation/exact/sc26_t2_exact-962526.out)。正式测试采用何种构建/入口仍须按实际合同确定；此处配置对应已验收的实验路径。

## 正式采用条件

[提交规则与剩余接口核对](FORMAL_ENTRY_GPU_CONTRACT_2026-10-23.md)列明已明确的邮箱入口、正式包布局、五轮和组件生命周期，以及最终MPI/启动、HIP入口、设备完成、官方检测和十右端汇总的具体核对项。

当前真实 HIP 实现通过 MPI C 驱动运行；独立 GPU 适配器仍是模板。约3.9秒是原型口径，不能直接减探针耗时成为正式成绩。公开规则允许外部软件包；实际接入方式、所选配置和最终包仍需资格验证与审查。正式提交和最终选型由队长确认。

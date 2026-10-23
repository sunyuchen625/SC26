# SolverChallenge26 project brief

Status: 24 October 2026, Asia/Shanghai. Evidence through 23 October. CUDA OOM! is an Ocean University of China team implementing and benchmarking solvers for ten engineering sparse linear systems. Sun Yuchen coordinates the team; Zhou Junzhe (Justin) and Su Chengqi are teammates. The advisers are Zhang Linjie and Fu Kai.

## Current delivery

The [teammate work order](SC26_队友交接工单_2026-10-24.md) is the execution entry. The accompanying handoff ZIP supplies the current candidates, guides and evidence. The numerical/source publication baseline is `038c0a8`; read the current repository main for the handoff documents.

The frozen CPU candidate is `SC26_CPU_candidate_6b7f675.tar.gz`, SHA256 `dae96e3fa5c8dc4cf8d66469b34797a84a0f3d741d0f8f4d8b4884f16206a111`. Its 118 manifested source/script/test entries retain the accepted v19 implementation. T2-low, T4–T7 and all ten RHS of T8/T9/T10 have passing full-scale evidence. T1, T3 and T2-high remain unresolved. [CPU results](CPU_RESULTS.md) distinguish measured configurations and residual metrics.

The current HIP candidate is `SC26_T2_HIP_preparation_20261023.tar.gz`, SHA256 `f9482721a702b88d4e1b5e87957f59a8391215eb1938a8599bfc055e1e1c1e3a`. It contains 89 manifested entries and 91 archive members. Exact diagonal/offdiagonal IJ preallocation, interpolation18 and l1-Jacobi18 give T2-low means 3.905254/3.907222/3.903342 s with original float128 relative residual 5.896126e-7. The phase completed 190 new solves; 40 historical solves are separately reconciled. [GPU results](T2_GPU_PREPARATION_2026-10-23.md) preserve all tested variants and individual round records.

Experimental S4 passes against measured 96-rank CPU, using the faster historical 7.036402 s comparator conservatively. This is prototype-inclusive timing, not an official score. The actual permitted launch, HIP entry and excluded-transfer/conversion definition remain open.

## Remaining work

[Formal entry and timing](FORMAL_ENTRY_GPU_CONTRACT_2026-10-23.md) separates mandatory program-route/build-run/package/parser/runtime terms from GPU-specific platform/entry qualification and internal teammate reproduction. Public rules permit external solver packages; the integration issue is the accepted interface. The public README states MPICH while experiments use OpenMPI. The separate T2 GPU adapter is still a template; the real HIP experiment uses the MPI C entry.

Run the [CPU reproduction guide](REPRODUCE_CPU_2026-10-03.md) in a teammate's independent directory: nine CPU targets, 24 known cases and four full-problem checks. If GPU is proposed for T2, add reproduction of the selected GPU artifact under the T2 item while retaining the CPU evidence. Reuse still-applicable checks and revalidate only affected source/runtime/resource/timing coverage.

24 October 18:00 remains the GPU qualification/review checkpoint. Reproduction is targeted for that checkpoint and required at 29 October final acceptance. Freeze 25 October. The internal finalized-submission target is 30 October 12:00, under the captain's instruction. The 23 October official-page check lists 30 October 24:00 without an explicit portal timezone. LX2 remains an environment appendix.

## Implementation and environment

Current code is under `资料/solverchallenge26_sample_code/`, based on upstream `b66421483501021dd84aa10fc494f1dbf8e65958`, with its MIT license retained. T2 uses HYPRE GMRES/BoomerAMG and internal constant-component projection; all final checks use original A and b. Shared CPU implementations are in `problems/cpu_baseline/`. Direct analysis is structural; numerical preparation and solution recovery retain their validated scope.

The validated CPU stack is GCC 11.3.0/OpenMPI 4.1.8/CMake 3.24.2/HYPRE 2.33.0/oneMKL 2022.0.0 on the commercial qhn platform. The GPU stack uses the allocated SCNet BW1000/gfx936 device and DTK/HIP, with the identified HYPRE install. [Resource status](算力申请与使用方案.md) records dated observations and authorization gaps. Build/solver jobs execute only on allocated nodes.

Original-system float128 checking follows the fifth complete solve; the six-decimal output file is not its accuracy substitute. T8 uses maximum absolute residual; other selected problems use relative two-norm. Full-process rank RSS peaks are conservatively summed. Formal scoring aggregation and final qualification still require the actual testing contract.

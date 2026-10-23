# T2-low CPU controls — 23 October 2026

Later same-day exact-source controls and individual round times are in [GPU preparation and S4 results](T2_GPU_PREPARATION_2026-10-23.md). The earlier 7.126864 s control below remains part of the conservative comparison.

Job **9269822** completed `0:0` on `c3n17`, with one node, 96 allocated CPUs, 60 GiB requested memory and **448 allocated seconds**. Operator: Codex using the existing team account. The four launch settings ran sequentially in this same allocation, with one thread per MPI process and core binding.

The unchanged accepted v19 T2 binary, CMake cache and original input hashes match comparison job `9213608`. Source manifest checks pass. Each setting completes five full solves, with default projection and tolerance `1e-7`, zero launcher/rank exits and original-system in-memory float128 residual below `1e-6`.

| MPI ranks | Driver five-round mean (s) | Original float128 relative residual | Conservative sum of rank RSS peaks (GiB) |
| --- | ---: | ---: | ---: |
| 16 | 24.410885 | 5.885605e-07 | 14.438 |
| 32 | 20.288075 | 5.894250e-07 | 15.610 |
| 64 | 12.608171 | 5.896190e-07 | 17.611 |
| 96 | 7.126864 | 5.875263e-07 | 19.179 |

These are the driver's outer five-round means. The recorded callback phase sums have their own scope. Memory is a conservative sum of each rank's complete-process GNU time peak, rather than a simultaneous node peak; all four sums fit the 60 GiB grant.

The 96-rank setting remains the fastest measured setting in this allocation, at **7.126864 s**. Its use as the final comparison setting depends on the actual permitted launcher/rank/thread contract. The original [CPU/GPU comparison](T2_HIP_FULL_RESULTS_2026-10-21.md) remains a dated result; fresh GPU measurements should use these contemporaneous CPU controls with their stated timing scope.

The [verification and identities](../logs/2026-10-23/resource-optimization/cpu-control-verification.json), [scheduler accounting](../logs/2026-10-23/resource-optimization/cpu-control-9269822-accounting.log), [batch output](../logs/2026-10-23/resource-optimization/logs/sc26_launch_compare-9269822.out), [runtime warnings and bindings](../logs/2026-10-23/resource-optimization/logs/sc26_launch_compare-9269822.err) and [individual run records](../logs/2026-10-23/resource-optimization/runs/t02-9269822/) retain the evidence. The retrieved archive matches the remote SHA256 `d24f7dda882460ed6f0c19851584e20f17120393285248b7a9086c608f7e3cd3`.

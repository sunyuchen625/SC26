#!/bin/bash
#SBATCH --job-name=sc26_hip_probe
#SBATCH --partition=hx1hdnormal
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --gres=dcu:Hygon:1
#SBATCH --time=00:05:00
#SBATCH --output=sc26_hip_probe-%j.out
#SBATCH --error=sc26_hip_probe-%j.err
set -e
export LC_ALL=C
module load compiler/gcc/12.2.0 compiler/cmake/3.24.1 compiler/dtk/25.04.2
set -uo pipefail
work="$HOME/sc26-hip-probe-$SLURM_JOB_ID"
mkdir -p "$work"
cd "$work"
cp "$0" submitted.sbatch
sha256sum submitted.sbatch
printf 'JOB_ID=%s NODELIST=%s CPUS_PER_TASK=%s\n' "$SLURM_JOB_ID" "$SLURM_JOB_NODELIST" "$SLURM_CPUS_PER_TASK"
scontrol show job "$SLURM_JOB_ID"
module list
hipcc --version
cmake --version
cat > hip-probe.cpp <<'HIP'
#include <hip/hip_runtime.h>
#include <cstdio>
#define HIP_CALL(call) do { hipError_t status = (call); if (status != hipSuccess) { std::fprintf(stderr, "%s: %s\n", #call, hipGetErrorString(status)); return 1; } } while (0)
__global__ void probe(double *values)
{
    values[threadIdx.x] = 0.5 * threadIdx.x + 1.25;
}
int main()
{
    int count, runtime_version;
    HIP_CALL(hipGetDeviceCount(&count));
    HIP_CALL(hipSetDevice(0));
    HIP_CALL(hipRuntimeGetVersion(&runtime_version));
    hipDeviceProp_t properties;
    HIP_CALL(hipGetDeviceProperties(&properties, 0));
    std::printf("HIP_DEVICE count=%d name=%s architecture=%s global_memory_bytes=%zu\n", count, properties.name, properties.gcnArchName, properties.totalGlobalMem);
    std::printf("HIP_RUNTIME_VERSION=%d\n", runtime_version);
    double host[8], *device;
    HIP_CALL(hipMalloc(reinterpret_cast<void **>(&device), sizeof(host)));
    hipLaunchKernelGGL(probe, dim3(1), dim3(8), 0, 0, device);
    HIP_CALL(hipGetLastError());
    HIP_CALL(hipDeviceSynchronize());
    HIP_CALL(hipMemcpy(host, device, sizeof(host), hipMemcpyDeviceToHost));
    HIP_CALL(hipFree(device));
    for (int i = 0; i < 8; ++i) {
        if (host[i] != 0.5 * i + 1.25) {
            std::fprintf(stderr, "HIP kernel result mismatch at %d: %.17g\n", i, host[i]);
            return 1;
        }
    }
    std::puts("HIP_KERNEL_PASS elements=8 precision=double");
}
HIP
hipcc -O2 --offload-arch=gfx936 hip-probe.cpp -o hip-probe
sha256sum hip-probe.cpp hip-probe
./hip-probe
module load mpi/openmpi/4.1.8/gcc-12.2.0/shca
module list
mpicc --showme
cat > mpi-probe.c <<'MPI'
#include <mpi.h>
#include <stdio.h>
int main(int argc, char **argv) {
    int rank, size, length; char version[MPI_MAX_LIBRARY_VERSION_STRING];
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Get_library_version(version, &length);
    printf("MPI_PROBE_PASS rank=%d size=%d library=%.*s\n", rank, size, length, version);
    return MPI_Finalize();
}
MPI
mpicc -O2 mpi-probe.c -o mpi-probe
sha256sum mpi-probe.c mpi-probe
mpirun --bind-to core --map-by core -np 1 ./mpi-probe
printf 'SC26_HIP_MPI_PROBE_COMPLETE\n'

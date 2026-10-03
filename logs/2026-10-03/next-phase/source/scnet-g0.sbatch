#!/bin/bash
#SBATCH --job-name=sc26_gpu_g0
#SBATCH --partition=hx1hdnormal
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --gres=dcu:Hygon:1
#SBATCH --time=00:05:00
#SBATCH --output=sc26_gpu_g0-%j.out
#SBATCH --error=sc26_gpu_g0-%j.err
set -e
export LC_ALL=C
printf 'JOB_ID=%s NODELIST=%s CPUS_PER_TASK=%s\n' "$SLURM_JOB_ID" "$SLURM_JOB_NODELIST" "$SLURM_CPUS_PER_TASK"
hostname
whoami
pwd
scontrol show job "$SLURM_JOB_ID"
module -t avail 2>&1 | grep -Ei 'dtk|mpi|cmake'
module load compiler/dtk/25.04.2
module list
hipcc --version
hy-smi
printf 'HIP_VISIBLE_DEVICES=%s ROCR_VISIBLE_DEVICES=%s CUDA_VISIBLE_DEVICES=%s\n' \
    "$HIP_VISIBLE_DEVICES" "$ROCR_VISIBLE_DEVICES" "$CUDA_VISIBLE_DEVICES"
rocminfo | grep -E 'Name:|Size:'
if command -v mpirun; then
    mpirun --version
else
    printf 'MPI executable unavailable in the current module environment\n'
fi

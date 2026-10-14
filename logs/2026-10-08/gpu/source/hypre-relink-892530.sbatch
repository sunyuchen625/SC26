#!/bin/bash
#SBATCH --job-name=sc26_hypre_hip_relink
#SBATCH --partition=hx1hdnormal
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --gres=dcu:Hygon:1
#SBATCH --time=00:05:00
#SBATCH --output=sc26_hypre_hip_relink-%j.out
#SBATCH --error=sc26_hypre_hip_relink-%j.err
set -e
if [[ -z ${SLURM_JOB_ID:-} || -z ${SLURMD_NODENAME:-} || $(hostname -s) != "$SLURMD_NODENAME" ]]; then
    printf 'Submit with sbatch; execution requires the allocated compute node.\n' >&2
    exit 2
fi
export LC_ALL=C
module load compiler/gcc/12.2.0 compiler/cmake/3.24.1 compiler/dtk/25.04.2
module load mpi/openmpi/4.1.8/gcc-12.2.0/shca
set -uo pipefail
mpi_prefix=/public/software/mpi/openmpi/openmpi-4.1.8
export OMPI_MCA_mca_base_component_path="$mpi_prefix/lib/openmpi:/public/software/mpi/pmix/4.2.9/lib/pmix"
export OMP_NUM_THREADS=1
dtk_root=/public/software/compiler/dtk-25.04.2
work="$HOME/sc26-hip-20261007"
build_dir="$work/build-891465"
cd "$work"
printf 'JOB_ID=%s NODE=%s ORIGIN_BUILD_JOB=891465\n' "$SLURM_JOB_ID" "$(hostname -s)"
scontrol show job "$SLURM_JOB_ID"
module list
printf 'HYPRE_ARCHIVE_BEFORE\n'
sha256sum "$build_dir/lib/libHYPRE.a"
cmake -S "$work/source-891465/src" -B "$build_dir" \
    -DCMAKE_EXE_LINKER_FLAGS="-L$dtk_root/llvm/lib/clang/17.0.0/lib/linux"
cmake --build "$build_dir" --parallel "$SLURM_CPUS_PER_TASK" --target ij
printf 'HYPRE_ARCHIVE_AFTER\n'
sha256sum "$build_dir/lib/libHYPRE.a" "$build_dir/test/ij" "$build_dir/CMakeCache.txt"
cmake --install "$build_dir"
printf 'HYPRE_HIP_IJ_LINKED\n'
"$build_dir/test/ij" -n 8 8 8 -P 1 1 1 -solver 1 \
    -memory_device -exec_device -rlx 18 -rlx_coarse 18 -tol 1e-8
printf 'HYPRE_HIP_RELINK_JOB_COMPLETE\n'

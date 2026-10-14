#!/bin/bash
#SBATCH --job-name=sc26_hypre_inputs
#SBATCH --partition=hx1hdnormal
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --gres=dcu:Hygon:1
#SBATCH --time=00:05:00
#SBATCH --output=sc26_hypre_inputs-%j.out
#SBATCH --error=sc26_hypre_inputs-%j.err
set -e
if [[ -z ${SLURM_JOB_ID:-} || -z ${SLURMD_NODENAME:-} || $(hostname -s) != "$SLURMD_NODENAME" ]]; then
    printf 'Submit with sbatch; execution requires the allocated compute node.\n' >&2
    exit 2
fi
export LC_ALL=C
module load compiler/gcc/12.2.0 compiler/cmake/3.24.1 compiler/dtk/25.04.2
module load mpi/openmpi/4.1.8/gcc-12.2.0/shca
set -uo pipefail
dtk_root=/public/software/compiler/dtk-25.04.2
work="$HOME/sc26-hip-20261007"
mkdir -p "$work"
cd "$work"
printf 'JOB_ID=%s NODE=%s WORK=%s\n' "$SLURM_JOB_ID" "$(hostname -s)" "$work"
scontrol show job "$SLURM_JOB_ID"
module list
command -v hipcc cmake mpicc
for setting in ROCM_PATH HIP_PATH HIP_CLANG_PATH; do
    printf '%s=%s\n' "$setting" "${!setting-}"
done
find -H "$dtk_root" -maxdepth 6 \( -name hip-config.cmake -o -name hip-lang-config.cmake -o -name rocblas-config.cmake -o -name rocsparse-config.cmake -o -name rocrand-config.cmake \) -print
ls -ld /public/share/ac3k88uz8y/SolverChallenge26-TenProblems/solverchallenge26_02
curl --fail --location --connect-timeout 15 --max-time 120 \
    https://github.com/hypre-space/hypre/archive/refs/tags/v2.33.0.tar.gz \
    -o hypre-2.33.0.tar.gz
printf '%s\n' '0f9103c34bce7a5dcbdb79a502720fc8aab4db9fd0146e0791cde7ec878f27da  hypre-2.33.0.tar.gz' | sha256sum -c -
tar -xzf hypre-2.33.0.tar.gz
printf 'HYPRE_BUILD_INPUTS_READY\n'

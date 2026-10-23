#!/bin/bash
#SBATCH --job-name=sc26_t2_l1_hipoff
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --time=00:15:00
#SBATCH --output=sc26_t2_l1_hipoff-%j.out
#SBATCH --error=sc26_t2_l1_hipoff-%j.err
set -e
if [[ -z ${SLURM_JOB_ID:-} || -z ${SLURMD_NODENAME:-} || $(hostname -s) != "$SLURMD_NODENAME" ]]; then
    printf 'Submit with sbatch; execution requires the allocated compute node.\n' >&2
    exit 2
fi
export LC_ALL=C
module purge
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 cmake/3.24.2 miniforge3/24.3.0
set -uo pipefail
work=/data/home/sunyc/solverchallenge26/resource-optimization-20261023
root="$work/t2-hipoff-$SLURM_JOB_ID"
mkdir -p "$root"
cd "$root"
cp "$0" submitted.sbatch
printf 'JOB_ID=%s NODE=%s ROOT=%s\n' "$SLURM_JOB_ID" "$(hostname -s)" "$root"
scontrol show job "$SLURM_JOB_ID"
module list
printf '%s  %s\n' 'b777cb575305cb12a15488a761532784670d1b68d8ed139c55e55f89db4a5625' \
    "$work/SC26_T2_HIP_source_20261023.tar.gz" | sha256sum -c -
tar -xzf "$work/SC26_T2_HIP_source_20261023.tar.gz"
sha256sum source-sha256.txt submitted.sbatch /data/home/sunyc/solverchallenge26/plan-execution-20261009/t2-small.sbatch \
    /data/home/sunyc/solverchallenge26/deps/hypre/lib64/libHYPRE.a
sha256sum -c source-sha256.txt
cat parent-commit.txt
export OMP_NUM_THREADS=1
cmake -S src -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc \
    -DSC26_PROBLEM=02 -DSC26_T2_HIP=OFF -DSC26_BUILD_MPI=ON \
    -DSC26_BUILD_MPI_GPU=OFF -DSC26_ENABLE_FLOAT128=ON \
    -DHYPRE_DIR=/data/home/sunyc/solverchallenge26/deps/hypre/lib64/cmake/HYPRE \
    >configure.log 2>&1 || { configure_exit=$?; tail -n 30 configure.log >&2; exit "$configure_exit"; }
cmake --build build -j4 --target MPI_iterative_solver \
    >build.log 2>&1 || { build_exit=$?; tail -n 30 build.log >&2; exit "$build_exit"; }
sha256sum build/CMakeCache.txt build/bin/MPI_iterative_solver
grep -E '^(SC26_|HYPRE_DIR|CMAKE_C_COMPILER)' build/CMakeCache.txt
grep -E 'HYPRE_USING_(HIP|GPU|UNIFIED_MEMORY)' /data/home/sunyc/solverchallenge26/deps/hypre/include/HYPRE_config.h
export SC26_ROOT="$root" SC26_BUILD_DIR=build
printf 'REGRESSION_ROOT=%s REGRESSION_BINARY=%s\n' "$SC26_ROOT" "$SC26_ROOT/$SC26_BUILD_DIR/bin/MPI_iterative_solver"
bash /data/home/sunyc/solverchallenge26/plan-execution-20261009/t2-small.sbatch >small-cases.out 2>small-cases.err \
    || { regression_exit=$?; tail -n 30 small-cases.out >&2; cat small-cases.err >&2; exit "$regression_exit"; }
cat small-cases.err
grep -E 'KNOWN_SOLUTION_PASS|OFFICIAL_RESIDUAL_PASS' small-cases.out
test "$(grep -c '^OFFICIAL_RESIDUAL_PASS ' small-cases.out)" -eq 6
sha256sum build/bin/MPI_iterative_solver
printf 'SC26_T2_HIPOFF_REGRESSION_COMPLETE\n'

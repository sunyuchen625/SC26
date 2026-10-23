#!/bin/bash
#SBATCH --job-name=sc26_t2_timed_build
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --time=00:10:00
#SBATCH --output=sc26_t2_timed_build-%j.out
#SBATCH --error=sc26_t2_timed_build-%j.err
set -e
if [[ -z ${SLURM_JOB_ID:-} || -z ${SLURMD_NODENAME:-} || $(hostname -s) != "$SLURMD_NODENAME" ]]; then
    printf 'Submit with sbatch; execution requires the allocated compute node.\n' >&2
    exit 2
fi
export LC_ALL=C
module purge
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 cmake/3.24.2 miniforge3/24.3.0
set -uo pipefail
export OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 MKL_DYNAMIC=FALSE MKL_THREADING_LAYER=GNU
unset SC26_RTOL SC26_PROJECT_CONSTANT
work=/data/home/sunyc/solverchallenge26/gpu-preparation-20261023
root="$work/cpu-build-$SLURM_JOB_ID"
data=/data/home/maorz/SolverChallenge26-TenProblems/solverchallenge26_02
time_bin=/data/home/sunyc/solverchallenge26/deps/gnu-time/time
mkdir -p "$root"
cd "$root"
cp "$0" submitted.sbatch
scontrol show job "$SLURM_JOB_ID"
module list
lscpu
printf '%s  %s\n' 'f9482721a702b88d4e1b5e87957f59a8391215eb1938a8599bfc055e1e1c1e3a' "$work/exact-source.tar.gz" | sha256sum -c -
tar -xzf "$work/exact-source.tar.gz"
sha256sum -c source-sha256.txt
sha256sum source-sha256.txt src/problems/problem02/solver.c src/apps/MPI_iterative_solver.c "$time_bin" /data/home/sunyc/solverchallenge26/deps/hypre/lib64/libHYPRE.a
cat parent-commit.txt
cmake -S src -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc \
 -DSC26_PROBLEM=02 -DSC26_T2_HIP=OFF -DSC26_BUILD_MPI=ON \
 -DSC26_BUILD_MPI_GPU=OFF -DSC26_ENABLE_FLOAT128=ON \
 -DHYPRE_DIR=/data/home/sunyc/solverchallenge26/deps/hypre/lib64/cmake/HYPRE >configure.log 2>&1 \
 || { status=$?; tail -n 30 configure.log >&2; exit "$status"; }
cmake --build build -j4 --target MPI_iterative_solver >build.log 2>&1 \
 || { status=$?; tail -n 30 build.log >&2; exit "$status"; }
sha256sum build/CMakeCache.txt build/bin/MPI_iterative_solver
grep -E 'HYPRE_USING_(HIP|GPU|UNIFIED_MEMORY)' /data/home/sunyc/solverchallenge26/deps/hypre/include/HYPRE_config.h
export SC26_ROOT="$root" SC26_BUILD_DIR=build
bash /data/home/sunyc/solverchallenge26/plan-execution-20261009/t2-small.sbatch >small-cases.out 2>small-cases.err
cat small-cases.err
grep -E 'KNOWN_SOLUTION_PASS|OFFICIAL_RESIDUAL_PASS' small-cases.out
test "$(grep -c '^OFFICIAL_RESIDUAL_PASS ' small-cases.out)" -eq 6
sha256sum source-sha256.txt src/problems/problem02/solver.c src/apps/MPI_iterative_solver.c build/CMakeCache.txt build/bin/MPI_iterative_solver > build-receipt.sha256
printf 'SC26_TIMED_CPU_BUILD_COMPLETE ROOT=%s\n' "$root"

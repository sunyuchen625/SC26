#!/bin/bash
#SBATCH --job-name=sc26_direct_probe
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=150G
#SBATCH --time=00:20:00
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err
set -e
export LC_ALL=C
module purge
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 cmake/3.24.2 miniforge3/24.3.0
set -uo pipefail
root=$PWD
problem=$1
case "$problem" in 03|04) ;; *) exit 2 ;; esac
export MKLROOT=/data/public/software/intel/oneapi/mkl/2022.0.0
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK MKL_NUM_THREADS=$SLURM_CPUS_PER_TASK
export MKL_DYNAMIC=FALSE MKL_THREADING_LAYER=GNU
time_bin=/data/home/sunyc/solverchallenge26/deps/gnu-time/time
module list
lscpu
sha256sum source-sha256.txt
sha256sum -c source-sha256.txt
cmake -S src -B "build-probe-t$problem" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc \
    -DSC26_PROBLEM="$problem" -DSC26_BUILD_MPI_GPU=OFF \
    -DCMAKE_PREFIX_PATH=/data/home/sunyc/solverchallenge26/deps/hypre
cmake --build "build-probe-t$problem" -j4 --target sc26_io sc26_mpi_diagnostics
mpicc -O3 -std=gnu99 -DDIRECT_SOLVER -DMPI_USE -DSC26_PROBLEM_NUMBER="$((10#$problem))" \
    -Isrc/include -Isrc/problems/cpu_baseline -I"$MKLROOT/include" scripts/direct-probe.c \
    "build-probe-t$problem/libsc26_io.a" "build-probe-t$problem/libsc26_mpi_diagnostics.a" \
    -L"$MKLROOT/lib/intel64" -Wl,-rpath,"$MKLROOT/lib/intel64" \
    -lmkl_rt -lquadmath -lpthread -ldl -lm -o "build-probe-t$problem/direct-probe"
data=/data/home/maorz/SolverChallenge26-TenProblems/solverchallenge26_$problem
sha256sum "build-probe-t$problem/direct-probe" "build-probe-t$problem/CMakeCache.txt" \
    "$data/solverchallenge26_${problem}_A.dat" "$data/solverchallenge26_${problem}_b.dat" "$time_bin"
run="$root/runs/t$problem-probe-$SLURM_JOB_ID"
mkdir -p "$run"; cd "$run"
"$time_bin" -v -o process.time "$root/build-probe-t$problem/direct-probe" \
    "$data/solverchallenge26_${problem}_A.dat" "$data/solverchallenge26_${problem}_b.dat" | tee solver.log

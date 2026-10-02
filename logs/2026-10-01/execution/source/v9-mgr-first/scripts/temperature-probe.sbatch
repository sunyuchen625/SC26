#!/bin/bash
#SBATCH --job-name=sc26_u2_temperature
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --time=00:15:00
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err
set -e
export LC_ALL=C
module purge
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 cmake/3.24.2 miniforge3/24.3.0
set -uo pipefail
export MKLROOT=/data/public/software/intel/oneapi/mkl/2022.0.0
export OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 MKL_DYNAMIC=FALSE MKL_THREADING_LAYER=GNU
cmake -S src -B build-t01 -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc \
    -DSC26_PROBLEM=01 -DSC26_FIELD_SPLIT=ON -DSC26_BUILD_MPI_GPU=OFF \
    -DCMAKE_PREFIX_PATH=/data/home/sunyc/solverchallenge26/deps/hypre
cmake --build build-t01 -j4 --target MPI_iterative_solver
unset SC26_PROJECT_CONSTANT
export SC26_RTOL=1e-8
bash scripts/remediation-baseline.sbatch 01 01

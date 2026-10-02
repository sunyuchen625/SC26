#!/bin/bash
#SBATCH --job-name=sc26_mpi_smoke
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:02:00
#SBATCH --chdir=/data/home/sunyc/solverchallenge26
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err

set -e
export LC_ALL=C
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 cmake/3.24.2
set -u
export OMP_NUM_THREADS=1
module list
hostname
for file in /data/home/maorz/SolverChallenge26-TenProblems/solverchallenge26_02/solverchallenge26_02_{A,b}.dat; do
    head -c 16 "$file" >/dev/null
done
mpirun -np "$SLURM_NTASKS" ./build/mpi_smoke

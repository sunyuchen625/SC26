#!/bin/bash
#SBATCH --job-name=sc26_direct
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=96
#SBATCH --mem=450G
#SBATCH --time=00:30:00
#SBATCH --chdir=/data/home/sunyc/solverchallenge26
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err
set -e
export LC_ALL=C
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 miniforge3/24.3.0
set -uo pipefail
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK MKL_NUM_THREADS=$SLURM_CPUS_PER_TASK
export MKL_DYNAMIC=FALSE MKL_THREADING_LAYER=GNU
root=/data/home/sunyc/solverchallenge26
problem=$1
case "$problem" in
    03) sys_type=0 ;;
    06) sys_type=1 ;;
    *) exit 2 ;;
esac
data=/data/home/maorz/SolverChallenge26-TenProblems/solverchallenge26_$problem
module list
lscpu
sha256sum "$root/build-t$problem/bin/MPI_direct_solver" "$data/solverchallenge26_${problem}_A.dat" "$data/solverchallenge26_${problem}_b.dat"
run_dir="$root/runs/t$problem-direct-$SLURM_JOB_ID"
mkdir -p "$run_dir"
cd "$run_dir"
/usr/bin/time -v -o process.time "$root/build-t$problem/bin/MPI_direct_solver" \
    "$data/solverchallenge26_${problem}_A.dat" "$data/solverchallenge26_${problem}_b.dat" \
    0 "$sys_type" | tee solver.log
python3 "$root/tests/check_result.py" solver.log 1e-8

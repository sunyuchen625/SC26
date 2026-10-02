#!/bin/bash
#SBATCH --job-name=sc26_stage2_complex
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=96
#SBATCH --mem=450G
#SBATCH --time=00:45:00
#SBATCH --chdir=/data/home/sunyc/solverchallenge26
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err
set -e
export LC_ALL=C
module purge
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 miniforge3/24.3.0
set -uo pipefail
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK MKL_NUM_THREADS=$SLURM_CPUS_PER_TASK
export MKL_DYNAMIC=FALSE MKL_THREADING_LAYER=GNU
root=/data/home/sunyc/solverchallenge26
problem=$1; shift
case "$problem" in
    08) metric=max ;;
    10) metric=relative ;;
    *) exit 2 ;;
esac
if [ "$#" = 0 ]; then set -- 01; fi
data=/data/home/maorz/SolverChallenge26-TenProblems/solverchallenge26_$problem
module list
lscpu
sha256sum "$root/build-t$problem/bin/MPI_direct_solver" "$data/solverchallenge26_${problem}_A.dat"
failed=0
for rhs in "$@"; do
    sha256sum "$data/solverchallenge26_${problem}_b_${rhs}.dat"
    run_dir="$root/runs/t$problem-direct-$SLURM_JOB_ID/rhs-$rhs"
    mkdir -p "$run_dir"
    cd "$run_dir"
    /usr/bin/time -v -o process.time "$root/build-t$problem/bin/MPI_direct_solver" \
        "$data/solverchallenge26_${problem}_A.dat" "$data/solverchallenge26_${problem}_b_${rhs}.dat" \
        0 1 | tee solver.log
    python3 "$root/tests/check_result.py" solver.log 1e-8 --metric "$metric" || failed=1
done
exit "$failed"

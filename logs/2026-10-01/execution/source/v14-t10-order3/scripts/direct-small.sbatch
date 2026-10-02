#!/bin/bash
#SBATCH --job-name=sc26_direct_small
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=00:05:00
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
real_problem=${1:-03}
for sample in poisson nonsymmetric scaled complex; do
    problem=$real_problem; sys_type=0
    if [ "$sample" = complex ]; then problem=06; sys_type=1; fi
    run_dir="$root/runs/direct-small-$SLURM_JOB_ID/$sample"
    mkdir -p "$run_dir"
    cd "$run_dir"
    "$root/build-t$problem/bin/MPI_direct_solver" \
        "$root/tests/small_systems/${sample}_A.dat" "$root/tests/small_systems/${sample}_b.dat" \
        0 "$sys_type" | tee solver.log
    python3 "$root/tests/check_result.py" solver.log 1e-10 answer_x.rhs \
        "$root/tests/small_systems/${sample}_x.txt"
done

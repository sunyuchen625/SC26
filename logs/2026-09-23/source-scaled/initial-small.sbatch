#!/bin/bash
#SBATCH --job-name=sc26_initial_small
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=00:05:00
#SBATCH --chdir=/data/home/sunyc/solverchallenge26
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err
set -e
export LC_ALL=C
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 cmake/3.24.2 miniforge3/24.3.0
set -uo pipefail
export OMP_NUM_THREADS=1 SC26_RTOL=1e-11
root=/data/home/sunyc/solverchallenge26
python3 tests/make_small_systems.py
python3 tests/make_complex_system.py
for problem in 01 03 06; do
    samples='poisson nonsymmetric'; sys_type=0
    if [ "$problem" = 06 ]; then samples=complex; sys_type=1; fi
    for sample in $samples; do
        for ranks in 1 4; do
            run_dir="$root/runs/initial-small-$SLURM_JOB_ID/t$problem-$sample-$ranks"
            mkdir -p "$run_dir"
            cd "$run_dir"
            mpirun -np "$ranks" "$root/build-t$problem/bin/MPI_iterative_solver" \
                "$root/tests/small_systems/${sample}_A.dat" \
                "$root/tests/small_systems/${sample}_b.dat" 0 "$sys_type" | tee solver.log
            python3 "$root/tests/check_result.py" solver.log 1e-10 answer_x.rhs \
                "$root/tests/small_systems/${sample}_x.txt"
        done
    done
done

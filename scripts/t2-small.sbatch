#!/bin/bash
#SBATCH --job-name=sc26_t2_small
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
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
for sample in poisson nonsymmetric neumann; do
    export SC26_PROJECT_CONSTANT=0
    if [ "$sample" = neumann ]; then export SC26_PROJECT_CONSTANT=1; fi
    for ranks in 1 4; do
        run_dir="$root/runs/small-$SLURM_JOB_ID/$sample-$ranks"
        mkdir -p "$run_dir"
        cd "$run_dir"
        mpirun -np "$ranks" "$root/build/bin/MPI_iterative_solver" \
            "$root/tests/small_systems/${sample}_A.dat" \
            "$root/tests/small_systems/${sample}_b.dat" 0 0 | tee solver.log
        check_mode=unique
        if [ "$sample" = neumann ]; then check_mode=constant-nullspace; fi
        python3 "$root/tests/check_result.py" solver.log 1e-10 answer_x.rhs \
            "$root/tests/small_systems/${sample}_x.txt" "$check_mode"
    done
done

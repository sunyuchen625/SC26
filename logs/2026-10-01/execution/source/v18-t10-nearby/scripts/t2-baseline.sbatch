#!/bin/bash
#SBATCH --job-name=sc26_t2_baseline
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=32
#SBATCH --cpus-per-task=1
#SBATCH --mem=128G
#SBATCH --time=00:40:00
#SBATCH --chdir=/data/home/sunyc/solverchallenge26
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err
set -e
export LC_ALL=C
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 cmake/3.24.2 miniforge3/24.3.0
set -uo pipefail
export OMP_NUM_THREADS=1 SC26_PROJECT_CONSTANT=1
root=/data/home/sunyc/solverchallenge26
data=/data/home/maorz/SolverChallenge26-TenProblems/solverchallenge26_02
module list
lscpu
python3 scripts/inspect-t2.py "$data/solverchallenge26_02_A.dat" "$data/solverchallenge26_02_b.dat"
sha256sum "$data/solverchallenge26_02_A.dat" "$data/solverchallenge26_02_b.dat"
for rtol in ${SC26_RTOLS:-1e-7 5e-11}; do
    export SC26_RTOL="$rtol"
    if [ "$rtol" = 1e-7 ]; then threshold=1e-6; else threshold=1e-10; fi
    run_dir="$root/runs/t2-$SLURM_JOB_ID/$rtol"
    mkdir -p "$run_dir"
    cd "$run_dir"
    mpirun -np "$SLURM_NTASKS" sh -c \
        'exec /usr/bin/time -v -o "rank-${OMPI_COMM_WORLD_RANK}.time" "$@"' sh \
        "$root/build/bin/MPI_iterative_solver" \
        "$data/solverchallenge26_02_A.dat" "$data/solverchallenge26_02_b.dat" 0 0 | tee solver.log
    python3 "$root/tests/check_result.py" solver.log "$threshold"
done

#!/bin/bash
#SBATCH --job-name=sc26_launch_compare
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=96
#SBATCH --cpus-per-task=1
#SBATCH --mem=450G
#SBATCH --time=00:30:00
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err
set -e
export LC_ALL=C
module purge
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 miniforge3/24.3.0
set -uo pipefail
root=$PWD
frozen=$1; shift
time_bin=/data/home/sunyc/solverchallenge26/deps/gnu-time/time
export OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 MKL_DYNAMIC=FALSE MKL_THREADING_LAYER=GNU
unset SC26_RTOL SC26_PROJECT_CONSTANT
module list
lscpu
scontrol show job "$SLURM_JOB_ID"
sha256sum "$root/scripts/launch-comparison.sbatch" "$time_bin"
cd "$frozen"
sha256sum source-sha256.txt
sha256sum -c source-sha256.txt
cd "$root"
for configuration in "$@"; do
    problem=${configuration%%:*}
    ranks=${configuration#*:}
    binary="$frozen/build-t$problem/bin/MPI_iterative_solver"
    data=/data/home/maorz/SolverChallenge26-TenProblems/solverchallenge26_$problem
    run="$root/runs/t$problem-$SLURM_JOB_ID/${ranks}-ranks"
    mkdir -p "$run"; cd "$run"
    echo "LAUNCH_CONFIG problem=$problem mpi_ranks=$ranks omp_threads=1 binding=core mapping=core node=$SLURMD_NODENAME job=$SLURM_JOB_ID"
    sha256sum "$binary" "$frozen/build-t$problem/CMakeCache.txt" \
        "$data/solverchallenge26_${problem}_A.dat" "$data/solverchallenge26_${problem}_b.dat"
    set +e
    mpirun --bind-to core --map-by core --report-bindings -np "$ranks" sh -c \
        'timer=$1; shift; exec "$timer" -v -o "rank-${OMPI_COMM_WORLD_RANK}.time" "$@"' sh \
        "$time_bin" "$binary" "$data/solverchallenge26_${problem}_A.dat" \
        "$data/solverchallenge26_${problem}_b.dat" 0 0 | tee solver.log
    process_status=${PIPESTATUS[0]}
    set -e
    echo "$process_status" > process.exit
    if [ "$process_status" != 0 ]; then exit "$process_status"; fi
    python3 "$frozen/tests/check_result.py" solver.log 1e-6
done

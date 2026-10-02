#!/bin/bash
#SBATCH --job-name=sc26_remediation
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=96
#SBATCH --mem=450G
#SBATCH --time=00:30:00
#SBATCH --chdir=/data/home/sunyc/solverchallenge26/execution-20261001
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err
set -e
export LC_ALL=C
module purge
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 miniforge3/24.3.0
set -uo pipefail
root=$PWD
time_bin=/data/home/sunyc/solverchallenge26/deps/gnu-time/time
problem=$1; shift
target=MPI_direct_solver; metric=relative; threshold=1e-8; sys_type=0
case "$problem" in
    02) target=MPI_iterative_solver; threshold=1e-6 ;;
    05) target=MPI_iterative_solver ;;
    07) target=MPI_iterative_solver; threshold=1e-6 ;;
    06|08|10) sys_type=1 ;;
    03|09) ;;
    *) exit 2 ;;
esac
if [ "$problem" = 08 ]; then metric=max; fi
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK MKL_NUM_THREADS=$SLURM_CPUS_PER_TASK
export MKL_DYNAMIC=FALSE MKL_THREADING_LAYER=GNU
data=/data/home/maorz/SolverChallenge26-TenProblems/solverchallenge26_$problem
module list
lscpu
"$time_bin" --version
sha256sum "$time_bin"
env | sort | sed -n '/^SC26_/p'
sha256sum -c source-sha256.txt
sha256sum "$root/build-t$problem/bin/$target" "$root/build-t$problem/CMakeCache.txt" \
    "$data/solverchallenge26_${problem}_A.dat"
if [ "$#" = 0 ]; then set -- 01; fi
for rhs in "$@"; do
    rhs_file="$data/solverchallenge26_${problem}_b.dat"
    case "$problem" in 08|09|10) rhs_file="$data/solverchallenge26_${problem}_b_${rhs}.dat" ;; esac
    sha256sum "$rhs_file"
    run="$root/runs/t$problem-$SLURM_JOB_ID/rhs-$rhs"
    mkdir -p "$run"; cd "$run"
    set +e
    if [ "$target" = MPI_iterative_solver ]; then
        mpirun -np "$SLURM_NTASKS" sh -c \
            'timer=$1; shift; exec "$timer" -v -o "rank-${OMPI_COMM_WORLD_RANK}.time" "$@"' sh \
            "$time_bin" "$root/build-t$problem/bin/$target" "$data/solverchallenge26_${problem}_A.dat" \
            "$rhs_file" 0 "$sys_type" | tee solver.log
        process_status=${PIPESTATUS[0]}
    else
        "$time_bin" -v -o process.time "$root/build-t$problem/bin/$target" \
            "$data/solverchallenge26_${problem}_A.dat" "$rhs_file" 0 "$sys_type" | tee solver.log
        process_status=${PIPESTATUS[0]}
    fi
    set -e
    echo "$process_status" > process.exit
    if [ "$process_status" != 0 ]; then exit "$process_status"; fi
    python3 "$root/tests/check_result.py" solver.log "$threshold" --metric "$metric"
done

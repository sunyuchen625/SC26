#!/bin/bash
#SBATCH --job-name=sc26_initial
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=32
#SBATCH --cpus-per-task=1
#SBATCH --mem=128G
#SBATCH --time=00:20:00
#SBATCH --chdir=/data/home/sunyc/solverchallenge26
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err
set -e
export LC_ALL=C
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 cmake/3.24.2 miniforge3/24.3.0
set -uo pipefail
export OMP_NUM_THREADS=1
root=/data/home/sunyc/solverchallenge26
problem=$1
build="$root/build-t$problem${SC26_BUILD_SUFFIX:-}"
case "$problem" in
    01) rtols='1e-8 1e-12'; sys_type=0 ;;
    03|04|05|07) rtols=1e-12; sys_type=0 ;;
    06) rtols=1e-12; sys_type=1 ;;
    *) exit 2 ;;
esac
data=/data/home/maorz/SolverChallenge26-TenProblems/solverchallenge26_$problem
module list
lscpu
sha256sum "$build/bin/MPI_iterative_solver" "$data/solverchallenge26_${problem}_A.dat" "$data/solverchallenge26_${problem}_b.dat"
for rtol in $rtols; do
    export SC26_RTOL="$rtol"
    threshold=1e-8
    if [ "$problem" = 07 ]; then threshold=1e-6; fi
    if [ "$rtol" = 1e-8 ]; then threshold=1e-4; fi
    run_dir="$root/runs/t$problem-$SLURM_JOB_ID/$rtol"
    mkdir -p "$run_dir"
    cd "$run_dir"
    mpirun -np "$SLURM_NTASKS" sh -c \
        'exec /usr/bin/time -v -o "rank-${OMPI_COMM_WORLD_RANK}.time" "$@"' sh \
        "$build/bin/MPI_iterative_solver" \
        "$data/solverchallenge26_${problem}_A.dat" "$data/solverchallenge26_${problem}_b.dat" 0 "$sys_type" | tee solver.log
    python3 "$root/tests/check_result.py" solver.log "$threshold"
    if [ "$problem" = 01 ]; then
        python3 - <<'PY'
from pathlib import Path
import re
peak_bytes = sum(int(re.search(r'Maximum resident set size \(kbytes\): (\d+)', p.read_text())[1])*1024 for p in Path('.').glob('rank-*.time'))
assert peak_bytes <= 9_000_000_000, peak_bytes
print('T1_MEMORY_PASS sum_rank_peak_bytes=%d' % peak_bytes)
PY
    fi
done

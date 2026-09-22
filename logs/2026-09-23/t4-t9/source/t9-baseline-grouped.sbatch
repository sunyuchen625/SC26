#!/bin/bash
#SBATCH --job-name=sc26_t09_direct
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=96
#SBATCH --mem=95000M
#SBATCH --time=00:40:00
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
data=/data/home/maorz/SolverChallenge26-TenProblems/solverchallenge26_09
module list
lscpu
sha256sum "$root/build-t09/bin/MPI_direct_solver" "$data/solverchallenge26_09_A.dat"
if [ "$#" -eq 0 ]; then set -- 01 02 03 04 05 06 07 08 09 10; fi
failed=0
for rhs in "$@"; do
    sha256sum "$data/solverchallenge26_09_b_$rhs.dat"
    run_dir="$root/runs/t09-direct-$SLURM_JOB_ID/rhs-$rhs"
    mkdir -p "$run_dir"
    cd "$run_dir"
    /usr/bin/time -v -o process.time "$root/build-t09/bin/MPI_direct_solver" \
        "$data/solverchallenge26_09_A.dat" "$data/solverchallenge26_09_b_$rhs.dat" \
        0 0 | tee solver.log
    if ! python3 "$root/tests/check_result.py" solver.log 1e-8; then failed=1; fi
    python3 - <<'PY'
from pathlib import Path
import re
peak_bytes = int(re.search(r'Maximum resident set size \(kbytes\): (\d+)', Path('process.time').read_text())[1])*1024
assert peak_bytes < 100_000_000_000, peak_bytes
print('T9_MEMORY_PASS peak_bytes=%d' % peak_bytes)
PY
done
exit "$failed"

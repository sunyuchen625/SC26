#!/bin/bash
#SBATCH --job-name=sc26_t1_diagnostic
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --cpus-per-task=1
#SBATCH --mem=8500M
#SBATCH --time=00:20:00
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err
set -e
export LC_ALL=C
module purge
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 miniforge3/24.3.0
set -uo pipefail
root=$PWD
frozen=$1
time_bin=/data/home/sunyc/solverchallenge26/deps/gnu-time/time
export OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
unset SC26_RTOL SC26_PROJECT_CONSTANT
module list
lscpu
scontrol show job "$SLURM_JOB_ID"
sha256sum "$root/scripts/t1-residual-diagnostic.c" "$root/scripts/t1-residual-diagnostic.sbatch" "$time_bin"
cd "$frozen"
sha256sum source-sha256.txt
sha256sum -c source-sha256.txt
build="$frozen/build-t07"
sha256sum "$build"/libsc26*.a "$build/CMakeCache.txt" \
    /data/home/sunyc/solverchallenge26/deps/hypre/lib64/libHYPRE.a
mkdir -p "$root/bin"
set -x
mpicc -O3 -std=gnu99 -DMPI_USE -DITERATIVE_SOLVER -DSC26_PROBLEM_NUMBER=1 \
    -I "$frozen/src/include" -I "$frozen/src/problems/cpu_baseline" \
    -I /data/home/sunyc/solverchallenge26/deps/hypre/include \
    "$root/scripts/t1-residual-diagnostic.c" \
    "$build/libsc26_mpi_io.a" "$build/libsc26_mpi_diagnostics.a" "$build/libsc26_io.a" \
    /data/home/sunyc/solverchallenge26/deps/hypre/lib64/libHYPRE.a \
    -lquadmath -lpthread -ldl -lm -o "$root/bin/t1-residual-diagnostic"
set +x
sha256sum "$root/bin/t1-residual-diagnostic"
run="$root/runs/t01-$SLURM_JOB_ID/small"
mkdir -p "$run"; cd "$run"
mpirun --bind-to core --map-by core -np 1 "$root/bin/t1-residual-diagnostic" \
    "$frozen/tests/small_systems/fields07_A.dat" "$frozen/tests/small_systems/fields07_b.dat" \
    | tee solver.log
python3 - <<'PY'
import re
from pathlib import Path
log = Path('solver.log').read_text()
q = float(re.search(r'Q-Check \|\| b - Ax \|\| 2 / \|\| b \|\| 2 =\s+(\S+)', log)[1])
reported = float(re.search(r'original_relative=(\S+)', log)[1])
assert q < 1e-10, q
assert abs(reported-q) <= q*1e-6, (reported, q)
assert sum(map(int, re.findall(r'T1_RESIDUAL_BIN .* rows=(\d+)', log))) == int(re.search(r'T1_RESIDUAL_TOTAL rows=(\d+)', log)[1])
print('T1_DIAGNOSTIC_KNOWN_SYSTEM_PASS')
PY
data=/data/home/maorz/SolverChallenge26-TenProblems/solverchallenge26_01
sha256sum "$data/solverchallenge26_01_A.dat" "$data/solverchallenge26_01_b.dat"
run="$root/runs/t01-$SLURM_JOB_ID/full"
mkdir -p "$run"; cd "$run"
set +e
mpirun --bind-to core --map-by core -np 8 sh -c \
    'timer=$1; shift; exec "$timer" -v -o "rank-${OMPI_COMM_WORLD_RANK}.time" "$@"' sh \
    "$time_bin" "$root/bin/t1-residual-diagnostic" \
    "$data/solverchallenge26_01_A.dat" "$data/solverchallenge26_01_b.dat" | tee solver.log
process_status=${PIPESTATUS[0]}
set -e
echo "$process_status" > process.exit
if [ "$process_status" != 0 ]; then exit "$process_status"; fi
python3 - <<'PY'
import re
from pathlib import Path
log = Path('solver.log').read_text()
times = [p.read_text() for p in Path('.').glob('rank-*.time')]
assert len(times) == 8
assert all(int(re.search(r'Exit status: (\d+)', s)[1]) == 0 for s in times)
peak = sum(int(re.search(r'Maximum resident set size \(kbytes\): (\d+)', s)[1])*1024 for s in times)
framework = float(re.search(r'Total memory usage:\s+(\S+) MB', log)[1])*1024*1024
assert peak <= 9_000_000_000 and framework <= 9_000_000_000, (peak, framework)
assert sum(map(int, re.findall(r'T1_RESIDUAL_BIN .* rows=(\d+)', log))) == 6_291_456
q = float(re.search(r'Q-Check \|\| b - Ax \|\| 2 / \|\| b \|\| 2 =\s+(\S+)', log)[1])
reported = float(re.search(r'original_relative=(\S+)', log)[1])
assert abs(reported-q) <= q*1e-6, (reported, q)
print(f'T1_DIAGNOSTIC_COMPLETE sum_rank_peak_bytes={peak} framework_peak_bytes={framework:.0f} original_residual_after_one_solve={q:.12e}')
PY

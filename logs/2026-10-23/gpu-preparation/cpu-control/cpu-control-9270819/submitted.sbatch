#!/bin/bash
#SBATCH --job-name=sc26_t2_s4_cpu
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=96
#SBATCH --cpus-per-task=1
#SBATCH --mem=60G
#SBATCH --time=00:06:00
#SBATCH --output=sc26_t2_s4_cpu-%j.out
#SBATCH --error=sc26_t2_s4_cpu-%j.err
set -e
if [[ -z ${SLURM_JOB_ID:-} || -z ${SLURMD_NODENAME:-} || $(hostname -s) != "$SLURMD_NODENAME" ]]; then
    printf 'Submit with sbatch; execution requires the allocated compute node.\n' >&2
    exit 2
fi
export LC_ALL=C
module purge
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 cmake/3.24.2 miniforge3/24.3.0
set -uo pipefail
export OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 MKL_DYNAMIC=FALSE MKL_THREADING_LAYER=GNU
unset SC26_RTOL SC26_PROJECT_CONSTANT
work=/data/home/sunyc/solverchallenge26/gpu-preparation-20261023
root=$1
out="$work/cpu-control-$SLURM_JOB_ID"
data=/data/home/maorz/SolverChallenge26-TenProblems/solverchallenge26_02
time_bin=/data/home/sunyc/solverchallenge26/deps/gnu-time/time
mkdir -p "$out"
cp "$0" "$out/submitted.sbatch"
printf 'BUILD_ROOT=%s CONTROL_ROOT=%s\n' "$root" "$out"
scontrol show job "$SLURM_JOB_ID"
module list
lscpu
cd "$root"
sha256sum -c source-sha256.txt
sha256sum -c build-receipt.sha256
cat parent-commit.txt
sha256sum /data/home/sunyc/solverchallenge26/deps/hypre/lib64/libHYPRE.a "$time_bin"
grep -E 'HYPRE_USING_(HIP|GPU|UNIFIED_MEMORY)' /data/home/sunyc/solverchallenge26/deps/hypre/include/HYPRE_config.h
unset SC26_RTOL SC26_PROJECT_CONSTANT
printf '%s  %s\n' \
 'ea9373832008d1b0928d46053de923b872b1fed73f9b0f31aef43d8f6aec24d1' "$data/solverchallenge26_02_A.dat" \
 '3dc7f3a0e52b088e21ab1b540b37583db2828eca8385ed2a963e34789615a46e' "$data/solverchallenge26_02_b.dat" | sha256sum -c -
for repeat in 1 2; do
    mkdir -p "$out/full/repeat-$repeat"
    cd "$out/full/repeat-$repeat"
    printf 'CONTROL_REPEAT=%s RANKS=96 NODE=%s\n' "$repeat" "$(hostname -s)"
    status=0
    mpirun --bind-to core --map-by core --report-bindings -np 96 sh -c \
      'timer=$1; shift; exec "$timer" -v -o "rank-${OMPI_COMM_WORLD_RANK}.time" "$@"' sh \
      "$time_bin" "$root/build/bin/MPI_iterative_solver" "$data/solverchallenge26_02_A.dat" "$data/solverchallenge26_02_b.dat" 0 0 \
      >solver.log 2>solver.err || status=$?
    printf '%s\n' "$status" >process.exit
    test "$status" -eq 0
    python3 "$root/tests/check_result.py" solver.log 1e-6
    python3 - <<'CHECK_ROUNDS'
from pathlib import Path
import math,re
log=Path('solver.log').read_text()
rows=re.findall(r'^CHECK round (\d+) time : (\S+) s$',log,re.M)
assert [int(i)for i,_ in rows]==[1,2,3,4,5]
assert all(math.isfinite(float(t))and float(t)>0 for _,t in rows)
times=list(Path('.').glob('rank-*.time'));assert len(times)==96
rss=0
for p in times:
 text=p.read_text();assert re.search(r'Exit status: 0\s*$',text)
 rss+=int(re.search(r'Maximum resident set size \(kbytes\): (\d+)',text)[1])
assert rss<60*1024**2
print('CPU_OUTER_ROUNDS_AND_RSS_PASS sum_peak_RSS_KiB='+str(rss))
CHECK_ROUNDS
    test "$(grep -c '^T2_GMRES .* rtol=1.0e-07$' solver.log)" -eq 5
    test "$(grep -c '^T2_RHS_PROJECTION ' solver.log)" -eq 5
    grep -E '^CHECK round |^CHECK end|^T2_PHASE_SECONDS |^T2_GMRES |Q-Check' solver.log
    printf 'CPU_CONTROL_REPEAT_PASS=%s\n' "$repeat"
done
printf 'SC26_TIMED_CPU_CONTROL_COMPLETE\n'

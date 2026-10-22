#!/bin/bash
#SBATCH --job-name=sc26_t2_hip_full
#SBATCH --partition=hx1hdnormal
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --gres=dcu:Hygon:1
#SBATCH --mem=58G
#SBATCH --time=00:45:00
#SBATCH --output=sc26_t2_hip_full-%j.out
#SBATCH --error=sc26_t2_hip_full-%j.err
set -e
if [[ -z ${SLURM_JOB_ID:-} || -z ${SLURMD_NODENAME:-} || $(hostname -s) != "$SLURMD_NODENAME" ]]; then
    printf 'Submit with sbatch; execution requires the allocated compute node.\n' >&2
    exit 2
fi
export LC_ALL=C
module load compiler/gcc/12.2.0 compiler/cmake/3.24.1 compiler/dtk/25.04.2
module load mpi/openmpi/4.1.8/gcc-12.2.0/shca
set -uo pipefail
test "$#" -eq 2
mpi_prefix=/public/software/mpi/openmpi/openmpi-4.1.8
export OMPI_MCA_mca_base_component_path="$mpi_prefix/lib/openmpi:/public/software/mpi/pmix/4.2.9/lib/pmix"
export OMPI_MCA_ess_singleton_isolated=1
export OMP_NUM_THREADS=1
unset SC26_RTOL SC26_PROJECT_CONSTANT
work="$HOME/sc26-hip-20261007"
small_dir="$work/t2-$1"
run="$work/t2-full-$SLURM_JOB_ID"
data=/public/share/ac3k88uz8y/SolverChallenge26-TenProblems/solverchallenge26_02
mkdir -p "$run"
cp "$0" "$run/submitted.sbatch"
printf 'JOB_ID=%s NODE=%s SMALL_JOB=%s TIMING_SCOPE=prototype-inclusive\n' "$SLURM_JOB_ID" "$(hostname -s)" "$1"
scontrol show job "$SLURM_JOB_ID"
module list
grep '^MemTotal:' /proc/meminfo
hy-smi
rocminfo | grep -E 'Name:|Size:'
printf 'HIP_VISIBLE_DEVICES=%s ROCR_VISIBLE_DEVICES=%s CUDA_VISIBLE_DEVICES=%s\n' \
    "${HIP_VISIBLE_DEVICES:-}" "${ROCR_VISIBLE_DEVICES:-}" "${CUDA_VISIBLE_DEVICES:-}"
cd "$small_dir"
sha256sum -c source-sha256.txt
cat parent-commit.txt
printf '%s  %s\n' "$2" build/bin/MPI_iterative_solver \
    '7a5f354a82e8f5429190428f1a1c3f1381113e9eb7d4265de5b197cd906a96e9' source-sha256.txt \
    '5e0d630e62ea9a7c4d1330045e19e5d20594a5ee7cefcf445fe6b105d6d1e1bd' build/CMakeCache.txt \
    'e3887d90f71190657cd3315b8b4e896bbf238ad38b0178f0b2b05ad8535deb36' \
    "$work/install-892588/lib/libHYPRE.a" | sha256sum -c -
sha256sum source-sha256.txt build/CMakeCache.txt "$run/submitted.sbatch"
grep -E 'HYPRE_USING_(HIP|GPU|UNIFIED_MEMORY)' "$work/install-892588/include/HYPRE_config.h"
grep -E 'HYPRE_ENABLE_(HIP|UNIFIED_MEMORY)' "$work/install-892588/lib/cmake/HYPRE/HYPREConfig.cmake"
ldd build/bin/MPI_iterative_solver
printf '%s  %s\n' \
    'ea9373832008d1b0928d46053de923b872b1fed73f9b0f31aef43d8f6aec24d1' "$data/solverchallenge26_02_A.dat" \
    '3dc7f3a0e52b088e21ab1b540b37583db2828eca8385ed2a963e34789615a46e' "$data/solverchallenge26_02_b.dat" \
    | sha256sum -c -
python3 - "$data/solverchallenge26_02_A.dat" "$data/solverchallenge26_02_b.dat" <<'SC26_INPUT_ID'
from pathlib import Path
import struct
import sys
for name, count in zip(sys.argv[1:], (4, 2)):
    with open(name, 'rb') as source:
        header = struct.unpack('>' + 'i' * count, source.read(4 * count))
    print('PETSC_INPUT file=%s bytes=%d header=%s' % (name, Path(name).stat().st_size, header))
SC26_INPUT_ID
cd "$run"
export SC26_RTOL=1e-11
for sample in poisson nonsymmetric neumann; do
    export SC26_PROJECT_CONSTANT=0
    check_args=(solver.log 1e-10 answer_x.rhs "$small_dir/tests/small_systems/${sample}_x.txt")
    if [[ "$sample" == neumann ]]; then
        export SC26_PROJECT_CONSTANT=1
        check_args+=(constant-nullspace)
    fi
    mkdir -p "device-small/$sample"
    cd "device-small/$sample"
    solver_exit=0
    /usr/bin/time -v -o process.time "$small_dir/build/bin/MPI_iterative_solver" \
        "$small_dir/tests/small_systems/${sample}_A.dat" \
        "$small_dir/tests/small_systems/${sample}_b.dat" 0 0 \
        >solver.log 2>solver.err || solver_exit=$?
    printf '%s\n' "$solver_exit" >process.exit
    printf 'CASE=%s SOLVER_EXIT_CODE=%s\n' "$sample" "$solver_exit"
    cat solver.err
    if [[ "$solver_exit" -ne 0 ]]; then tail -n 30 solver.log >&2; exit "$solver_exit"; fi
    test ! -s solver.err
    test "$(grep -c '^T2_HIP_POLICY memory_device=1 execution_device=1$' solver.log)" -eq 5
    python3 "$small_dir/tests/check_result.py" "${check_args[@]}"
    cd "$run"
done
unset SC26_RTOL SC26_PROJECT_CONSTANT
printf 'SC26_T2_HIP_DEVICE_SMALL_COMPLETE\n'
solver_exit=0
/usr/bin/time -v -o process.time "$small_dir/build/bin/MPI_iterative_solver" \
    "$data/solverchallenge26_02_A.dat" "$data/solverchallenge26_02_b.dat" 0 0 \
    >solver.log 2>solver.err || solver_exit=$?
printf '%s\n' "$solver_exit" >process.exit
printf 'SOLVER_EXIT_CODE=%s\n' "$solver_exit"
cat solver.err
if [[ "$solver_exit" -ne 0 ]]; then tail -n 30 solver.log >&2; exit "$solver_exit"; fi
test ! -s solver.err
test "$(grep -c '^T2_HIP_POLICY memory_device=1 execution_device=1$' solver.log)" -eq 5
test "$(grep -c '^T2_PHASE_SECONDS ' solver.log)" -eq 5
test "$(grep -c '^T2_RHS_PROJECTION ' solver.log)" -eq 5
test "$(grep -c '^T2_GMRES .* rtol=1.0e-07$' solver.log)" -eq 5
python3 "$small_dir/tests/check_result.py" solver.log 1e-6
grep -E '^T2_GMRES |^T2_PHASE_SECONDS |Q-Check|time' solver.log
cat process.time
awk -v limit="$((SLURM_MEM_PER_NODE * 1024))" '/Maximum resident set size/ {if ($NF > limit) exit 1}' process.time
printf 'SC26_T2_HIP_FULL_COMPLETE\n'

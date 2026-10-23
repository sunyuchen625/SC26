#!/bin/bash
#SBATCH --job-name=sc26_t2_relax18
#SBATCH --partition=hx1hdnormal
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --gres=dcu:Hygon:1
#SBATCH --mem=58G
#SBATCH --time=00:45:00
#SBATCH --output=sc26_t2_relax18-%j.out
#SBATCH --error=sc26_t2_relax18-%j.err
set -e
if [[ -z ${SLURM_JOB_ID:-} || -z ${SLURMD_NODENAME:-} || $(hostname -s) != "$SLURMD_NODENAME" ]]; then
    printf 'Submit with sbatch; execution requires the allocated compute node.\n' >&2
    exit 2
fi
export LC_ALL=C
module load compiler/gcc/12.2.0 compiler/cmake/3.24.1 compiler/dtk/25.04.2
module load mpi/openmpi/4.1.8/gcc-12.2.0/shca
set -uo pipefail
mpi_prefix=/public/software/mpi/openmpi/openmpi-4.1.8
dtk_root=/public/software/compiler/dtk-25.04.2
export OMPI_MCA_mca_base_component_path="$mpi_prefix/lib/openmpi:/public/software/mpi/pmix/4.2.9/lib/pmix"
export OMPI_MCA_ess_singleton_isolated=1
export OMP_NUM_THREADS=1
work="$HOME/sc26-hip-20261007"
baseline="$work/t2-897432"
run="$work/relax18-$SLURM_JOB_ID"
candidate="$run/candidate"
data=/public/share/ac3k88uz8y/SolverChallenge26-TenProblems/solverchallenge26_02
mkdir -p "$candidate"
cp "$0" "$run/submitted.sbatch"
printf 'EXPERIMENT=relax6_vs_relax18 JOB=%s NODE=%s OMP=%s\n' "$SLURM_JOB_ID" "$(hostname -s)" "$OMP_NUM_THREADS"
scontrol show job "$SLURM_JOB_ID"
module list
hy-smi
rocminfo | grep -E 'Name:|Size:'
printf '%s  %s\n' \
 '9708c99de61699a0c9d7452503ab07c97284ed3287b57185a816947d8de58ee0' "$work/SC26_T2_HIP_source_20261009.tar.gz" \
 '7f02c33a25b0f30b80224b505e73a63a8f2dbda3f3cddd064003743fd6ea168d' "$baseline/build/bin/MPI_iterative_solver" \
 'e3887d90f71190657cd3315b8b4e896bbf238ad38b0178f0b2b05ad8535deb36' "$work/install-892588/lib/libHYPRE.a" \
 'ea9373832008d1b0928d46053de923b872b1fed73f9b0f31aef43d8f6aec24d1' "$data/solverchallenge26_02_A.dat" \
 '3dc7f3a0e52b088e21ab1b540b37583db2828eca8385ed2a963e34789615a46e' "$data/solverchallenge26_02_b.dat" | sha256sum -c -
cd "$baseline"
sha256sum -c source-sha256.txt
cd "$candidate"
tar -xzf "$work/SC26_T2_HIP_source_20261009.tar.gz"
sha256sum -c source-sha256.txt
python3 - <<'PATCH_SOLVER'
from pathlib import Path
import hashlib
p = Path('src/problems/problem02/solver.c')
original = p.read_bytes()
before = b'HYPRE_BoomerAMGSetRelaxType(solver->amg, 6)'
assert original.count(before) == 1
patched = original.replace(before, b'HYPRE_BoomerAMGSetRelaxType(solver->amg, 18)')
assert hashlib.sha256(patched).hexdigest() == '4e08cf8c7fd6892943fffb17f393ce175a4d7714ad1ee98acf8d3584bb9854ca'
p.write_bytes(patched)
lines = []
for line in Path('source-sha256.txt').read_text().splitlines():
    _, name = line.split('  ', 1)
    lines.append(hashlib.sha256(Path(name).read_bytes()).hexdigest() + '  ' + name)
Path('source-sha256.txt').write_text('\n'.join(lines) + '\n')
print('RELAX18_SOURCE_SHA256=' + hashlib.sha256(patched).hexdigest())
PATCH_SOLVER
sha256sum -c source-sha256.txt
sha256sum source-sha256.txt src/problems/problem02/solver.c "$run/submitted.sbatch"
grep -E 'HYPRE_USING_(HIP|GPU|UNIFIED_MEMORY)' "$work/install-892588/include/HYPRE_config.h"
cmake -S src -B build -DCMAKE_BUILD_TYPE=Release \
 -DSC26_PROBLEM=02 -DSC26_T2_HIP=ON -DSC26_BUILD_MPI=ON \
 -DSC26_BUILD_MPI_GPU=OFF -DSC26_ENABLE_FLOAT128=ON \
 -DCMAKE_C_COMPILER="$mpi_prefix/bin/mpicc" \
 -DCMAKE_CXX_COMPILER="$dtk_root/llvm/bin/clang++" \
 -DCMAKE_HIP_COMPILER="$dtk_root/llvm/bin/clang++" \
 -DCMAKE_HIP_COMPILER_ROCM_ROOT="$dtk_root/hip" \
 -DCMAKE_HIP_ARCHITECTURES=gfx936 \
 -DCMAKE_HIP_FLAGS="--gpu-max-threads-per-block=1024" \
 -DCMAKE_EXE_LINKER_FLAGS="-L$dtk_root/llvm/lib/clang/17.0.0/lib/linux" \
 -DHYPRE_DIR="$work/install-892588/lib/cmake/HYPRE" \
 -DROCM_PATH="$dtk_root/hip" -Dhip_DIR="$dtk_root/hip/lib/cmake/hip" \
 -Drocblas_DIR="$dtk_root/lib/cmake/rocblas" \
 -Drocsparse_DIR="$dtk_root/lib/cmake/rocsparse" \
 -Drocrand_DIR="$dtk_root/lib/cmake/rocrand" >configure.log 2>&1 \
 || { status=$?; tail -n 35 configure.log >&2; exit "$status"; }
cmake --build build --parallel "$SLURM_CPUS_PER_TASK" --target MPI_iterative_solver >build.log 2>&1 \
 || { status=$?; tail -n 35 build.log >&2; exit "$status"; }
sha256sum build/CMakeCache.txt build/bin/MPI_iterative_solver
ldd build/bin/MPI_iterative_solver
python3 tests/make_small_systems.py
for variant in baseline l1jacobi; do
    source_dir="$baseline"
    if [[ "$variant" == l1jacobi ]]; then source_dir="$candidate"; fi
    binary="$source_dir/build/bin/MPI_iterative_solver"
    printf 'VARIANT=%s BINARY=%s\n' "$variant" "$binary"
    sha256sum "$binary"
    for sample in poisson nonsymmetric neumann; do
        export SC26_RTOL=1e-11 SC26_PROJECT_CONSTANT=0
        args=(solver.log 1e-10 answer_x.rhs "$source_dir/tests/small_systems/${sample}_x.txt")
        if [[ "$sample" == neumann ]]; then
            export SC26_PROJECT_CONSTANT=1
            args+=(constant-nullspace)
        fi
        mkdir -p "$run/$variant/small/$sample"
        cd "$run/$variant/small/$sample"
        status=0
        /usr/bin/time -v -o process.time "$binary" \
         "$source_dir/tests/small_systems/${sample}_A.dat" \
         "$source_dir/tests/small_systems/${sample}_b.dat" 0 0 >solver.log 2>solver.err || status=$?
        printf '%s\n' "$status" >process.exit
        printf 'VARIANT=%s CASE=%s EXIT=%s\n' "$variant" "$sample" "$status"
        cat solver.err
        if [[ "$status" -ne 0 ]]; then tail -n 35 solver.log >&2; exit "$status"; fi
        test ! -s solver.err
        test "$(grep -c '^T2_HIP_POLICY memory_device=1 execution_device=1$' solver.log)" -eq 5
        test "$(grep -c '^T2_PHASE_SECONDS ' solver.log)" -eq 5
        python3 "$source_dir/tests/check_result.py" "${args[@]}"
    done
    unset SC26_RTOL SC26_PROJECT_CONSTANT
    mkdir -p "$run/$variant/full"
    cd "$run/$variant/full"
    status=0
    /usr/bin/time -v -o process.time "$binary" \
     "$data/solverchallenge26_02_A.dat" "$data/solverchallenge26_02_b.dat" 0 0 >solver.log 2>solver.err || status=$?
    printf '%s\n' "$status" >process.exit
    printf 'VARIANT=%s FULL_EXIT=%s\n' "$variant" "$status"
    cat solver.err
    if [[ "$status" -ne 0 ]]; then tail -n 35 solver.log >&2; exit "$status"; fi
    test ! -s solver.err
    test "$(grep -c '^T2_HIP_POLICY memory_device=1 execution_device=1$' solver.log)" -eq 5
    test "$(grep -c '^T2_PHASE_SECONDS ' solver.log)" -eq 5
    test "$(grep -c '^T2_RHS_PROJECTION ' solver.log)" -eq 5
    test "$(grep -c '^T2_GMRES .* rtol=1.0e-07$' solver.log)" -eq 5
    python3 "$source_dir/tests/check_result.py" solver.log 1e-6
    grep -E '^T2_GMRES |^T2_PHASE_SECONDS |Q-Check|time' solver.log
    cat process.time
    awk -v limit="$((SLURM_MEM_PER_NODE * 1024))" '/Maximum resident set size/ {if ($NF > limit) exit 1}' process.time
    printf 'VARIANT=%s FULL_PASS\n' "$variant"
done
printf 'SC26_RELAX18_COMPARISON_COMPLETE\n'

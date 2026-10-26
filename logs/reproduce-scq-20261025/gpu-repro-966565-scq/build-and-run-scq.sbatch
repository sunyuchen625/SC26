#!/bin/bash
#SBATCH --job-name=sc26_t2_hip_scq
#SBATCH --partition=hx1hdnormal
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --gres=dcu:Hygon:1
#SBATCH --mem=58G
#SBATCH --time=00:45:00
#SBATCH --output=sc26_t2_hip_scq-%j.out
#SBATCH --error=sc26_t2_hip_scq-%j.err

set -e
if [[ -z ${SLURM_JOB_ID:-} || -z ${SLURMD_NODENAME:-} || $(hostname -s) != "$SLURMD_NODENAME" ]]; then
    printf 'Submit with sbatch; execution requires the allocated compute node.
' >&2
    exit 2
fi
export LC_ALL=C
module load compiler/gcc/12.2.0 compiler/cmake/3.24.1 compiler/dtk/25.04.2
module load mpi/openmpi/4.1.8/gcc-12.2.0/shca
set -uo pipefail

mpi_prefix=/public/software/mpi/openmpi/openmpi-4.1.8
dtk_root=/public/software/compiler/dtk-25.04.2
hypre_prefix=/public/home/travissun/sc26-hip-20261007/install-892588
data=/public/share/ac3k88uz8y/SolverChallenge26-TenProblems/solverchallenge26_02

export OMPI_MCA_mca_base_component_path="$mpi_prefix/lib/openmpi:/public/software/mpi/pmix/4.2.9/lib/pmix"
export OMPI_MCA_ess_singleton_isolated=1
export OMP_NUM_THREADS=1

root=/public/home/travissun/sc26-hip-20261007/reproduce-gpu-20261024-scq
cd "$root"
printf 'OPERATOR=scq JOB=%s NODE=%s USER=%s DIR=%s
' "$SLURM_JOB_ID" "$(hostname -s)" "$(id -un)" "$root"
scontrol show job "$SLURM_JOB_ID"
module list
hy-smi
rocminfo | grep -E 'Name:|Size:'

sha256sum source-sha256.txt src/problems/problem02/solver.c src/apps/MPI_iterative_solver.c
sha256sum -c source-sha256.txt
printf '%s  %s
' 'e3887d90f71190657cd3315b8b4e896bbf238ad38b0178f0b2b05ad8535deb36' "$hypre_prefix/lib/libHYPRE.a" 'ea9373832008d1b0928d46053de923b872b1fed73f9b0f31aef43d8f6aec24d1' "$data/solverchallenge26_02_A.dat" '3dc7f3a0e52b088e21ab1b540b37583db2828eca8385ed2a963e34789615a46e' "$data/solverchallenge26_02_b.dat" | sha256sum -c -

cmake -S src -B build -DCMAKE_BUILD_TYPE=Release -DSC26_PROBLEM=02 -DSC26_T2_HIP=ON -DSC26_BUILD_MPI=ON -DSC26_BUILD_MPI_GPU=OFF -DSC26_ENABLE_FLOAT128=ON -DCMAKE_C_COMPILER="$mpi_prefix/bin/mpicc" -DCMAKE_CXX_COMPILER="$dtk_root/llvm/bin/clang++" -DCMAKE_HIP_COMPILER="$dtk_root/llvm/bin/clang++" -DCMAKE_HIP_COMPILER_ROCM_ROOT="$dtk_root/hip" -DCMAKE_HIP_ARCHITECTURES=gfx936 -DCMAKE_HIP_FLAGS="--gpu-max-threads-per-block=1024" -DCMAKE_EXE_LINKER_FLAGS="-L$dtk_root/llvm/lib/clang/17.0.0/lib/linux" -DHYPRE_DIR="$hypre_prefix/lib/cmake/HYPRE" -DROCM_PATH="$dtk_root/hip" -Dhip_DIR="$dtk_root/hip/lib/cmake/hip" -Drocblas_DIR="$dtk_root/lib/cmake/rocblas" -Drocsparse_DIR="$dtk_root/lib/cmake/rocsparse" -Drocrand_DIR="$dtk_root/lib/cmake/rocrand" > configure.log 2>&1

cmake --build build --parallel "$SLURM_CPUS_PER_TASK" --target MPI_iterative_solver > build.log 2>&1
sha256sum build/CMakeCache.txt build/bin/MPI_iterative_solver
ldd build/bin/MPI_iterative_solver

python3 tests/make_small_systems.py
for sample in poisson nonsymmetric neumann; do
    export SC26_RTOL=1e-11 SC26_PROJECT_CONSTANT=0
    args=(solver.log 1e-10 answer_x.rhs "$root/tests/small_systems/${sample}_x.txt")
    if [[ "$sample" == neumann ]]; then export SC26_PROJECT_CONSTANT=1; args+=(constant-nullspace); fi
    mkdir -p "$root/runs-$SLURM_JOB_ID/small/$sample"
    cd "$root/runs-$SLURM_JOB_ID/small/$sample"
    status=0
    /usr/bin/time -v -o process.time "$root/build/bin/MPI_iterative_solver" "$root/tests/small_systems/${sample}_A.dat" "$root/tests/small_systems/${sample}_b.dat" 0 0 >solver.log 2>solver.err || status=$?
    printf '%s
' "$status" >process.exit
    test "$status" -eq 0 && test ! -s solver.err
    python3 "$root/tests/check_result.py" "${args[@]}"
done

unset SC26_RTOL SC26_PROJECT_CONSTANT
full_out="$root/runs-$SLURM_JOB_ID/full"
mkdir -p "$full_out"
cd "$full_out"
status=0
/usr/bin/time -v -o process.time "$root/build/bin/MPI_iterative_solver" "$data/solverchallenge26_02_A.dat" "$data/solverchallenge26_02_b.dat" 0 0 >solver.log 2>solver.err || status=$?
printf '%s
' "$status" >process.exit
test "$status" -eq 0
test ! -s solver.err
test "$(grep -c '^T2_HIP_POLICY memory_device=1 execution_device=1$' solver.log)" -eq 5
test "$(grep -c '^T2_PHASE_SECONDS ' solver.log)" -eq 5
test "$(grep -c '^T2_PREP_CALL_SECONDS ' solver.log)" -eq 5
test "$(grep -c '^T2_RHS_PROJECTION ' solver.log)" -eq 5
test "$(grep -c '^T2_GMRES .* rtol=1.0e-07$' solver.log)" -eq 5
python3 "$root/tests/check_result.py" solver.log 1e-6
grep -E '^CHECK round |^CHECK end|^T2_PREP_CALL_SECONDS |^T2_PHASE_SECONDS |^T2_GMRES |Q-Check' solver.log
cat process.time
printf 'SC26_GPU_REPRODUCTION_COMPLETE JOB=%s
' "$SLURM_JOB_ID"

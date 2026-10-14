#!/bin/bash
#SBATCH --job-name=sc26_t2_hip_build
#SBATCH --partition=hx1hdnormal
#SBATCH --nodes=1
#SBATCH --nodelist=f11r2n10
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --gres=dcu:Hygon:1
#SBATCH --time=00:15:00
#SBATCH --output=sc26_t2_hip_build-%j.out
#SBATCH --error=sc26_t2_hip_build-%j.err
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
export OMPI_MCA_mca_base_component_path="$mpi_prefix/lib/openmpi:/public/software/mpi/pmix/4.2.9/lib/pmix"
export OMPI_MCA_ess_singleton_isolated=1
export OMP_NUM_THREADS=1
dtk_root=/public/software/compiler/dtk-25.04.2
work="$HOME/sc26-hip-20261007"
prototype_dir="$work/t2-$SLURM_JOB_ID"
mkdir -p "$prototype_dir"
cd "$prototype_dir"
cp "$0" submitted.sbatch
sha256sum submitted.sbatch
printf 'JOB_ID=%s NODE=%s PROTOTYPE=%s HYPRE_BUILD_JOB=892588\n' \
    "$SLURM_JOB_ID" "$(hostname -s)" "$prototype_dir"
scontrol show job "$SLURM_JOB_ID"
module list
printf '%s  %s\n' '9708c99de61699a0c9d7452503ab07c97284ed3287b57185a816947d8de58ee0' \
    "$work/SC26_T2_HIP_source_20261009.tar.gz" | sha256sum -c -
tar -xzf "$work/SC26_T2_HIP_source_20261009.tar.gz"
sha256sum source-sha256.txt
sha256sum -c source-sha256.txt
cat parent-commit.txt
python3 --version
/usr/bin/time --version
printf '%s  %s\n' 'e3887d90f71190657cd3315b8b4e896bbf238ad38b0178f0b2b05ad8535deb36' \
    "$work/install-892588/lib/libHYPRE.a" | sha256sum -c -
grep -E 'HYPRE_USING_(HIP|GPU|UNIFIED_MEMORY)' "$work/install-892588/include/HYPRE_config.h"
grep -E 'HYPRE_ENABLE_(HIP|UNIFIED_MEMORY)' "$work/install-892588/lib/cmake/HYPRE/HYPREConfig.cmake"
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
    -Drocrand_DIR="$dtk_root/lib/cmake/rocrand" \
    >configure.log 2>&1 || { configure_exit=$?; tail -n 30 configure.log >&2; exit "$configure_exit"; }
cmake --build build --parallel "$SLURM_CPUS_PER_TASK" --target MPI_iterative_solver \
    >build.log 2>&1 || { build_exit=$?; tail -n 30 build.log >&2; exit "$build_exit"; }
sha256sum build/CMakeCache.txt build/bin/MPI_iterative_solver
grep -E '^(SC26_|HYPRE_DIR|CMAKE_(C|CXX|HIP)_COMPILER)' build/CMakeCache.txt
python3 tests/make_small_systems.py
export SC26_RTOL=1e-11
for sample in poisson nonsymmetric neumann; do
    export SC26_PROJECT_CONSTANT=0
    check_args=(solver.log 1e-10 answer_x.rhs "$prototype_dir/tests/small_systems/${sample}_x.txt")
    if [[ "$sample" == neumann ]]; then
        export SC26_PROJECT_CONSTANT=1
        check_args+=(constant-nullspace)
    fi
    mkdir -p "runs/$sample"
    cd "runs/$sample"
    solver_exit=0
    /usr/bin/time -v -o process.time "$prototype_dir/build/bin/MPI_iterative_solver" \
        "$prototype_dir/tests/small_systems/${sample}_A.dat" \
        "$prototype_dir/tests/small_systems/${sample}_b.dat" 0 0 \
        >solver.log 2>solver.err || solver_exit=$?
    printf 'CASE=%s SOLVER_EXIT_CODE=%s\n' "$sample" "$solver_exit"
    cat solver.err
    if [[ "$solver_exit" -ne 0 ]]; then tail -n 30 solver.log >&2; exit "$solver_exit"; fi
    test ! -s solver.err
    test "$(grep -c '^T2_HIP_POLICY memory_device=1 execution_device=1$' solver.log)" -eq 5
    python3 "$prototype_dir/tests/check_result.py" "${check_args[@]}"
    grep 'Maximum resident set size' process.time
    cd "$prototype_dir"
done
printf 'SC26_T2_HIP_SMALL_COMPLETE\n'

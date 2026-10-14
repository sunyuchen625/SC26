#!/bin/bash
#SBATCH --job-name=sc26_hypre_hip_build
#SBATCH --partition=hx1hdnormal
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --gres=dcu:Hygon:1
#SBATCH --time=01:30:00
#SBATCH --output=sc26_hypre_hip_build-%j.out
#SBATCH --error=sc26_hypre_hip_build-%j.err
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
export OMP_NUM_THREADS=1
dtk_root=/public/software/compiler/dtk-25.04.2
work="$HOME/sc26-hip-20261007"
source_dir="$work/source-$SLURM_JOB_ID"
build_dir="$work/build-$SLURM_JOB_ID"
install_dir="$work/install-$SLURM_JOB_ID"
cd "$work"
printf '%s\n' '0f9103c34bce7a5dcbdb79a502720fc8aab4db9fd0146e0791cde7ec878f27da  hypre-2.33.0.tar.gz' | sha256sum -c -
mkdir -p "$source_dir"
tar -xzf hypre-2.33.0.tar.gz -C "$source_dir" --strip-components=1
printf 'JOB_ID=%s NODE=%s BUILD=%s INSTALL=%s\n' "$SLURM_JOB_ID" "$(hostname -s)" "$build_dir" "$install_dir"
scontrol show job "$SLURM_JOB_ID"
module list
cmake -S "$source_dir/src" -B "$build_dir" \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$install_dir" \
    -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_COMPILER="$mpi_prefix/bin/mpicc" \
    -DCMAKE_CXX_COMPILER="$dtk_root/llvm/bin/clang++" \
    -DMPI_CXX_COMPILER="$mpi_prefix/bin/mpicxx" \
    -DCMAKE_HIP_COMPILER="$dtk_root/llvm/bin/clang++" \
    -DCMAKE_HIP_COMPILER_ROCM_ROOT="$dtk_root/hip" \
    -DCMAKE_HIP_ARCHITECTURES=gfx936 \
    -DROCM_PATH="$dtk_root/hip" \
    -Dhip_DIR="$dtk_root/hip/lib/cmake/hip" \
    -Drocblas_DIR="$dtk_root/lib/cmake/rocblas" \
    -Drocsparse_DIR="$dtk_root/lib/cmake/rocsparse" \
    -Drocrand_DIR="$dtk_root/lib/cmake/rocrand" \
    -DHYPRE_ENABLE_MPI=ON -DHYPRE_ENABLE_HIP=ON \
    -DHYPRE_ENABLE_CUDA=OFF -DHYPRE_ENABLE_SYCL=OFF \
    -DHYPRE_ENABLE_UNIFIED_MEMORY=OFF -DHYPRE_ENABLE_ROCSOLVER=OFF \
    -DHYPRE_BUILD_TESTS=ON -DHYPRE_BUILD_EXAMPLES=OFF
cmake --build "$build_dir" --parallel "$SLURM_CPUS_PER_TASK" --target HYPRE ij
cmake --install "$build_dir"
sha256sum "$build_dir/CMakeCache.txt" "$build_dir/test/ij" "$install_dir/lib/libHYPRE.a"
printf 'HYPRE_HIP_LIBRARY_BUILT\n'
"$build_dir/test/ij" -n 8 8 8 -P 1 1 1 -solver 1 \
    -memory_device -exec_device -rlx 18 -rlx_coarse 18 -tol 1e-8
printf 'HYPRE_HIP_BUILD_JOB_COMPLETE\n'

#!/bin/bash
#SBATCH --job-name=sc26_formal_build
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --time=00:25:00
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err
set -euo pipefail
shared=$PWD
scratch=$(mktemp -d "/tmp/sc26-build-$SLURM_JOB_ID.XXXXXX")
printf 'Building on %s in %s\n' "$SLURMD_NODENAME" "$scratch"
cd "$scratch"
tar -xzf "$shared/formal-snapshot-v2.tar.gz"
mkdir logs
trap 'cd "$scratch" && cp -a logs/. "$shared/logs/"; if [[ -d runs ]]; then tar -czf "$shared/logs/small-$SLURM_JOB_ID.tar.gz" runs; fi; rm -rf -- "$scratch"' EXIT
if [[ $* == 05 ]]; then
    module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0
    deps=/data/home/sunyc/solverchallenge26/deps
    cp "$deps/hypre-2.33.0/src/parcsr_ls/par_mgr_setup.c" .
    patch par_mgr_setup.c < scripts/hypre-2.33-mgr-repeat.patch
    flags="$deps/hypre-build/CMakeFiles/HYPRE.dir/flags.make"
    read -r -a includes <<< "$(sed -n 's/^C_INCLUDES = //p' "$flags")"
    read -r -a cflags <<< "$(sed -n 's/^C_FLAGS = //p' "$flags")"
    mpicc "${includes[@]}" "${cflags[@]}" -c par_mgr_setup.c -o par_mgr_setup.c.o
    export SC26_HYPRE_PREFIX="$scratch/hypre-mgr"
    mkdir -p "$SC26_HYPRE_PREFIX/lib64"
    ln -s "$deps/hypre/include" "$SC26_HYPRE_PREFIX/include"
    cp -R "$deps/hypre/lib64/cmake" "$SC26_HYPRE_PREFIX/lib64/"
    cp "$deps/hypre/lib64/libHYPRE.a" "$SC26_HYPRE_PREFIX/lib64/"
    ar r "$SC26_HYPRE_PREFIX/lib64/libHYPRE.a" par_mgr_setup.c.o
    sha256sum scripts/hypre-2.33-mgr-repeat.patch par_mgr_setup.c "$SC26_HYPRE_PREFIX/lib64/libHYPRE.a"
fi
bash scripts/remediation-build.sbatch "$@"
cd "$scratch"
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 miniforge3/24.3.0
export MKL_THREADING_LAYER=GNU MKL_DYNAMIC=FALSE OMP_NUM_THREADS=4 MKL_NUM_THREADS=4 SC26_PARDISO_ORDERING=3
for sample in complex complex_unsorted complex_structural; do
    rhs=$sample
    if [ "$sample" = complex_unsorted ]; then rhs=complex; fi
    run="$scratch/runs/small-$SLURM_JOB_ID/t10-${sample}-ord3"
    mkdir -p "$run"; cd "$run"
    /data/home/sunyc/solverchallenge26/deps/gnu-time/time -v -o process.time \
        "$scratch/build-t10/bin/MPI_direct_solver" \
        "$scratch/tests/small_systems/${sample}_A.dat" "$scratch/tests/small_systems/${rhs}_b.dat" \
        0 1 | tee solver.log
    python3 "$scratch/tests/check_result.py" solver.log 1e-10 answer_x.rhs \
        "$scratch/tests/small_systems/${rhs}_x.txt" --metric relative --formal
done
unset SC26_PARDISO_ORDERING
cd "$scratch"
cp source-sha256.txt scripts/remediation-baseline.sbatch tests/check_result.py "$shared/"
for build in build-t*; do
    mkdir -p "$shared/$build/bin"
    cp "$build"/bin/* "$shared/$build/bin/"
    cp "$build/CMakeCache.txt" "$shared/$build/"
done
printf 'SC26_BUILD_AND_SMOKE_PASS\n'

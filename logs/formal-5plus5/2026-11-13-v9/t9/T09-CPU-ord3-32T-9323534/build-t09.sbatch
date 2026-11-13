#!/bin/bash
#SBATCH --job-name=sc26_v9_t09_build
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --time=00:15:00
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err
set -euo pipefail
if [[ -z ${SLURM_JOB_ID:-} || -z ${SLURMD_NODENAME:-} || $(hostname -s) != "$SLURMD_NODENAME" ]]; then
    printf 'Submit with sbatch; execution requires the allocated compute node.\n' >&2
    exit 2
fi
export LC_ALL=C
module purge
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 cmake/3.24.2 miniforge3/24.3.0
shared=$PWD
scratch=$(mktemp -d "/tmp/sc26-build-t09-$SLURM_JOB_ID.XXXXXX")
printf 'Building T09 on %s in %s\n' "$SLURMD_NODENAME" "$scratch"
cd "$scratch"
tar -xzf "$shared/source.tar.gz"
mkdir -p logs
trap 'cp -a "$scratch/logs/." "$shared/logs/"; if [[ -d "$scratch/runs" ]]; then tar -czf "$shared/logs/small-$SLURM_JOB_ID.tar.gz" -C "$scratch" runs; fi; rm -rf -- "$scratch"' EXIT

root=$PWD
time_bin=/data/home/sunyc/solverchallenge26/deps/gnu-time/time
export MKLROOT=/data/public/software/intel/oneapi/mkl/2022.0.0
export MKL_THREADING_LAYER=GNU MKL_DYNAMIC=FALSE OMP_NUM_THREADS=4 MKL_NUM_THREADS=4
module list
lscpu
"$time_bin" --version
sha256sum "$time_bin"
sha256sum source-sha256.txt
sha256sum -c source-sha256.txt
python3 tests/make_small_systems.py

cmake -S src -B build-t09 -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc \
    -DSC26_PROBLEM=09 -DSC26_BUILD_MPI_GPU=OFF \
    -DCMAKE_PREFIX_PATH=/data/home/sunyc/solverchallenge26/deps/hypre \
    > "logs/configure-t09-$SLURM_JOB_ID.log" 2>&1
cmake --build build-t09 -j4 --target MPI_direct_solver \
    > "logs/build-t09-$SLURM_JOB_ID.log" 2>&1
sha256sum build-t09/bin/MPI_direct_solver build-t09/CMakeCache.txt

for ord in default 3; do
    if [[ $ord == default ]]; then
        unset SC26_PARDISO_ORDERING
        expected_ord="ordering=2"
    else
        export SC26_PARDISO_ORDERING="$ord"
        expected_ord="ordering=$ord"
    fi
    for sample in poisson nonsymmetric scaled; do
        run="$root/runs/small-$SLURM_JOB_ID/t09-$ord-$sample"
        mkdir -p "$run"; cd "$run"
        "$time_bin" -v -o process.time "$root/build-t09/bin/MPI_direct_solver" \
            "$root/tests/small_systems/${sample}_A.dat" "$root/tests/small_systems/${sample}_b.dat" \
            0 0 | tee solver.log
        grep -q "T9_PARDISO_CONFIG .* ${expected_ord} " solver.log
        python3 "$root/tests/check_result.py" solver.log 1e-10 answer_x.rhs \
            "$root/tests/small_systems/${sample}_x.txt" --metric relative --formal
    done
done

mkdir -p "$shared/build-t09/bin"
cp "$root/build-t09/bin/MPI_direct_solver" "$shared/build-t09/bin/"
cp "$root/build-t09/CMakeCache.txt" "$shared/build-t09/"
printf 'SC26_T09_BUILD_AND_SMOKE_PASS\n'

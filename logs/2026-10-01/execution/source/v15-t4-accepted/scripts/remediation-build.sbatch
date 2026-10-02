#!/bin/bash
#SBATCH --job-name=sc26_remediation_build
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --time=00:15:00
#SBATCH --chdir=/data/home/sunyc/solverchallenge26/execution-20261001
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err
set -e
export LC_ALL=C
module purge
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 cmake/3.24.2 miniforge3/24.3.0
set -uo pipefail
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
python3 tests/make_complex_system.py
python3 tests/make_field_systems.py
for problem in 02 03 04 05 06 07 08 09 10; do
    target=MPI_direct_solver
    case "$problem" in 02|05|07) target=MPI_iterative_solver ;; esac
    cmake -S src -B "build-t$problem" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc \
        -DSC26_PROBLEM="$problem" -DSC26_BUILD_MPI_GPU=OFF \
        -DCMAKE_PREFIX_PATH=/data/home/sunyc/solverchallenge26/deps/hypre \
        > "logs/configure-t$problem-$SLURM_JOB_ID.log" 2>&1
    cmake --build "build-t$problem" -j4 --target "$target" \
        > "logs/build-t$problem-$SLURM_JOB_ID.log" 2>&1
    sha256sum "build-t$problem/bin/$target" "build-t$problem/CMakeCache.txt"
done
export SC26_ROOT="$root" SC26_BUILD_DIR=build-t02
bash scripts/t2-small.sbatch
unset SC26_RTOL SC26_PROJECT_CONSTANT
export OMP_NUM_THREADS=4 MKL_NUM_THREADS=4
for problem in 03 04 06 08 09 10; do
    samples='poisson nonsymmetric scaled'; sys_type=0; metric=relative
    case "$problem" in
        06|08) samples=complex; sys_type=1 ;;
        10) samples='complex complex_unsorted'; sys_type=1 ;;
    esac
    if [ "$problem" = 08 ]; then metric=max; fi
    for sample in $samples; do
        rhs=$sample
        if [ "$sample" = complex_unsorted ]; then rhs=complex; fi
        run="$root/runs/small-$SLURM_JOB_ID/t$problem-$sample"
        mkdir -p "$run"; cd "$run"
        "$time_bin" -v -o process.time "$root/build-t$problem/bin/MPI_direct_solver" \
            "$root/tests/small_systems/${sample}_A.dat" "$root/tests/small_systems/${rhs}_b.dat" \
            0 "$sys_type" | tee solver.log
        python3 "$root/tests/check_result.py" solver.log 1e-10 answer_x.rhs \
            "$root/tests/small_systems/${rhs}_x.txt" --metric "$metric"
    done
done
export OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 SC26_RTOL=1e-12
for problem in 05 07; do
    for ranks in 1 4; do
        run="$root/runs/small-$SLURM_JOB_ID/t$problem-fields-$ranks"
        mkdir -p "$run"; cd "$run"
        mpirun -np "$ranks" "$root/build-t$problem/bin/MPI_iterative_solver" \
            "$root/tests/small_systems/fields${problem}_A.dat" \
            "$root/tests/small_systems/fields${problem}_b.dat" 0 0 | tee solver.log
        python3 "$root/tests/check_result.py" solver.log 1e-10 answer_x.rhs \
            "$root/tests/small_systems/fields${problem}_x.txt"
    done
done

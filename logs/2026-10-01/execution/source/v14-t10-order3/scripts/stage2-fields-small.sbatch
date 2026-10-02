#!/bin/bash
#SBATCH --job-name=sc26_fields_small
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --time=00:10:00
#SBATCH --chdir=/data/home/sunyc/solverchallenge26
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err
set -e
export LC_ALL=C
module purge
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 cmake/3.24.2 miniforge3/24.3.0
set -uo pipefail
export MKLROOT=/data/public/software/intel/oneapi/mkl/2022.0.0
export OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 SC26_RTOL=1e-12
root=/data/home/sunyc/solverchallenge26
python3 tests/make_field_systems.py
for problem in 05 07; do
    cmake -S src -B build-t$problem-mgr -DCMAKE_BUILD_TYPE=Release -DSC26_PROBLEM=$problem \
        -DSC26_FIELD_SPLIT=ON -DSC26_BUILD_MPI_GPU=OFF -DCMAKE_PREFIX_PATH="$root/deps/hypre"
    cmake --build build-t$problem-mgr -j4 --target MPI_iterative_solver
    for method in ilu mgr; do
        build="$root/build-t$problem"
        if [ "$method" = mgr ]; then build="$build-mgr"; fi
        for ranks in 1 4; do
            run_dir="$root/runs/fields-small-$SLURM_JOB_ID/t$problem-$method-$ranks"
            mkdir -p "$run_dir"; cd "$run_dir"
            mpirun -np "$ranks" "$build/bin/MPI_iterative_solver" \
                "$root/tests/small_systems/fields${problem}_A.dat" \
                "$root/tests/small_systems/fields${problem}_b.dat" 0 0 | tee solver.log
            python3 "$root/tests/check_result.py" solver.log 1e-10 answer_x.rhs \
                "$root/tests/small_systems/fields${problem}_x.txt"
        done
    done
    cd "$root"
done

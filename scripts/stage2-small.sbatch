#!/bin/bash
#SBATCH --job-name=sc26_stage2_small
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
export MKL_DYNAMIC=FALSE MKL_THREADING_LAYER=GNU
root=/data/home/sunyc/solverchallenge26
python3 tests/make_small_systems.py
python3 tests/make_complex_system.py
for problem in ${SC26_PROBLEMS:-05 07 08 10}; do
    target=MPI_iterative_solver
    if [ "$problem" = 08 ] || [ "$problem" = 10 ]; then target=MPI_direct_solver; fi
    cmake -S src -B build-t$problem -DCMAKE_BUILD_TYPE=Release -DSC26_PROBLEM=$problem \
        -DSC26_BUILD_MPI_GPU=OFF -DCMAKE_PREFIX_PATH="$root/deps/hypre"
    cmake --build build-t$problem -j4 --target "$target"
    export OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 SC26_RTOL=1e-12
    if [ "$target" = MPI_iterative_solver ]; then
        for sample in poisson nonsymmetric scaled; do
            for ranks in 1 4; do
                run_dir="$root/runs/stage2-small-$SLURM_JOB_ID/t$problem-$sample-$ranks"
                mkdir -p "$run_dir"; cd "$run_dir"
                mpirun -np "$ranks" "$root/build-t$problem/bin/$target" \
                    "$root/tests/small_systems/${sample}_A.dat" \
                    "$root/tests/small_systems/${sample}_b.dat" 0 0 | tee solver.log
                python3 "$root/tests/check_result.py" solver.log 1e-10 answer_x.rhs \
                    "$root/tests/small_systems/${sample}_x.txt"
            done
        done
    else
        export OMP_NUM_THREADS=4 MKL_NUM_THREADS=4
        samples=complex
        if [ "$problem" = 10 ]; then samples='complex complex_unsorted'; fi
        for sample in $samples; do
            run_dir="$root/runs/stage2-small-$SLURM_JOB_ID/t$problem-$sample"
            mkdir -p "$run_dir"; cd "$run_dir"
            "$root/build-t$problem/bin/$target" "$root/tests/small_systems/${sample}_A.dat" \
                "$root/tests/small_systems/complex_b.dat" 0 1 | tee solver.log
            metric=relative
            if [ "$problem" = 08 ]; then metric=max; fi
            python3 "$root/tests/check_result.py" solver.log 1e-10 answer_x.rhs \
                "$root/tests/small_systems/complex_x.txt" --metric "$metric"
        done
    fi
    cd "$root"
done

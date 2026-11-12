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
if [[ -z ${SLURM_JOB_ID:-} || -z ${SLURMD_NODENAME:-} || $(hostname -s) != "$SLURMD_NODENAME" ]]; then
    printf 'Submit with sbatch; execution requires the allocated compute node.\n' >&2
    exit 2
fi
export LC_ALL=C
module purge
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 cmake/3.24.2 miniforge3/24.3.0
set -uo pipefail
root=$PWD
deps=/data/home/sunyc/solverchallenge26/deps
time_bin=$deps/gnu-time/time
problems=("$@")
if (( $# == 0 )); then problems=(02 03 04 05 06 07 08 09 10); fi
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
for problem in "${problems[@]}"; do
    target=MPI_direct_solver
    case "$problem" in 02|05|07) target=MPI_iterative_solver ;; esac
    hypre_prefix=$deps/hypre
    if [[ $problem == 05 ]]; then
        hypre_prefix="$root/build-t05/hypre-mgr"
        mkdir -p "$hypre_prefix/lib64"
        ln -sfn "$deps/hypre/include" "$hypre_prefix/include"
        cp -R "$deps/hypre/lib64/cmake" "$hypre_prefix/lib64/"
        cp "$deps/hypre/lib64/libHYPRE.a" "$hypre_prefix/lib64/"
        patched_source="$hypre_prefix/par_mgr_setup.c"
        cp "$deps/hypre-2.33.0/src/parcsr_ls/par_mgr_setup.c" "$patched_source"
        patch "$patched_source" < scripts/hypre-2.33-mgr-repeat.patch
        flags="$deps/hypre-build/CMakeFiles/HYPRE.dir/flags.make"
        read -r -a includes <<< "$(sed -n 's/^C_INCLUDES = //p' "$flags")"
        read -r -a cflags <<< "$(sed -n 's/^C_FLAGS = //p' "$flags")"
        mpicc "${includes[@]}" "${cflags[@]}" -c "$patched_source" -o "$hypre_prefix/par_mgr_setup.c.o"
        ar r "$hypre_prefix/lib64/libHYPRE.a" "$hypre_prefix/par_mgr_setup.c.o"
        sha256sum "$patched_source" "$hypre_prefix/lib64/libHYPRE.a"
    fi
    cmake -S src -B "build-t$problem" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc \
        -DSC26_PROBLEM="$problem" -DSC26_BUILD_MPI_GPU=OFF \
        -DHYPRE_DIR="$hypre_prefix/lib64/cmake/HYPRE" \
        > "logs/configure-t$problem-$SLURM_JOB_ID.log" 2>&1
    cmake --build "build-t$problem" -j4 --target "$target" \
        > "logs/build-t$problem-$SLURM_JOB_ID.log" 2>&1
    sha256sum "build-t$problem/bin/$target" "build-t$problem/CMakeCache.txt"
done
if [[ " ${problems[*]} " == *" 02 "* ]]; then
    export SC26_ROOT="$root" SC26_BUILD_DIR=build-t02
    bash scripts/t2-small.sbatch
fi
unset SC26_RTOL SC26_PROJECT_CONSTANT
export OMP_NUM_THREADS=4 MKL_NUM_THREADS=4
for problem in "${problems[@]}"; do
    case "$problem" in 03|04|06|08|09|10) ;; *) continue ;; esac
    samples='poisson nonsymmetric scaled'; sys_type=0; metric=relative
    case "$problem" in
        06|08) samples=complex; sys_type=1 ;;
        10) samples='complex complex_unsorted complex_structural'; sys_type=1 ;;
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
            "$root/tests/small_systems/${rhs}_x.txt" --metric "$metric" --formal
    done
done
export OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 SC26_RTOL=1e-12
for problem in "${problems[@]}"; do
    case "$problem" in 05|07) ;; *) continue ;; esac
    for ranks in 1 4; do
        run="$root/runs/small-$SLURM_JOB_ID/t$problem-fields-$ranks"
        mkdir -p "$run"; cd "$run"
        mpirun -np "$ranks" "$root/build-t$problem/bin/MPI_iterative_solver" \
            "$root/tests/small_systems/fields${problem}_A.dat" \
            "$root/tests/small_systems/fields${problem}_b.dat" 0 0 | tee solver.log
        python3 "$root/tests/check_result.py" solver.log 1e-10 answer_x.rhs \
            "$root/tests/small_systems/fields${problem}_x.txt" --formal
    done
done

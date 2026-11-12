#!/bin/bash
#SBATCH --job-name=sc26_t2_quad_probe
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=96
#SBATCH --cpus-per-task=1
#SBATCH --mem=85G
#SBATCH --time=00:40:00
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err
set -eo pipefail
export LC_ALL=C
module purge
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 miniforge3/24.3.0
set -u
export OMP_NUM_THREADS=1 SC26_PROJECT_CONSTANT=0
root=$PWD
deps=/data/home/sunyc/solverchallenge26/deps
printf 'SC26_RUN problem=02 rhs=01 node=%s mpi=%s threads=1\n' "$SLURMD_NODENAME" "$SLURM_NTASKS"
sha256sum source-sha256.txt
sha256sum -c source-sha256.txt --quiet
mpicc -O3 -std=gnu99 -DMPI_USE -DITERATIVE_SOLVER -include stdlib.h -include string.h \
    -I include -I problem02 -I "$deps/hypre/include" \
    t2_quad.c problem02/solver.c src/{matrix_market/highlevel,matrix_market/mmio,mpi_system_loader,petsc_binary_reader,system_loader,diagnostics}.c \
    "$deps/hypre/lib64/libHYPRE.a" -lquadmath -lm -o t2_quad
sha256sum t2_quad "$deps/hypre/lib64/libHYPRE.a"
mkdir -p "runs/$SLURM_JOB_ID"
python3 tests/make_small_systems.py
mpirun -np 2 --bind-to core stdbuf -oL "$root/t2_quad" \
    "$root/tests/small_systems/nonsymmetric_A.dat" "$root/tests/small_systems/nonsymmetric_b.dat" 30 2 \
    > "runs/$SLURM_JOB_ID/smoke.log"
awk '/^Q-Check .* 2 \/ /{ok=($NF+0<1e-10)} END{exit !ok}' "runs/$SLURM_JOB_ID/smoke.log"
printf 'T2_SMOKE_PASS official_quad_checker=check_correctness_q_xq\n'
data=/data/home/maorz/SolverChallenge26-TenProblems/solverchallenge26_02
cd "runs/$SLURM_JOB_ID"
set +e
"$deps/gnu-time/time" -v -o process.time mpirun -np "$SLURM_NTASKS" --bind-to core \
    stdbuf -oL "$root/t2_quad" "$data/solverchallenge26_02_A.dat" "$data/solverchallenge26_02_b.dat" 72 3 | tee solver.log
rc=${PIPESTATUS[0]}
set -e
printf '%s\n' "$rc" > process.exit
exit "$rc"

#!/bin/bash
#SBATCH --job-name=sc26_stage2_inspect
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=00:20:00
#SBATCH --chdir=/data/home/sunyc/solverchallenge26
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err
set -e
export LC_ALL=C
module purge
module load miniforge3/24.3.0
set -uo pipefail
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1
mkdir -p runs/stage2-inspect-$SLURM_JOB_ID
for problem in 05 07 08 10; do
    /usr/bin/time -v -o runs/stage2-inspect-$SLURM_JOB_ID/t$problem.time \
        python3 scripts/inspect-stage2.py "$problem" \
        > runs/stage2-inspect-$SLURM_JOB_ID/t$problem.json
done

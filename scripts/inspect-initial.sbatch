#!/bin/bash
#SBATCH --job-name=sc26_inspect_initial
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --mem=12G
#SBATCH --time=00:05:00
#SBATCH --chdir=/data/home/sunyc/solverchallenge26
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err
set -e
export LC_ALL=C
module load miniforge3/24.3.0
set -uo pipefail
for problem in 01 03; do
    data=/data/home/maorz/SolverChallenge26-TenProblems/solverchallenge26_$problem
    python3 scripts/inspect-t2.py "$data/solverchallenge26_${problem}_A.dat" \
        "$data/solverchallenge26_${problem}_b.dat" > "logs/inspect-t$problem.json"
done

#!/bin/bash
#SBATCH --job-name=sc26_stage2_verify
#SBATCH --partition=qhn
#SBATCH --account=sunyc
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=00:05:00
#SBATCH --chdir=/data/home/sunyc/solverchallenge26
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err
set -e
export LC_ALL=C
module purge
module load gcc/11.3.0 openmpi/4.1.8/gcc11.3.0 cmake/3.24.2 miniforge3/24.3.0
set -uo pipefail
for build in build-t05 build-t07 build-t08 build-t10 build-t05-mgr build-t07-mgr; do
    ctest --test-dir "$build" --output-on-failure
done
python3 - <<'PY'
from pathlib import Path
import subprocess
import sys
log = 'runs/stage2-small-9193123/t08-complex/solver.log'
checker = [sys.executable, 'tests/check_result.py', log, '1e-14']
relative = subprocess.run(checker, capture_output=True, text=True)
maximum = subprocess.run(checker + ['--metric', 'max'], capture_output=True, text=True)
assert relative.returncode == 0, relative.stderr
assert maximum.returncode != 0 and '1.021671e-12' in maximum.stderr, maximum.stderr
print('T8_METRIC_CHECK_PASS: relative=8.874297e-17 passes 1e-14; max=1.021671e-12 fails 1e-14')
PY

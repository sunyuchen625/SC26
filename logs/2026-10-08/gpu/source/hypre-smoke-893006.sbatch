#!/bin/bash
#SBATCH --job-name=sc26_hypre_hip_smoke
#SBATCH --partition=hx1hdnormal
#SBATCH --nodes=1
#SBATCH --nodelist=f11r2n10
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --gres=dcu:Hygon:1
#SBATCH --time=00:05:00
#SBATCH --output=sc26_hypre_hip_smoke-%j.out
#SBATCH --error=sc26_hypre_hip_smoke-%j.err
set -e
if [[ -z ${SLURM_JOB_ID:-} || -z ${SLURMD_NODENAME:-} || $(hostname -s) != "$SLURMD_NODENAME" ]]; then
    printf 'Submit with sbatch; execution requires the allocated compute node.\n' >&2
    exit 2
fi
export LC_ALL=C
module load compiler/gcc/12.2.0 compiler/cmake/3.24.1 compiler/dtk/25.04.2
module load mpi/openmpi/4.1.8/gcc-12.2.0/shca
set -uo pipefail
mpi_prefix=/public/software/mpi/openmpi/openmpi-4.1.8
export OMPI_MCA_mca_base_component_path="$mpi_prefix/lib/openmpi:/public/software/mpi/pmix/4.2.9/lib/pmix"
export OMPI_MCA_ess_singleton_isolated=1
export OMP_NUM_THREADS=1
work="$HOME/sc26-hip-20261007"
build_dir="$work/build-892588"
run_dir="$work/smoke-$SLURM_JOB_ID"
mkdir -p "$run_dir"
cd "$run_dir"
cp "$0" submitted.sbatch
sha256sum submitted.sbatch
printf 'JOB_ID=%s NODE=%s ORIGIN_BUILD_JOB=892588\n' "$SLURM_JOB_ID" "$(hostname -s)"
scontrol show job "$SLURM_JOB_ID"
module list
printf '%s  %s\n' '6bb5dd78bb2e70fe64be4c6977ce206464423d05227e1c22747d4b76dffce5b9' \
    "$build_dir/test/ij" | sha256sum -c -
"$mpi_prefix/bin/ompi_info" --parsable --param ess singleton --level 9 >ompi-singleton.txt
grep -F 'ess_singleton_isolated:value' ompi-singleton.txt
solver_exit=0
"$build_dir/test/ij" -n 8 8 8 -P 1 1 1 -solver 1 \
    -memory_device -exec_device -rlx 18 -rlx_coarse 18 -tol 1e-8 \
    >ij-smoke.out 2>ij-smoke.err || solver_exit=$?
cat ij-smoke.err
printf 'SOLVER_EXIT_CODE=%s\n' "$solver_exit"
test "$solver_exit" -eq 0
grep -E '^Iterations =|^Final Relative Residual Norm =' ij-smoke.out
test ! -s ij-smoke.err
awk '/^Final Relative Residual Norm =/ {
    passed = ($6 ~ /^[0-9]+[.][0-9]+[eE][+-][0-9]+$/ && $6 < 1e-8)
} END { exit !passed }' ij-smoke.out
printf 'HYPRE_HIP_SMOKE_JOB_COMPLETE\n'

#!/bin/bash
#SBATCH --job-name=sc26_mpi_probe
#SBATCH --partition=hx1hdnormal
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --gres=dcu:Hygon:1
#SBATCH --time=00:05:00
#SBATCH --output=sc26_mpi_probe-%j.out
#SBATCH --error=sc26_mpi_probe-%j.err
set -e
if [[ -z ${SLURM_JOB_ID:-} || -z ${SLURMD_NODENAME:-} || $(hostname -s) != "$SLURMD_NODENAME" ]]; then
    printf 'Submit with sbatch; execution requires the allocated compute node.\n' >&2
    exit 2
fi
export LC_ALL=C
module load compiler/gcc/12.2.0 compiler/dtk/25.04.2
module load mpi/openmpi/4.1.8/gcc-12.2.0/shca
set -uo pipefail
printf 'JOB_ID=%s NODELIST=%s\n' "$SLURM_JOB_ID" "$SLURM_JOB_NODELIST"
scontrol show job "$SLURM_JOB_ID"
module list
cd "$HOME/sc26-hip-probe-887201"
printf '%s\n' '90933f5a2b79d54f6447f967470110fbe8fc40411fa17eb381fb361915b4d61c  mpi-probe' | sha256sum -c -
mpi_launcher=/public/software/mpi/openmpi/openmpi-4.1.8/bin/mpirun
"$mpi_launcher" -np 1 sh -c '
    actual_host=$(hostname -s)
    printf "MPI_EXEC_HOST=%s\n" "$actual_host"
    test "$actual_host" = "$1" || exit 2
    exec "$2"
' _ "$SLURMD_NODENAME" "$PWD/mpi-probe"
printf 'SC26_MPI_PROBE_COMPLETE\n'

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
export LC_ALL=C
module load compiler/gcc/12.2.0 compiler/dtk/25.04.2
module load mpi/openmpi/4.1.8/gcc-12.2.0/shca
set -uo pipefail
printf 'JOB_ID=%s NODELIST=%s\n' "$SLURM_JOB_ID" "$SLURM_JOB_NODELIST"
scontrol show job "$SLURM_JOB_ID"
module list
type -a mpirun mpicc
readlink -f "$(command -v mpirun)"
mpicc --showme
cd "$HOME/sc26-hip-probe-887201"
printf '%s\n' '90933f5a2b79d54f6447f967470110fbe8fc40411fa17eb381fb361915b4d61c  mpi-probe' | sha256sum -c -
ldd ./mpi-probe
mpi_launcher=/public/software/mpi/openmpi/openmpi-4.1.8/bin/mpirun
ls -l "$mpi_launcher"
"$mpi_launcher" --version
"$mpi_launcher" -np 1 ./mpi-probe
printf 'SC26_MPI_PROBE_COMPLETE\n'

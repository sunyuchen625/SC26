#!/bin/bash
#SBATCH --job-name=sc26_mpi_components
#SBATCH --partition=hx1hdnormal
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --gres=dcu:Hygon:1
#SBATCH --time=00:05:00
#SBATCH --output=sc26_mpi_components-%j.out
#SBATCH --error=sc26_mpi_components-%j.err
set -e
if [[ -z ${SLURM_JOB_ID:-} || -z ${SLURMD_NODENAME:-} || $(hostname -s) != "$SLURMD_NODENAME" ]]; then
    printf 'Submit with sbatch; execution requires the allocated compute node.\n' >&2
    exit 2
fi
export LC_ALL=C
module load compiler/gcc/12.2.0 compiler/dtk/25.04.2
module load mpi/openmpi/4.1.8/gcc-12.2.0/shca
set -uo pipefail
mpi_prefix=/public/software/mpi/openmpi/openmpi-4.1.8
printf 'JOB_ID=%s NODE=%s\n' "$SLURM_JOB_ID" "$(hostname -s)"
scontrol show job "$SLURM_JOB_ID"
module list
for setting in OPAL_PREFIX OPAL_LIBDIR OPAL_PKGLIBDIR OMPI_MCA_shmem OMPI_MCA_mca_base_component_path LD_LIBRARY_PATH LD_PRELOAD; do
    printf '%s=%s\n' "$setting" "${!setting-}"
done
set +e
ls -ld "$mpi_prefix/lib" "$mpi_prefix/lib/openmpi" /dev/shm /tmp
printf 'DIRECTORY_QUERY_EXIT=%s\n' "$?"
df -h /dev/shm /tmp
printf 'FILESYSTEM_QUERY_EXIT=%s\n' "$?"
find "$mpi_prefix/lib" -maxdepth 2 -name 'mca_shmem*' -print
printf 'COMPONENT_LIST_EXIT=%s\n' "$?"
for component in "$mpi_prefix"/lib/openmpi/mca_shmem*.so; do
    if [[ -f "$component" ]]; then
        printf 'SHMEM_COMPONENT=%s\n' "$component"
        ldd "$component"
        printf 'COMPONENT_LDD_EXIT=%s\n' "$?"
    fi
done
for configuration in "$mpi_prefix/etc/openmpi-mca-params.conf" "$HOME/.openmpi/mca-params.conf"; do
    if [[ -f "$configuration" ]]; then
        printf 'MPI_CONFIG=%s\n' "$configuration"
        awk '/^[[:space:]]*(shmem|mca_base_component_path|mca_component_path)[[:alnum:]_]*[[:space:]]*=/' "$configuration"
    fi
done
set -e
cd "$HOME/sc26-hip-probe-887201"
printf '%s\n' '90933f5a2b79d54f6447f967470110fbe8fc40411fa17eb381fb361915b4d61c  mpi-probe' | sha256sum -c -
printf 'MPI_PREFIX_TEST=%s MPI_EXEC_HOST=%s\n' "$mpi_prefix" "$(hostname -s)"
set +e
OPAL_PREFIX="$mpi_prefix" OMPI_MCA_mca_base_component_show_load_errors=1 OMPI_MCA_shmem_base_verbose=10 ./mpi-probe
mpi_status=$?
set -e
printf 'MPI_PREFIX_TEST_EXIT=%s\n' "$mpi_status"
exit "$mpi_status"

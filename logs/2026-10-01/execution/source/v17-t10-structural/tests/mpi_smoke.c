#include <mpi.h>
#include <stdio.h>

int main(int argc, char **argv)
{
    int rank, size, sum, name_length;
    char host[MPI_MAX_PROCESSOR_NAME];
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Get_processor_name(host, &name_length);
    int value = rank + 1;
    MPI_Allreduce(&value, &sum, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD);
    printf("rank=%d size=%d host=%s sum=%d\n", rank, size, host, sum);
    int passed = size == 2 && sum == 3;
    if (rank == 0)
        printf("MPI_SMOKE_%s\n", passed ? "PASS" : "FAIL");
    MPI_Finalize();
    return passed ? 0 : 1;
}

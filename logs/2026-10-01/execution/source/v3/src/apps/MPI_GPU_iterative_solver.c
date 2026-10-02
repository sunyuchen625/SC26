/* MPI GPU iterative-solver harness. The selected problem supplies the adapter. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mpi.h"

#include "solverchallenge26/diagnostics.h"
#include "solverchallenge26/gpu_iterative_solver_api.h"
#include "solverchallenge26/mpi_system_loader.h"

static int parse_args(int argc, char **argv, int rank, char **matrix,
                      char **rhs, int *read_base, int *sys_type)
{
    if (argc < 3 || argc > 5) {
        if (rank == 0) print_help();
        return -1;
    }

    *matrix = argv[1];
    *rhs = argv[2];
    if (argc >= 4) {
        *read_base = atoi(argv[3]);
        if (*read_base != 0 && *read_base != 1) {
            if (rank == 0) fprintf(stderr, "read_base must be 0 or 1\n");
            return -1;
        }
    }
    if (argc == 5) {
        *sys_type = atoi(argv[4]);
        if (*sys_type != 0 && *sys_type != 1) {
            if (rank == 0) fprintf(stderr, "sys_type must be 0 or 1\n");
            return -1;
        }
    } else if (detect_sys_type_from_matrix(*matrix, sys_type) != 0) {
        if (rank == 0)
            fprintf(stderr, "Failed to detect system type from %s\n", *matrix);
        return -1;
    }
    return 0;
}

static void free_global_solution(int **counts, int **displs, double **x,
                                  double **x_im)
{
    free(*counts);
    free(*displs);
    free(*x);
    free(*x_im);
    *counts = NULL;
    *displs = NULL;
    *x = NULL;
    *x_im = NULL;
}

int main(int argc, char **argv)
{
    int rank, size;
    int read_base = 1, sys_type = 0;
    char *matrix = NULL, *rhs = NULL;
    struct MPI_LocalSystem local;
    struct SC26_SolverInput input;
    int *counts = NULL, *displs = NULL;
    double *x_global = NULL, *x_global_im = NULL;
    int status = 0;

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (parse_args(argc, argv, rank, &matrix, &rhs, &read_base, &sys_type) !=
        0) {
        MPI_Finalize();
        return EXIT_FAILURE;
    }

    mpi_local_system_init(&local);
    if (mpi_load_local_linear_system(matrix, rhs, read_base, sys_type,
                                     MPI_COMM_WORLD, &local) != 0) {
        MPI_Finalize();
        return EXIT_FAILURE;
    }

    input.global_n = local.global_cols;
    input.local_n = local.row_end - local.row_begin;
    input.row_begin = local.row_begin;
    input.row_ptr = local.row_ptr;
    input.col_idx = local.col_idx;
    input.val = local.val;
    input.val_im = local.val_im;
    input.x = input.local_n ? calloc((size_t)input.local_n, sizeof(*input.x))
                            : NULL;
    input.x_im = sys_type && input.local_n
                     ? calloc((size_t)input.local_n, sizeof(*input.x_im))
                     : NULL;
    input.b = local.b;
    input.b_im = local.b_im;
    input.comm = MPI_COMM_WORLD;

    status = (input.local_n && !input.x) ||
             (sys_type && input.local_n && !input.x_im);
    {
        int global_status = 0;
        MPI_Allreduce(&status, &global_status, 1, MPI_INT, MPI_MAX,
                      MPI_COMM_WORLD);
        status = global_status;
    }
    if (status) {
        free(input.x);
        free(input.x_im);
        mpi_local_system_free(&local);
        MPI_Finalize();
        return EXIT_FAILURE;
    }

    if (rank == 0) {
        fprintf(stdout,
                "matrix name :      %s\nvectorb name :     %s\nread function :    %s\nsys_type :         %d\n",
                matrix, rhs,
                file_is_petsc_matrix(matrix)
                    ? "PETSc binary (0-base)"
                    : (read_base ? "MTX base-1" : "MTX base-0"),
                sys_type);
    }

    /* Input loading is one-time. Host-to-device transfer is measured
       separately; end-to-end time excludes that transfer. */
    const int test_frequency = 5;
    double local_total_ms = 0.0;
    double local_upload_ms = 0.0;
    double local_download_ms = 0.0;
    unsigned long long local_gpu_tracked_peak = 0;
    unsigned long long local_gpu_observed_peak = 0;
    for (int trial = 0; trial < test_frequency; ++trial) {
        struct SC26_GpuIterativeSolver *solver = NULL;
        struct SC26_GpuMemoryMetrics memory_metrics = {0, 0};
        double start, upload_start, upload_stop, solve_start, solve_stop;
        double copy_start, copy_stop, stop;
        if (input.local_n)
            memset(input.x, 0,
                   sizeof(*input.x) * (size_t)input.local_n);
        if (input.x_im && input.local_n)
            memset(input.x_im, 0,
                   sizeof(*input.x_im) * (size_t)input.local_n);

        MPI_Barrier(MPI_COMM_WORLD);
        start = MPI_Wtime();
        status = sc26_gpu_iterative_solver_create(&input, &solver);
        {
            int global_status = 0;
            MPI_Allreduce(&status, &global_status, 1, MPI_INT, MPI_MAX,
                          MPI_COMM_WORLD);
            status = global_status;
        }
        upload_start = MPI_Wtime();
        if (!status) status = sc26_gpu_iterative_solver_upload(solver);
        upload_stop = MPI_Wtime();
        local_upload_ms += (upload_stop - upload_start) * 1000.0;
        {
            int global_status = 0;
            MPI_Allreduce(&status, &global_status, 1, MPI_INT, MPI_MAX,
                          MPI_COMM_WORLD);
            status = global_status;
        }
        MPI_Barrier(MPI_COMM_WORLD);
        solve_start = MPI_Wtime();
        if (!status) status = sc26_gpu_iterative_solver_solve(solver);
        {
            int global_status = 0;
            MPI_Allreduce(&status, &global_status, 1, MPI_INT, MPI_MAX,
                          MPI_COMM_WORLD);
            status = global_status;
        }
        solve_stop = MPI_Wtime();
        copy_start = MPI_Wtime();
        if (!status) status = sc26_gpu_iterative_solver_copy_solution(solver);
        copy_stop = MPI_Wtime();
        local_download_ms += (copy_stop - copy_start) * 1000.0;
        {
            int global_status = 0;
            MPI_Allreduce(&status, &global_status, 1, MPI_INT, MPI_MAX,
                          MPI_COMM_WORLD);
            status = global_status;
        }
        if (!status) {
            status = sc26_gpu_iterative_solver_get_memory_metrics(
                solver, &memory_metrics);
        }
        {
            int global_status = 0;
            MPI_Allreduce(&status, &global_status, 1, MPI_INT, MPI_MAX,
                          MPI_COMM_WORLD);
            status = global_status;
        }
        if ((unsigned long long)memory_metrics.tracked_peak_bytes >
            local_gpu_tracked_peak)
            local_gpu_tracked_peak =
                (unsigned long long)memory_metrics.tracked_peak_bytes;
        if ((unsigned long long)memory_metrics.observed_peak_bytes >
            local_gpu_observed_peak)
            local_gpu_observed_peak =
                (unsigned long long)memory_metrics.observed_peak_bytes;
        if (solver) sc26_gpu_iterative_solver_destroy(solver);
        stop = MPI_Wtime();
        MPI_Barrier(MPI_COMM_WORLD);
        local_total_ms += ((upload_start - start) +
                           (solve_stop - solve_start) +
                           (stop - copy_stop)) * 1000.0;

        int global_status = 0;
        MPI_Allreduce(&status, &global_status, 1, MPI_INT, MPI_MAX,
                      MPI_COMM_WORLD);
        if (global_status) {
            status = global_status;
            break;
        }
    }
    {
        double local_ms = local_total_ms / (double)test_frequency;
        double local_upload = local_upload_ms / (double)test_frequency;
        double local_download = local_download_ms / (double)test_frequency;
        double global_ms = 0.0;
        double global_upload = 0.0;
        double global_download = 0.0;
        unsigned long long global_gpu_tracked_peak = 0;
        unsigned long long global_gpu_observed_peak = 0;
        MPI_Reduce(&local_ms, &global_ms, 1, MPI_DOUBLE, MPI_MAX, 0,
                   MPI_COMM_WORLD);
        MPI_Reduce(&local_upload, &global_upload, 1, MPI_DOUBLE, MPI_MAX, 0,
                   MPI_COMM_WORLD);
        MPI_Reduce(&local_download, &global_download, 1, MPI_DOUBLE, MPI_MAX,
                   0, MPI_COMM_WORLD);
        MPI_Reduce(&local_gpu_tracked_peak, &global_gpu_tracked_peak, 1,
                   MPI_UNSIGNED_LONG_LONG, MPI_MAX, 0, MPI_COMM_WORLD);
        MPI_Reduce(&local_gpu_observed_peak, &global_gpu_observed_peak, 1,
                   MPI_UNSIGNED_LONG_LONG, MPI_MAX, 0, MPI_COMM_WORLD);
        if (rank == 0) {
            printf("------------------------------------------\n");
            printf("GPU memory usage:                   %12.4f MB\n",
                   (double)global_gpu_tracked_peak / (1024.0 * 1024.0));
            printf("GPU observed memory delta:         %12.4f MB\n",
                   (double)global_gpu_observed_peak / (1024.0 * 1024.0));
            printf("CHECK MPI GPU CPU-to-GPU transfer time : %12.6lf ms\n",
                   global_upload);
            printf("CHECK MPI GPU GPU-to-CPU transfer time : %12.6lf ms\n",
                   global_download);
            printf("CHECK MPI GPU iterative end to end time : %12.6lf ms\n", global_ms);
        }
    }

    if (status) {
        if (rank == 0) fprintf(stderr, "MPI GPU solve failed\n");
        free(input.x);
        free(input.x_im);
        mpi_local_system_free(&local);
        MPI_Finalize();
        return EXIT_FAILURE;
    }

    mem_usage();
    counts = malloc(sizeof(*counts) * (size_t)size);
    displs = malloc(sizeof(*displs) * (size_t)size);
    status = (!counts || !displs) ? 1 : 0;
    {
        int global_status = 0;
        MPI_Allreduce(&status, &global_status, 1, MPI_INT, MPI_MAX,
                      MPI_COMM_WORLD);
        status = global_status;
    }
    if (!status) mpi_row_counts(input.global_n, size, counts, displs);
    if (rank == 0 && !status) {
        x_global = malloc(sizeof(*x_global) * (size_t)input.global_n);
        if (sys_type)
            x_global_im = malloc(sizeof(*x_global_im) * (size_t)input.global_n);
        status = !x_global || (sys_type && !x_global_im);
    }
    MPI_Bcast(&status, 1, MPI_INT, 0, MPI_COMM_WORLD);
    if (!status) {
        MPI_Gatherv(input.x, input.local_n, MPI_DOUBLE, x_global, counts,
                    displs, MPI_DOUBLE, 0, MPI_COMM_WORLD);
        if (sys_type)
            MPI_Gatherv(input.x_im, input.local_n, MPI_DOUBLE, x_global_im,
                        counts, displs, MPI_DOUBLE, 0, MPI_COMM_WORLD);
    }

    free(input.x);
    free(input.x_im);
    mpi_local_system_free(&local);

    int reload_status = 0;
    if (rank == 0 && !status) {
        int m, n, nnz, symmetric;
        int *row_ptr = NULL, *col_idx = NULL;
        double *val = NULL, *val_im = NULL, *b = NULL, *b_im = NULL;
        reload_status = load_linear_system(
            matrix, rhs, read_base, sys_type, &m, &n, &nnz, &symmetric,
            &row_ptr, &col_idx, &val, &val_im, &b, &b_im);
        if (reload_status == 0 && m != n) reload_status = 1;
        if (reload_status != 0) {
            fprintf(stderr, "Final full-system reload failed\n");
        } else if (sys_type == 0) {
            store_x(n, x_global, "answer_x.rhs");
            check_correctness(n, row_ptr, col_idx, val, x_global, b);
            check_correctness_ld_d2ld(n, row_ptr, col_idx, val, x_global, b);
#ifndef SC26_DISABLE_FLOAT128
            check_correctness_q_d2q(n, row_ptr, col_idx, val, x_global, b);
#endif
        } else {
            store_x_complex(n, x_global, x_global_im, "answer_x.rhs");
            check_correctness_complex(n, row_ptr, col_idx, val, val_im,
                                      x_global, x_global_im, b, b_im);
            check_correctness_complex_ld_d2ld(
                n, row_ptr, col_idx, val, val_im, x_global, x_global_im, b,
                b_im);
#ifndef SC26_DISABLE_FLOAT128
            check_correctness_complex_q_d2q(
                n, row_ptr, col_idx, val, val_im, x_global, x_global_im, b,
                b_im);
#endif
        }
        free(row_ptr);
        free(col_idx);
        free(val);
        free(val_im);
        free(b);
        free(b_im);
    }
    MPI_Bcast(&reload_status, 1, MPI_INT, 0, MPI_COMM_WORLD);
    if (reload_status != 0) status = reload_status;

    free_global_solution(&counts, &displs, &x_global, &x_global_im);
    MPI_Finalize();
    return status ? EXIT_FAILURE : EXIT_SUCCESS;
}

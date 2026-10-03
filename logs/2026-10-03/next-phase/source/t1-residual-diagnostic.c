#include "solver.c"
#include "solverchallenge26/diagnostics.h"
#include "solverchallenge26/mpi_system_loader.h"
#include <limits.h>

int main(int argc, char **argv)
{
    if (argc != 3) return 2;
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    struct MPI_LocalSystem system;
    mpi_local_system_init(&system);
    if (mpi_load_local_linear_system(argv[1], argv[2], 0, 0,
            MPI_COMM_WORLD, &system)) MPI_Abort(MPI_COMM_WORLD, 1);
    int n = system.global_cols, local_n = system.row_end - system.row_begin;
    double *x = calloc((size_t)local_n, sizeof(*x));
    double *global_x = malloc((size_t)n * sizeof(*global_x));
    int *counts = malloc((size_t)size * sizeof(*counts));
    int *offsets = malloc((size_t)size * sizeof(*offsets));
    if (!x || !global_x || !counts || !offsets) MPI_Abort(MPI_COMM_WORLD, 1);
    struct SC26_SolverInput input = {
        .global_n = n, .local_n = local_n, .row_begin = system.row_begin,
        .row_ptr = system.row_ptr, .col_idx = system.col_idx, .val = system.val,
        .b = system.b, .x = x, .comm = MPI_COMM_WORLD
    };
    struct MySolver solver;
    analyse(&solver, &input);
    preprocess(&solver, &input);
    iterative_solver(&solver, &input);
    mpi_row_counts(n, size, counts, offsets);
    MPI_Allgatherv(x, local_n, MPI_DOUBLE, global_x, counts, offsets,
                   MPI_DOUBLE, MPI_COMM_WORLD);
    free(x); free(counts); free(offsets);

    int local_min = INT_MAX, local_max = INT_MIN, min_exponent, max_exponent;
    for (int i = 0; i < local_n; ++i) {
        double maximum = 0;
        for (int k = input.row_ptr[i]; k < input.row_ptr[i+1]; ++k)
            maximum = fmax(maximum, fabs(input.val[k]));
        int exponent = (int)floor(log10(maximum));
        if (exponent < local_min) local_min = exponent;
        if (exponent > local_max) local_max = exponent;
    }
    MPI_Allreduce(&local_min, &min_exponent, 1, MPI_INT, MPI_MIN, MPI_COMM_WORLD);
    MPI_Allreduce(&local_max, &max_exponent, 1, MPI_INT, MPI_MAX, MPI_COMM_WORLD);
    int bins = max_exponent - min_exponent + 1, groups = 3*bins;
    long double *local = calloc((size_t)groups*4, sizeof(*local));
    long double *global = calloc((size_t)groups*4, sizeof(*global));
    long long *local_counts = calloc((size_t)groups, sizeof(*local_counts));
    long long *global_counts = calloc((size_t)groups, sizeof(*global_counts));
    if (!local || !global || !local_counts || !global_counts)
        MPI_Abort(MPI_COMM_WORLD, 1);
    for (int i = 0; i < local_n; ++i) {
        double maximum = 0;
        __float128 ax = 0;
        for (int k = input.row_ptr[i]; k < input.row_ptr[i+1]; ++k) {
            maximum = fmax(maximum, fabs(input.val[k]));
            ax += (__float128)input.val[k]*global_x[input.col_idx[k]];
        }
        long double r = (long double)((__float128)input.b[i] - ax);
        double d = 1/sqrt(maximum);
        long double dr = r*d, b = input.b[i], db = b*d;
        int block = (int)((long long)(input.row_begin+i)*3/n);
        int bin = (int)floor(log10(maximum)) - min_exponent;
        int group = block*bins+bin;
        ++local_counts[group];
        local[4*group] += r*r;
        local[4*group+1] += dr*dr;
        local[4*group+2] += b*b;
        local[4*group+3] += db*db;
    }
    MPI_Reduce(local, global, groups*4, MPI_LONG_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
    MPI_Reduce(local_counts, global_counts, groups, MPI_LONG_LONG, MPI_SUM, 0, MPI_COMM_WORLD);
    if (rank == 0) {
        long double totals[4] = {0};
        for (int g = 0; g < groups; ++g)
            for (int j = 0; j < 4; ++j) totals[j] += global[4*g+j];
        printf("T1_DIAGNOSTIC solves=1 matvec=float128 statistic_reduce=long_double temperature_blocks=3 contiguous=1\n");
        printf("T1_RESIDUAL_TOTAL rows=%d r_norm=%.18Le Dr_norm=%.18Le b_norm=%.18Le Db_norm=%.18Le original_relative=%.18Le scaled_relative=%.18Le\n",
            n, sqrtl(totals[0]), sqrtl(totals[1]), sqrtl(totals[2]), sqrtl(totals[3]),
            sqrtl(totals[0]/totals[2]), sqrtl(totals[1]/totals[3]));
        for (int g = 0; g < groups; ++g) {
            if (global_counts[g] == 0) continue;
            printf("T1_RESIDUAL_BIN block=%d rowmax_decade=%d rows=%lld r_sq=%.18Le Dr_sq=%.18Le b_sq=%.18Le Db_sq=%.18Le\n",
                g/bins+1, g%bins+min_exponent, global_counts[g],
                global[4*g], global[4*g+1], global[4*g+2], global[4*g+3]);
        }
    }
    free(local); free(global); free(local_counts); free(global_counts);
    mpi_local_system_free(&system);

    int m, nnz, symmetric, reload_status = 0;
    int *row_ptr = NULL, *col_idx = NULL;
    double *values = NULL, *imaginary_values = NULL, *rhs = NULL, *imaginary_rhs = NULL;
    if (rank == 0)
        reload_status = load_linear_system(argv[1], argv[2], 0, 0, &m, &n, &nnz, &symmetric,
            &row_ptr, &col_idx, &values, &imaginary_values, &rhs, &imaginary_rhs);
    MPI_Bcast(&reload_status, 1, MPI_INT, 0, MPI_COMM_WORLD);
    if (reload_status) MPI_Abort(MPI_COMM_WORLD, 1);
    if (rank == 0) {
        check_correctness_q_d2q(n, row_ptr, col_idx, values, global_x, rhs);
        free(row_ptr); free(col_idx); free(values); free(rhs);
        free(imaginary_values); free(imaginary_rhs);
    }
    MPI_Barrier(MPI_COMM_WORLD);
    mem_usage();
    free(global_x);
    MPI_Finalize();
    return 0;
}

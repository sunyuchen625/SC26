/*
 * This is the reference MPI iterative method solver code of SolverChallenge26
 */

// system file
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/time.h>

#include "mpi.h"

#include "solverchallenge26/diagnostics.h"
#include "solverchallenge26/mpi_system_loader.h"
#include "solverchallenge26/solver_api.h"

int main(int argc, char** argv)
{

    int     m, n, nnzA, isSymmetricA;
    int*    row_ptr = NULL;         // the csr row pointer array of matrix A
    int*    col_idx = NULL;         // the csr column index array of matrix A
    double* val     = NULL;         // the csr value array of matrix A (real number)
    double* val_im  = NULL;         // the csr value array of matrix A (imaginary number)
    double *x = NULL, *x_im = NULL; // solution vector x, (x: real number, x_im: imaginary number)
    double *b = NULL, *b_im = NULL; // right-hand side vector b, (b: real number, b_im: imaginary number)
    double  tt, time;
    int local_n, row_begin;
    struct MPI_LocalSystem local_system;
    int *gather_counts = NULL, *gather_displs = NULL;
    double *x_global = NULL, *x_global_im = NULL;

    char* filename_matrix;       // the filename of matrix A
    char* filename_b;            // the filename of right-hand side vector b
    int   read_matrix_base = 1;  // 0-base or 1-base, default 1-base
    enum { warmup_frequency = 5, test_frequency = 5, rounds = warmup_frequency + test_frequency };
    int   sys_type         = 0;  // type of algebraic systems, 0: real, 1: complex; default 0

    int myrank, size;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &myrank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    /* ========================================== */
    // Step 0: Read command line argument
    /* ========================================== */
    if (argc < 3 || argc > 5) {
        if (myrank == 0) print_help();
        MPI_Finalize();
        return -1;
    }
    filename_matrix = argv[1];
    filename_b = argv[2];
    if (argc >= 4) {
        filename_matrix  = argv[1];
        filename_b       = argv[2];
        read_matrix_base = atoi(argv[3]);

        if (!((read_matrix_base == 0) || (read_matrix_base == 1))) {
            if (myrank == 0) {
                fprintf(stdout, "read_base error input %d\n", read_matrix_base);
                print_help();
            }
            MPI_Finalize();
            return -1;
        }
    }
    if (argc == 5) {
        sys_type = atoi(argv[4]);
        if (sys_type > 1 || sys_type < 0) {
            if (myrank == 0) {
                fprintf(stdout, "sys_type error input %d\n", sys_type);
                print_help();
            }
            MPI_Finalize();
            return -1;
        }
    }

    //! If the user does not specify parameter sys_type,
    //! it will automatically determine whether it is a real system or a complex system
    if (argc < 5) {
        if (detect_sys_type_from_matrix(filename_matrix, &sys_type) != 0) {
            if (myrank == 0) fprintf(stdout, "Failed to detect system type from %s\n", filename_matrix);
            MPI_Finalize();
            return -1;
        }
    }

    if (myrank == 0)
        fprintf(stdout, "matrix name :      %s\nvectorb name :     %s\nread function :    %s\nsys_type :         %d\n",
                filename_matrix, filename_b, file_is_petsc_matrix(filename_matrix) ? "PETSc binary (0-base)" : (read_matrix_base ? "MTX base-1" : "MTX base-0"),
                sys_type);

    /* ========================================== */
    // Step 1: Load matrix and rhs (PETSc binary by default)
    /* ========================================== */
    if (mpi_load_local_linear_system(filename_matrix, filename_b, read_matrix_base, sys_type,
                                     MPI_COMM_WORLD, &local_system) != 0) {
        MPI_Finalize();
        return -1;
    }
    m = local_system.global_rows;
    n = local_system.global_cols;
    nnzA = local_system.global_nnz;
    row_begin = local_system.row_begin;
    local_n = local_system.row_end - local_system.row_begin;
    row_ptr = local_system.row_ptr;
    col_idx = local_system.col_idx;
    val = local_system.val;
    val_im = local_system.val_im;
    b = local_system.b;
    b_im = local_system.b_im;
    x = local_n ? (double*)calloc((size_t)local_n, sizeof(double)) : NULL;
    int allocation_status = local_n && !x ? -1 : 0;
    if (sys_type) {
        x_im = local_n ? (double*)calloc((size_t)local_n, sizeof(double)) : NULL;
        if (local_n && !x_im) allocation_status = -1;
    }
    int global_allocation_status = 0;
    MPI_Allreduce(&allocation_status, &global_allocation_status, 1, MPI_INT, MPI_MIN, MPI_COMM_WORLD);
    if (global_allocation_status) {
        free(x);
        free(x_im);
        mpi_local_system_free(&local_system);
        MPI_Finalize();
        return -1;
    }

    struct SC26_SolverInput solver_input = {
        .global_n = n,
        .local_n = local_n,
        .row_begin = row_begin,
        .row_ptr = row_ptr,
        .col_idx = col_idx,
        .val = val,
        .val_im = val_im,
        .x = x,
        .x_im = x_im,
        .b = b,
        .b_im = b_im,
        .comm = MPI_COMM_WORLD
    };

    /* ========================================== */
    // Step 2: Solve the linear system
    /* ========================================== */
    double round_seconds[rounds];
    if (sys_type == 0) {
        struct MySolver mysolver;
        SC26_SOLVER_CREATE(&mysolver, &solver_input);
        for (int i = 0; i < rounds; ++i) {
            if (i == warmup_frequency) {
                MPI_Barrier(MPI_COMM_WORLD);
                tt = MPI_Wtime();
            }
            double round_started = MPI_Wtime();
            if (local_n) {
                memset(x, 0, sizeof(*x) * (size_t)local_n);
            }
            analyse(&mysolver, &solver_input);
            preprocess(&mysolver, &solver_input);
            iterative_solver(&mysolver, &solver_input);
            round_seconds[i] = (MPI_Wtime() - round_started);
        }
        time = (MPI_Wtime() - tt);
        SC26_SOLVER_DESTROY(&mysolver, &solver_input);
    } else {
        struct MySolver_complex mysolver;
        SC26_SOLVER_CREATE_COMPLEX(&mysolver, &solver_input);
        for (int i = 0; i < rounds; ++i) {
            if (i == warmup_frequency) {
                MPI_Barrier(MPI_COMM_WORLD);
                tt = MPI_Wtime();
            }
            double round_started = MPI_Wtime();
            if (local_n) {
                memset(x, 0, sizeof(*x) * (size_t)local_n);
                memset(x_im, 0, sizeof(*x_im) * (size_t)local_n);
            }
            analyse_complex(&mysolver, &solver_input);
            preprocess_complex(&mysolver, &solver_input);
            iterative_solver_complex(&mysolver, &solver_input);
            round_seconds[i] = (MPI_Wtime() - round_started);
        }
        time = (MPI_Wtime() - tt);
        SC26_SOLVER_DESTROY_COMPLEX(&mysolver, &solver_input);
    }
    double local_seconds = time, round_maximum[rounds];
    MPI_Reduce(&local_seconds, &time, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    MPI_Reduce(round_seconds, round_maximum, rounds, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    if (myrank == 0) {
        for (int i = 0; i < rounds; ++i)
            printf("CHECK round %d %s time : %.9f s\n", i + 1,
                   i < warmup_frequency ? "warmup" : "formal", round_maximum[i]);
        printf("CHECK formal total time : %.9f s\n", time);
        time = time * 1000.0 / test_frequency;
    }

    /* ========================================== */
    // Step 3: Check time, memory and correctness
    /* ========================================== */
    // check the memory
    mem_usage();

    gather_counts = (int*)malloc((size_t)size * sizeof(*gather_counts));
    gather_displs = (int*)malloc((size_t)size * sizeof(*gather_displs));
    int gather_array_status = (!gather_counts || !gather_displs) ? -1 : 0;
    int global_gather_array_status = 0;
    MPI_Allreduce(&gather_array_status, &global_gather_array_status, 1, MPI_INT, MPI_MIN, MPI_COMM_WORLD);
    if (global_gather_array_status) {
        if (myrank == 0) fprintf(stdout, "MPI solution gather allocation failed.\n");
        free(gather_counts);
        free(gather_displs);
        free(x);
        free(x_im);
        mpi_local_system_free(&local_system);
        MPI_Finalize();
        return -1;
    }
    mpi_row_counts(n, size, gather_counts, gather_displs);
    int gather_status = 0;
    if (myrank == 0) {
        x_global = (double*)malloc(sizeof(double) * (size_t)n);
        if (sys_type) x_global_im = (double*)malloc(sizeof(double) * (size_t)n);
        if (!x_global || (sys_type && !x_global_im)) gather_status = -1;
    }
    MPI_Bcast(&gather_status, 1, MPI_INT, 0, MPI_COMM_WORLD);
    if (gather_status) {
        free(x_global);
        free(x_global_im);
        free(x);
        free(x_im);
        mpi_local_system_free(&local_system);
        free(gather_counts);
        free(gather_displs);
        MPI_Finalize();
        return -1;
    }
    MPI_Gatherv(x, local_n, MPI_DOUBLE, x_global, gather_counts, gather_displs,
                MPI_DOUBLE, 0, MPI_COMM_WORLD);
    if (sys_type)
        MPI_Gatherv(x_im, local_n, MPI_DOUBLE, x_global_im, gather_counts, gather_displs,
                    MPI_DOUBLE, 0, MPI_COMM_WORLD);
    free(x);
    free(x_im);
    x = NULL;
    x_im = NULL;
    mpi_local_system_free(&local_system);
    row_ptr = NULL;
    col_idx = NULL;
    val = NULL;
    val_im = NULL;
    b = NULL;
    b_im = NULL;
    free(gather_counts);
    free(gather_displs);

    /* Re-read the complete system only on rank 0 for the final residual check. */
    int reload_status = 0;
    if (myrank == 0) {
        reload_status = load_linear_system(filename_matrix, filename_b, read_matrix_base, sys_type,
                                           &m, &n, &nnzA, &isSymmetricA, &row_ptr, &col_idx,
                                           &val, &val_im, &b, &b_im);
        if (reload_status == 0 && m != n) reload_status = -1;
    }
    MPI_Bcast(&reload_status, 1, MPI_INT, 0, MPI_COMM_WORLD);

    if (myrank == 0) {

        fprintf(stdout, "------------------------------------------\n");

        // check the memory
        // mem_usage();

        // check time
        fprintf(stdout, "CHECK end to end time :         %12.6lf ms\n", time);

        // store x to a file
        char* answer_x = "answer_x.rhs";
        if (sys_type == 0) // real rhs
            store_x(n, x_global, answer_x);
        else // complex rhs
            store_x_complex(n, x_global, x_global_im, answer_x);

        // check the correctness
        if (reload_status != 0) {
            fprintf(stdout, "Final full-system reload failed; residual check skipped.\n");
        } else if (sys_type == 0) // real system
        {
            // 1) using double precision
            check_correctness(n, row_ptr, col_idx, val, x_global, b);
            // 2) using long double precision
            check_correctness_ld_d2ld(n, row_ptr, col_idx, val, x_global, b);
#ifndef SC26_DISABLE_FLOAT128
            // 3) using float128 precision
            check_correctness_q_d2q(n, row_ptr, col_idx, val, x_global, b);
#endif

        } else { // complex system
            // 1) using double precision
            check_correctness_complex(n, row_ptr, col_idx, val, val_im, x_global, x_global_im, b, b_im);
            // 2) using long double precision
            check_correctness_complex_ld_d2ld(n, row_ptr, col_idx, val, val_im, x_global, x_global_im, b, b_im);
#ifndef SC26_DISABLE_FLOAT128
            // 3) using float128 precision
            check_correctness_complex_q_d2q(n, row_ptr, col_idx, val, val_im, x_global, x_global_im, b, b_im);
#endif

        }
        free(val_im);
        free(b_im);
        free(x_global);
        free(x_global_im);
        free(row_ptr);
        free(col_idx);
        free(val);
        free(b);
    }

    MPI_Finalize();
    return 0;
}

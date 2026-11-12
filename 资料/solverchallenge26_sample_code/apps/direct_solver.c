/*
 * This is the reference direct method solver code of SolverChallenge26
 */

// system file
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/time.h>

#include "solverchallenge26/diagnostics.h"
#include "solverchallenge26/system_loader.h"
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

    char* filename_matrix;       // the filename of matrix A
    char* filename_b;            // the filename of right-hand side vector b
    int   read_matrix_base = 1;  // 0-base or 1-base, default 1-base
    enum { warmup_frequency = 5, test_frequency = 5, rounds = warmup_frequency + test_frequency };
    int   sys_type         = 0;  // type of algebraic systems, 0: real, 1: complex; default 0

    /* ========================================== */
    // Step 0: Read command line argument
    /* ========================================== */
    if (argc < 3 || argc > 5) {
        print_help();
        return -1;
    }
    filename_matrix = argv[1];
    filename_b = argv[2];
    if (argc >= 4) {
        filename_matrix  = argv[1];
        filename_b       = argv[2];
        read_matrix_base = atoi(argv[3]);
        if (!((read_matrix_base == 0) || (read_matrix_base == 1))) {
            fprintf(stdout, "read_base error input %d\n", read_matrix_base);
            print_help();
            return -1;
        }
    }
    if (argc == 5) {
        sys_type = atoi(argv[4]);
        if (sys_type > 1 || sys_type < 0) {
            fprintf(stdout, "sys_type error input %d\n", sys_type);
            print_help();
            return -1;
        }
    }

    //! If the user does not specify parameter sys_type,
    //! it will automatically determine whether it is a real system or a complex system
    if (argc < 5) {
        if (detect_sys_type_from_matrix(filename_matrix, &sys_type) != 0) {
            fprintf(stdout, "Failed to detect system type from %s\n", filename_matrix);
            return -1;
        }
    }

    fprintf(stdout, "matrix name :      %s\nvectorb name :     %s\nread function :    %s\nsys_type :         %d\n",
            filename_matrix, filename_b, file_is_petsc_matrix(filename_matrix) ? "PETSc binary (0-base)" : (read_matrix_base ? "MTX base-1" : "MTX base-0"),
            sys_type);

    /* ========================================== */
    // Step 1: Load matrix and rhs (PETSc binary by default)
    /* ========================================== */
    if (load_linear_system(filename_matrix, filename_b, read_matrix_base, sys_type, &m, &n, &nnzA, &isSymmetricA, &row_ptr, &col_idx, &val, &val_im, &b,
                           &b_im) != 0) {
        return -1;
    }
    if (m != n) {
        fprintf(stdout, "Invalid matrix size.\n");
        return 0;
    }

    x = (double*)malloc(sizeof(double) * n);
    memset(x, 0.0, sizeof(double) * n);
    if (sys_type) {
        x_im = (double*)malloc(sizeof(double) * n);
        memset(x_im, 0.0, sizeof(double) * n);
    }

    struct SC26_SolverInput solver_input = {
        .global_n = n,
        .local_n = n,
        .row_begin = 0,
        .row_ptr = row_ptr,
        .col_idx = col_idx,
        .val = val,
        .val_im = val_im,
        .x = x,
        .x_im = x_im,
        .b = b,
        .b_im = b_im
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
                tt = GetCurrentTime();
            }
            double round_started = GetCurrentTime();
            memset(x, 0, sizeof(*x) * (size_t)n);
            preprocess(&mysolver, &solver_input);
            direct_solver(&mysolver, &solver_input);
            solve(&mysolver, &solver_input);
            round_seconds[i] = (GetCurrentTime() - round_started) / 1000.0;
        }
        time = (GetCurrentTime() - tt) / 1000.0;
        SC26_SOLVER_DESTROY(&mysolver, &solver_input);
    } else {
        struct MySolver_complex mysolver;
        SC26_SOLVER_CREATE_COMPLEX(&mysolver, &solver_input);
        for (int i = 0; i < rounds; ++i) {
            if (i == warmup_frequency) {
                tt = GetCurrentTime();
            }
            double round_started = GetCurrentTime();
            memset(x, 0, sizeof(*x) * (size_t)n);
            memset(x_im, 0, sizeof(*x_im) * (size_t)n);
            preprocess_complex(&mysolver, &solver_input);
            direct_solver_complex(&mysolver, &solver_input);
            solve_complex(&mysolver, &solver_input);
            round_seconds[i] = (GetCurrentTime() - round_started) / 1000.0;
        }
        time = (GetCurrentTime() - tt) / 1000.0;
        SC26_SOLVER_DESTROY_COMPLEX(&mysolver, &solver_input);
    }
    for (int i = 0; i < rounds; ++i)
        printf("CHECK round %d %s time : %.9f s\n", i + 1,
               i < warmup_frequency ? "warmup" : "formal", round_seconds[i]);
    printf("CHECK formal total time : %.9f s\n", time);
    time = time * 1000.0 / test_frequency;

    fprintf(stdout, "------------------------------------------\n");

    /* ========================================== */
    // Step 3: Check time, memory and correctness
    /* ========================================== */
    // check time
    fprintf(stdout, "CHECK end to end time :         %12.6lf ms\n", time);

    // check the memory
    mem_usage();

    // store x to a file
    char* answer_x = "answer_x.rhs";
    if (sys_type == 0) // real rhs
        store_x(n, x, answer_x);
    else // complex rhs
        store_x_complex(n, x, x_im, answer_x);

    // check the correctness
    if (sys_type == 0) // real system
    {
        // 1) using double precision
        check_correctness(n, row_ptr, col_idx, val, x, b);
        // 2) using long double precision
        check_correctness_ld_d2ld(n, row_ptr, col_idx, val, x, b);
#ifndef SC26_DISABLE_FLOAT128
        // 3) using float128 precision
        check_correctness_q_d2q(n, row_ptr, col_idx, val, x, b);
#endif

    } else { // complex system
        // 1) using double precision
        check_correctness_complex(n, row_ptr, col_idx, val, val_im, x, x_im, b, b_im);
        // 2) using long double precision
        check_correctness_complex_ld_d2ld(n, row_ptr, col_idx, val, val_im, x, x_im, b, b_im);
#ifndef SC26_DISABLE_FLOAT128
        // 3) using float128 precision
        check_correctness_complex_q_d2q(n, row_ptr, col_idx, val, val_im, x, x_im, b, b_im);
#endif

        free(val_im);
        free(x_im);
        free(b_im);
    }

    free(row_ptr);
    free(col_idx);
    free(val);
    free(x);
    free(b);

    return 0;
}

/*
 * Input view passed from the SolverChallenge26 harness to a problem solver.
 * The arrays remain owned by the harness and are valid for the call.
 */
#ifndef SC26_PUBLIC_SOLVER_INPUT_H
#define SC26_PUBLIC_SOLVER_INPUT_H

#ifdef MPI_USE
#include "mpi.h"
#endif

struct SC26_SolverInput {
    int global_n;
    int local_n;
    int row_begin;
    const int* row_ptr;
    const int* col_idx;
    const double* val;
    const double* val_im;
    double* x;
    double* x_im;
    const double* b;
    const double* b_im;
#ifdef MPI_USE
    MPI_Comm comm;
#endif
};

#endif

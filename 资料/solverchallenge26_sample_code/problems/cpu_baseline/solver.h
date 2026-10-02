/* SolverChallenge26 CPU baseline solver interface. */
#ifndef SC26_CPU_BASELINE_SOLVER_H
#define SC26_CPU_BASELINE_SOLVER_H

#include "solverchallenge26/solver_input.h"
#if defined(MPI_USE) && defined(ITERATIVE_SOLVER)
#include <HYPRE.h>
#include <HYPRE_IJ_mv.h>
#include <HYPRE_parcsr_ls.h>
#endif

#ifdef DIRECT_SOLVER
#include <mkl.h>
#if SC26_PROBLEM_NUMBER == 4 || SC26_PROBLEM_NUMBER == 10
typedef long long SC26_DirectInt;
#else
typedef MKL_INT SC26_DirectInt;
#endif
struct PardisoState {
    void *handle[64];
    SC26_DirectInt parameters[64], matrix_type;
#if SC26_PROBLEM_NUMBER == 4 || SC26_PROBLEM_NUMBER == 10
    SC26_DirectInt *row_ptr, *col_idx;
#endif
#if SC26_PROBLEM_NUMBER == 10
    double *scale;
#endif
    void *values, *rhs, *solution;
    double analyse_seconds, factor_seconds;
};
#endif

struct MySolver {
#ifdef DIRECT_SOLVER
    struct PardisoState direct;
#endif
#if defined(MPI_USE) && defined(ITERATIVE_SOLVER)
    HYPRE_IJMatrix matrix;
    HYPRE_IJVector rhs, solution;
    HYPRE_ParCSRMatrix par_matrix;
    HYPRE_ParVector par_rhs, par_solution;
    HYPRE_Solver gmres, amg;
#ifdef SC26_FIELD_SPLIT
    HYPRE_Solver coarse;
    HYPRE_Int *fields;
#endif
    HYPRE_BigInt *rows;
    HYPRE_Int *row_sizes;
    double *scale;
    double tolerance, analyse_seconds, preprocess_seconds;
#endif
};

struct MySolver_complex {
#ifdef DIRECT_SOLVER
    struct PardisoState direct;
#endif
    #if defined(MPI_USE) && defined(ITERATIVE_SOLVER)
    struct MySolver real;
    struct SC26_SolverInput expanded;
    int *row_ptr, *col_idx;
    double *values, *rhs, *solution;
#endif
};

#ifdef DIRECT_SOLVER
void preprocess(struct MySolver* solver, const struct SC26_SolverInput* input);
void direct_solver(struct MySolver* solver, const struct SC26_SolverInput* input);
void solve(struct MySolver* solver, const struct SC26_SolverInput* input);
void preprocess_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input);
void direct_solver_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input);
void solve_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input);
#endif

#ifdef ITERATIVE_SOLVER
void analyse(struct MySolver* solver, const struct SC26_SolverInput* input);
void preprocess(struct MySolver* solver, const struct SC26_SolverInput* input);
void iterative_solver(struct MySolver* solver, const struct SC26_SolverInput* input);
void analyse_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input);
void preprocess_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input);
void iterative_solver_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input);
#endif

#endif

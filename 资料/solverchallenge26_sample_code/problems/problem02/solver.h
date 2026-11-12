/* SolverChallenge26 problem 02 solver interface. */
#ifndef SC26_PROBLEM02_SOLVER_H
#define SC26_PROBLEM02_SOLVER_H

#include "solverchallenge26/solver_input.h"
#if defined(MPI_USE) && defined(ITERATIVE_SOLVER)
#include <HYPRE.h>
#include <HYPRE_IJ_mv.h>
#include <HYPRE_parcsr_ls.h>
#endif

struct MySolver {
#if defined(MPI_USE) && defined(ITERATIVE_SOLVER)
    HYPRE_IJMatrix matrix;
    HYPRE_IJVector rhs, solution;
    HYPRE_ParCSRMatrix par_matrix;
    HYPRE_ParVector par_rhs, par_solution;
    HYPRE_Solver gmres, amg;
    HYPRE_BigInt *rows;
    HYPRE_Int *row_sizes;
#ifdef HYPRE_USING_HIP
    HYPRE_IJVector raw_rhs, host_solution;
    HYPRE_ParVector par_raw_rhs, par_host_solution;
    long double rhs_mean;
#else
    double *projected_rhs;
#endif
    int project_constant;
    double tolerance, analyse_seconds, preprocess_seconds;
#endif
};

struct MySolver_complex {
    /* add solver state here */
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
#ifdef MPI_USE
void create_iterative(struct MySolver* solver, const struct SC26_SolverInput* input);
void destroy_iterative(struct MySolver* solver, const struct SC26_SolverInput* input);
#define SC26_SOLVER_CREATE create_iterative
#define SC26_SOLVER_DESTROY destroy_iterative
#define SC26_SOLVER_CREATE_COMPLEX(solver, input) ((void)0)
#define SC26_SOLVER_DESTROY_COMPLEX(solver, input) ((void)0)
#endif
void analyse(struct MySolver* solver, const struct SC26_SolverInput* input);
void preprocess(struct MySolver* solver, const struct SC26_SolverInput* input);
void iterative_solver(struct MySolver* solver, const struct SC26_SolverInput* input);
void analyse_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input);
void preprocess_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input);
void iterative_solver_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input);
#endif

#endif

/* SolverChallenge26 CPU baseline solver implementation. */
#include "solver.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef DIRECT_SOLVER
static void pardiso_phase(struct PardisoState *state, const struct SC26_SolverInput *input,
                          MKL_INT phase)
{
    MKL_INT one = 1, zero = 0, error, n = input->global_n;
    pardiso(state->handle, &one, &one, &state->matrix_type, &phase, &n,
            state->values, input->row_ptr, input->col_idx, &zero, &one,
            state->parameters, &zero, state->rhs, state->solution, &error);
    if (error) {
        fprintf(stderr, "PARDISO phase=%d error=%d\n", (int)phase, (int)error);
        exit(EXIT_FAILURE);
    }
}

static void prepare_direct(struct PardisoState *state, const struct SC26_SolverInput *input,
                           MKL_INT matrix_type)
{
    double started = dsecnd();
    #ifdef MPI_USE
    int size;
    MPI_Comm_size(input->comm, &size);
    if (size != 1) {
        fprintf(stderr, "PARDISO requires one MPI process with OpenMP threads\n");
        exit(EXIT_FAILURE);
    }
    #endif
    memset(state, 0, sizeof(*state));
    state->matrix_type = matrix_type;
    pardisoinit(state->handle, &state->matrix_type, state->parameters);
    state->parameters[1] = 2;
    state->parameters[7] = SC26_PROBLEM_NUMBER == 3 ? -8 : 4;
    state->parameters[26] = 1;
    state->parameters[34] = 1;
    state->values = (void *)input->val;
    state->rhs = (void *)input->b;
    state->solution = input->x;
    if (matrix_type == 13) {
        int n = input->global_n, nnz = input->row_ptr[n];
        MKL_Complex16 *a = malloc((size_t)nnz*sizeof(*a));
        MKL_Complex16 *b = malloc((size_t)n*sizeof(*b));
        MKL_Complex16 *x = calloc((size_t)n, sizeof(*x));
        if (!a || !b || !x) exit(EXIT_FAILURE);
        for (int k = 0; k < nnz; ++k) a[k] = (MKL_Complex16){input->val[k], input->val_im[k]};
        for (int i = 0; i < n; ++i) b[i] = (MKL_Complex16){input->b[i], input->b_im[i]};
        state->values = a; state->rhs = b; state->solution = x;
    }
    pardiso_phase(state, input, 11);
    state->analyse_seconds = dsecnd()-started;
    long long memory_kib = (long long)state->parameters[15]+state->parameters[16];
    if (memory_kib < state->parameters[14]) memory_kib = state->parameters[14];
    printf("T%d_PARDISO_ANALYSE seconds=%.6f estimated_peak_kib=%lld factor_nnz=%d\n",
           SC26_PROBLEM_NUMBER, state->analyse_seconds, memory_kib, (int)state->parameters[17]);
    fflush(stdout);
    if (memory_kib > 400LL*1024*1024) {
        fprintf(stderr, "PARDISO memory estimate exceeds the 400 GiB experiment budget\n");
        pardiso_phase(state, input, -1);
        exit(EXIT_FAILURE);
    }
}

static void factor_direct(struct PardisoState *state, const struct SC26_SolverInput *input)
{
    double started = dsecnd();
    pardiso_phase(state, input, 22);
    state->factor_seconds = dsecnd()-started;
    printf("T%d_PARDISO_FACTOR seconds=%.6f perturbed_pivots=%d\n", SC26_PROBLEM_NUMBER,
           state->factor_seconds, (int)state->parameters[13]);
    fflush(stdout);
}

static void finish_direct(struct PardisoState *state, const struct SC26_SolverInput *input)
{
    double started = dsecnd();
    pardiso_phase(state, input, 33);
    int refinements = state->parameters[6];
    pardiso_phase(state, input, -1);
    if (state->matrix_type == 13) {
        MKL_Complex16 *x = state->solution;
        for (int i = 0; i < input->global_n; ++i) {
            input->x[i] = x[i].real; input->x_im[i] = x[i].imag;
        }
        free(state->values); free(state->rhs); free(state->solution);
    }
    printf("T%d_PARDISO_DONE refinements=%d\n", SC26_PROBLEM_NUMBER, refinements);
    printf("T%d_PHASE_SECONDS analyse=%.6f factor=%.6f solve_cleanup=%.6f\n",
           SC26_PROBLEM_NUMBER, state->analyse_seconds, state->factor_seconds, dsecnd()-started);
    fflush(stdout);
}

void preprocess(struct MySolver* solver, const struct SC26_SolverInput* input)
{ prepare_direct(&solver->direct, input, 11); }
void direct_solver(struct MySolver* solver, const struct SC26_SolverInput* input)
{ factor_direct(&solver->direct, input); }
void solve(struct MySolver* solver, const struct SC26_SolverInput* input)
{ finish_direct(&solver->direct, input); }
void preprocess_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{ prepare_direct(&solver->direct, input, 13); }
void direct_solver_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{ factor_direct(&solver->direct, input); }
void solve_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{ finish_direct(&solver->direct, input); }
#endif

#ifdef ITERATIVE_SOLVER
#ifdef MPI_USE
#define HYPRE_CALL(call) do { \
    HYPRE_Int code = (call); \
    if (code) { \
        fprintf(stderr, "%s failed: HYPRE error %d\n", #call, (int)code); \
        MPI_Abort(input->comm, 1); \
    } \
} while (0)

void analyse(struct MySolver* solver, const struct SC26_SolverInput* input)
{
    double started = MPI_Wtime();
    HYPRE_CALL(HYPRE_Initialize());
    solver->tolerance = 1e-11;
    const char *setting = getenv("SC26_RTOL");
    if (setting) {
        char *end;
        solver->tolerance = strtod(setting, &end);
        if (*end || !(solver->tolerance > 0 && solver->tolerance < 1)) {
            fprintf(stderr, "SC26_RTOL must be a number between 0 and 1\n");
            MPI_Abort(input->comm, 1);
        }
    }
    solver->rows = malloc((size_t)input->local_n * sizeof(*solver->rows));
    solver->row_sizes = malloc((size_t)input->local_n * sizeof(*solver->row_sizes));
    if (input->local_n && (!solver->rows || !solver->row_sizes))
        MPI_Abort(input->comm, 1);
    for (int i = 0; i < input->local_n; ++i) {
        solver->rows[i] = input->row_begin + i;
        solver->row_sizes[i] = input->row_ptr[i + 1] - input->row_ptr[i];
    }
    HYPRE_BigInt lower = input->row_begin;
    HYPRE_BigInt upper = lower + input->local_n - 1;
    HYPRE_CALL(HYPRE_IJMatrixCreate(input->comm, lower, upper, lower, upper, &solver->matrix));
    HYPRE_CALL(HYPRE_IJMatrixSetObjectType(solver->matrix, HYPRE_PARCSR));
    HYPRE_CALL(HYPRE_IJMatrixSetRowSizes(solver->matrix, solver->row_sizes));
    solver->analyse_seconds = MPI_Wtime() - started;
}

void preprocess(struct MySolver* solver, const struct SC26_SolverInput* input)
{
    double started = MPI_Wtime();
    HYPRE_BigInt lower = input->row_begin;
    HYPRE_BigInt upper = lower + input->local_n - 1;
    int size;
    MPI_Comm_size(input->comm, &size);
    int *counts = malloc((size_t)size * sizeof(int));
    int *offsets = malloc((size_t)size * sizeof(int));
    double *local_scale = malloc((size_t)input->local_n * sizeof(double));
    solver->scale = malloc((size_t)input->global_n * sizeof(double));
    int nnz = input->row_ptr[input->local_n];
    double *scaled_values = malloc((size_t)nnz * sizeof(double));
    double *scaled_rhs = malloc((size_t)input->local_n * sizeof(double));
    if (!counts || !offsets || !solver->scale ||
        (input->local_n && (!local_scale || !scaled_rhs)) || (nnz && !scaled_values))
        MPI_Abort(input->comm, 1);
    for (int i = 0; i < input->local_n; ++i) {
        double maximum = 0;
        for (int k = input->row_ptr[i]; k < input->row_ptr[i+1]; ++k)
            maximum = fmax(maximum, fabs(input->val[k]));
        if (!(maximum > 0) || !isfinite(maximum)) {
            fprintf(stderr, "Invalid row scale at row %d\n", input->row_begin+i);
            MPI_Abort(input->comm, 1);
        }
        local_scale[i] = 1/sqrt(maximum);
    }
    MPI_Allgather(&input->local_n, 1, MPI_INT, counts, 1, MPI_INT, input->comm);
    MPI_Allgather(&input->row_begin, 1, MPI_INT, offsets, 1, MPI_INT, input->comm);
    MPI_Allgatherv(local_scale, input->local_n, MPI_DOUBLE, solver->scale,
                  counts, offsets, MPI_DOUBLE, input->comm);
    for (int i = 0; i < input->local_n; ++i) {
        scaled_rhs[i] = input->b[i]*local_scale[i];
        for (int k = input->row_ptr[i]; k < input->row_ptr[i+1]; ++k)
            scaled_values[k] = (input->val[k]*local_scale[i])*solver->scale[input->col_idx[k]];
    }
    free(counts);
    free(offsets);
    free(local_scale);
    HYPRE_CALL(HYPRE_IJMatrixInitialize(solver->matrix));
    HYPRE_CALL(HYPRE_IJMatrixSetValues(solver->matrix, input->local_n,
        solver->row_sizes, solver->rows, input->col_idx, scaled_values));
    free(scaled_values);
    HYPRE_CALL(HYPRE_IJMatrixAssemble(solver->matrix));
    HYPRE_CALL(HYPRE_IJMatrixGetObject(solver->matrix, (void **)&solver->par_matrix));
    HYPRE_CALL(HYPRE_IJVectorCreate(input->comm, lower, upper, &solver->rhs));
    HYPRE_CALL(HYPRE_IJVectorSetObjectType(solver->rhs, HYPRE_PARCSR));
    HYPRE_CALL(HYPRE_IJVectorInitialize(solver->rhs));
    HYPRE_CALL(HYPRE_IJVectorSetValues(solver->rhs, input->local_n, solver->rows, scaled_rhs));
    free(scaled_rhs);
    HYPRE_CALL(HYPRE_IJVectorAssemble(solver->rhs));
    HYPRE_CALL(HYPRE_IJVectorGetObject(solver->rhs, (void **)&solver->par_rhs));
    HYPRE_CALL(HYPRE_IJVectorCreate(input->comm, lower, upper, &solver->solution));
    HYPRE_CALL(HYPRE_IJVectorSetObjectType(solver->solution, HYPRE_PARCSR));
    HYPRE_CALL(HYPRE_IJVectorInitialize(solver->solution));
    HYPRE_CALL(HYPRE_IJVectorSetValues(solver->solution, input->local_n, solver->rows, input->x));
    HYPRE_CALL(HYPRE_IJVectorAssemble(solver->solution));
    HYPRE_CALL(HYPRE_IJVectorGetObject(solver->solution, (void **)&solver->par_solution));

#if SC26_PROBLEM_NUMBER == 6
    HYPRE_CALL(HYPRE_ILUCreate(&solver->amg));
    HYPRE_CALL(HYPRE_ILUSetType(solver->amg, 0));
    HYPRE_CALL(HYPRE_ILUSetLevelOfFill(solver->amg, 0));
    HYPRE_CALL(HYPRE_ILUSetMaxIter(solver->amg, 1));
    HYPRE_CALL(HYPRE_ILUSetTol(solver->amg, 0));
#else
    HYPRE_CALL(HYPRE_BoomerAMGCreate(&solver->amg));
    HYPRE_CALL(HYPRE_BoomerAMGSetCoarsenType(solver->amg, 10));
    HYPRE_CALL(HYPRE_BoomerAMGSetInterpType(solver->amg, 6));
    HYPRE_CALL(HYPRE_BoomerAMGSetPMaxElmts(solver->amg, 4));
    HYPRE_CALL(HYPRE_BoomerAMGSetStrongThreshold(solver->amg,
        SC26_PROBLEM_NUMBER == 3 ? 0.5 : 0.25));
    HYPRE_CALL(HYPRE_BoomerAMGSetRelaxType(solver->amg, 6));
    HYPRE_CALL(HYPRE_BoomerAMGSetNumSweeps(solver->amg, 1));
    HYPRE_CALL(HYPRE_BoomerAMGSetTol(solver->amg, 0));
    HYPRE_CALL(HYPRE_BoomerAMGSetMaxIter(solver->amg, 1));
#if SC26_PROBLEM_NUMBER == 3
    HYPRE_CALL(HYPRE_BoomerAMGSetNumFunctions(solver->amg, 3));
#endif
#endif
    HYPRE_CALL(HYPRE_ParCSRGMRESCreate(input->comm, &solver->gmres));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetKDim(solver->gmres, SC26_PROBLEM_NUMBER == 1 ? 30 : 50));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetMaxIter(solver->gmres, 300));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetTol(solver->gmres, solver->tolerance));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetAbsoluteTol(solver->gmres, 0));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetLogging(solver->gmres, 1));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetPrintLevel(solver->gmres, 2));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetPrecond(solver->gmres,
#if SC26_PROBLEM_NUMBER == 6
        HYPRE_ILUSolve, HYPRE_ILUSetup, solver->amg));
#else
        HYPRE_BoomerAMGSolve, HYPRE_BoomerAMGSetup, solver->amg));
#endif
    HYPRE_CALL(HYPRE_ParCSRGMRESSetup(solver->gmres,
        solver->par_matrix, solver->par_rhs, solver->par_solution));
    solver->preprocess_seconds = MPI_Wtime() - started;
}

void iterative_solver(struct MySolver* solver, const struct SC26_SolverInput* input)
{
    double started = MPI_Wtime();
    HYPRE_Int status = HYPRE_ParCSRGMRESSolve(solver->gmres,
        solver->par_matrix, solver->par_rhs, solver->par_solution);
    if (status & ~HYPRE_ERROR_CONV) {
        fprintf(stderr, "HYPRE GMRES failed: error %d\n", (int)status);
        MPI_Abort(input->comm, 1);
    }
    HYPRE_ClearError(HYPRE_ERROR_CONV);
    HYPRE_CALL(HYPRE_IJVectorGetValues(solver->solution, input->local_n, solver->rows, input->x));
    for (int i = 0; i < input->local_n; ++i)
        input->x[i] *= solver->scale[input->row_begin+i];
    free(solver->scale);
    HYPRE_Int iterations;
    HYPRE_Real residual;
    HYPRE_CALL(HYPRE_ParCSRGMRESGetNumIterations(solver->gmres, &iterations));
    HYPRE_CALL(HYPRE_ParCSRGMRESGetFinalRelativeResidualNorm(solver->gmres, &residual));
    if (!isfinite(residual)) {
        fprintf(stderr, "CPU GMRES did not converge: residual=%.12e tolerance=%.12e\n",
                residual, solver->tolerance);
        MPI_Abort(input->comm, 1);
    }
    HYPRE_CALL(HYPRE_ParCSRGMRESDestroy(solver->gmres));
#if SC26_PROBLEM_NUMBER == 6
    HYPRE_CALL(HYPRE_ILUDestroy(solver->amg));
#else
    HYPRE_CALL(HYPRE_BoomerAMGDestroy(solver->amg));
#endif
    HYPRE_CALL(HYPRE_IJMatrixDestroy(solver->matrix));
    HYPRE_CALL(HYPRE_IJVectorDestroy(solver->rhs));
    HYPRE_CALL(HYPRE_IJVectorDestroy(solver->solution));
    free(solver->rows);
    free(solver->row_sizes);
    HYPRE_CALL(HYPRE_Finalize());
    double times[3] = {solver->analyse_seconds, solver->preprocess_seconds, MPI_Wtime() - started};
    double maximum[3];
    MPI_Reduce(times, maximum, 3, MPI_DOUBLE, MPI_MAX, 0, input->comm);
    int rank;
    MPI_Comm_rank(input->comm, &rank);
    if (rank == 0) {
        printf("T%d_GMRES iterations=%d scaled_relative_residual=%.12e rtol=%.1e converged=%d\n",
               SC26_PROBLEM_NUMBER, (int)iterations, residual, solver->tolerance,
               !status && residual <= solver->tolerance);
        printf("T%d_PHASE_SECONDS analyse=%.6f preprocess=%.6f solve_cleanup=%.6f\n",
               SC26_PROBLEM_NUMBER, maximum[0], maximum[1], maximum[2]);
        fflush(stdout);
    }
}
#else
void analyse(struct MySolver* solver, const struct SC26_SolverInput* input)
{
    (void)solver; (void)input;
    fprintf(stderr, "CPU HYPRE baseline requires the MPI_iterative_solver target\n");
    exit(EXIT_FAILURE);
}
void preprocess(struct MySolver* solver, const struct SC26_SolverInput* input)
{
    (void)solver; (void)input;
}
void iterative_solver(struct MySolver* solver, const struct SC26_SolverInput* input)
{
    (void)solver; (void)input;
}
#endif

#ifdef MPI_USE
void analyse_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{
    double started = MPI_Wtime();
    int n = input->local_n, nnz = input->row_ptr[n];
    solver->row_ptr = malloc((size_t)(2*n+1) * sizeof(int));
    solver->col_idx = malloc((size_t)4*nnz * sizeof(int));
    solver->values = malloc((size_t)4*nnz * sizeof(double));
    solver->rhs = malloc((size_t)2*n * sizeof(double));
    solver->solution = calloc((size_t)2*n, sizeof(double));
    if (!solver->row_ptr || (n && (!solver->rhs || !solver->solution)) ||
        (nnz && (!solver->col_idx || !solver->values))) MPI_Abort(input->comm, 1);
    for (int i = 0; i < n; ++i) {
        int begin = input->row_ptr[i], end = input->row_ptr[i+1], count = end-begin;
        solver->row_ptr[2*i] = 4*begin;
        solver->row_ptr[2*i+1] = 4*begin+2*count;
        for (int k = begin; k < end; ++k) {
            int pos = 4*begin+2*(k-begin), col = 2*input->col_idx[k];
            solver->col_idx[pos] = solver->col_idx[pos+2*count] = col;
            solver->col_idx[pos+1] = solver->col_idx[pos+2*count+1] = col+1;
        }
    }
    solver->row_ptr[2*n] = 4*nnz;
    solver->expanded = (struct SC26_SolverInput) {
        .global_n = 2*input->global_n, .local_n = 2*n, .row_begin = 2*input->row_begin,
        .row_ptr = solver->row_ptr, .col_idx = solver->col_idx, .val = solver->values,
        .b = solver->rhs, .x = solver->solution, .comm = input->comm
    };
    analyse(&solver->real, &solver->expanded);
    solver->real.analyse_seconds = MPI_Wtime()-started;
}

void preprocess_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{
    double started = MPI_Wtime();
    /* Interleaved real form: [Re(A), -Im(A); Im(A), Re(A)]. */
    for (int i = 0; i < input->local_n; ++i) {
        int begin = input->row_ptr[i], end = input->row_ptr[i+1], count = end-begin;
        for (int k = begin; k < end; ++k) {
            int pos = 4*begin+2*(k-begin);
            solver->values[pos] = solver->values[pos+2*count+1] = input->val[k];
            solver->values[pos+1] = -input->val_im[k];
            solver->values[pos+2*count] = input->val_im[k];
        }
        solver->rhs[2*i] = input->b[i];
        solver->rhs[2*i+1] = input->b_im[i];
    }
    preprocess(&solver->real, &solver->expanded);
    solver->real.preprocess_seconds = MPI_Wtime()-started;
}

void iterative_solver_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{
    iterative_solver(&solver->real, &solver->expanded);
    for (int i = 0; i < input->local_n; ++i) {
        input->x[i] = solver->solution[2*i];
        input->x_im[i] = solver->solution[2*i+1];
    }
    free(solver->row_ptr);
    free(solver->col_idx);
    free(solver->values);
    free(solver->rhs);
    free(solver->solution);
}
#else
void analyse_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{
    (void)solver; (void)input;
    fprintf(stderr, "CPU HYPRE baseline requires the MPI_iterative_solver target\n");
    exit(EXIT_FAILURE);
}
void preprocess_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{
    (void)solver; (void)input;
}
void iterative_solver_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{
    (void)solver; (void)input;
}
#endif
#endif

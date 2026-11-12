/* SolverChallenge26 CPU baseline solver implementation. */
#include "solver.h"
#include <limits.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef DIRECT_SOLVER
#if SC26_PROBLEM_NUMBER == 10
struct ComplexEntry { SC26_DirectInt column; MKL_Complex16 value; };
static int compare_entry(const void *left, const void *right)
{
    const struct ComplexEntry *a = left, *b = right;
    return (a->column > b->column)-(a->column < b->column);
}
#endif

static void pardiso_phase(struct PardisoState *state, const struct SC26_SolverInput *input,
                          SC26_DirectInt phase)
{
    SC26_DirectInt one = 1, zero = 0, error, n = input->global_n;
    void *values = phase == 11 ? NULL : state->values;
#if SC26_PROBLEM_NUMBER == 4 || SC26_PROBLEM_NUMBER == 10
    pardiso_64(state->handle, &one, &one, &state->matrix_type, &phase, &n,
            values, state->row_ptr, state->col_idx, &zero, &one,
            state->parameters, &one, state->rhs, state->solution, &error);
#else
    pardiso(state->handle, &one, &one, &state->matrix_type, &phase, &n,
            values, input->row_ptr, input->col_idx, &zero, &one,
            state->parameters, &one, state->rhs, state->solution, &error);
#endif
    if (error) {
        fprintf(stderr, "PARDISO phase=%lld error=%lld\n", (long long)phase, (long long)error);
        exit(EXIT_FAILURE);
    }
}

void create_direct(struct PardisoState *state, const struct SC26_SolverInput *input,
                           MKL_INT matrix_type)
{
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
#if SC26_PROBLEM_NUMBER == 4 || SC26_PROBLEM_NUMBER == 10
    void *default_handle[64];
    MKL_INT defaults[64];
    pardisoinit(default_handle, &matrix_type, defaults);
    printf("T%d_PARDISO_LIBRARY_DEFAULTS interface=pardiso index_bits=32 scaling=%d matching=%d\n", SC26_PROBLEM_NUMBER, defaults[10], defaults[12]);
    /* pardiso_64 requires explicit initialization of its 64-bit parameters. */
    state->parameters[0] = 1;
    state->parameters[9] = 13;
    state->parameters[17] = -1;
    state->parameters[18] = -1;
    int rows = input->global_n, nonzeros = input->row_ptr[rows];
    state->row_ptr = malloc(((size_t)rows+1)*sizeof(*state->row_ptr));
    state->col_idx = malloc((size_t)nonzeros*sizeof(*state->col_idx));
    if (!state->row_ptr || !state->col_idx) exit(EXIT_FAILURE);
#if SC26_PROBLEM_NUMBER == 4
    for (int i = 0; i <= rows; ++i) state->row_ptr[i] = input->row_ptr[i];
    for (int k = 0; k < nonzeros; ++k) state->col_idx[k] = input->col_idx[k];
#else
    int max_width = 0;
    for (int i = 0; i < rows; ++i) {
        int width = input->row_ptr[i+1]-input->row_ptr[i];
        if (width > max_width) max_width = width;
    }
    state->row_order = malloc((size_t)rows*sizeof(*state->row_order));
    state->entries = malloc((size_t)max_width*sizeof(*state->entries));
    state->scale = malloc((size_t)rows*sizeof(*state->scale));
    if (!state->row_order || !state->entries || !state->scale) exit(EXIT_FAILURE);
#endif
#else
    pardisoinit(state->handle, &state->matrix_type, state->parameters);
    printf("T%d_PARDISO_LIBRARY_DEFAULTS scaling=%d matching=%d\n", SC26_PROBLEM_NUMBER,
           state->parameters[10], state->parameters[12]);
#endif
    state->parameters[1] = 2;
    state->parameters[7] = SC26_PROBLEM_NUMBER == 3 ? -8 : 4;
    state->parameters[10] = 0;
    state->parameters[12] = 0;
    state->parameters[26] = 1;
    state->parameters[34] = 1;
    MKLVersion version;
    mkl_get_version(&version);
    printf("T%d_PARDISO_CONFIG mkl=%d.%d.%d build=%s index_bits=%zu ordering=%lld refinement=%lld pivot_exponent=%lld scaling=%lld matching=%lld checker=%lld zero_based=%lld analysis_values=null\n",
           SC26_PROBLEM_NUMBER, version.MajorVersion, version.MinorVersion, version.UpdateVersion,
           version.Build, 8*sizeof(SC26_DirectInt), (long long)state->parameters[1],
           (long long)state->parameters[7], (long long)state->parameters[9],
           (long long)state->parameters[10], (long long)state->parameters[12],
           (long long)state->parameters[26], (long long)state->parameters[34]);
    state->values = (void *)input->val;
    state->rhs = (void *)input->b;
    state->solution = input->x;
    if (matrix_type == 13) {
        int n = input->global_n, nnz = input->row_ptr[n];
        MKL_Complex16 *a = malloc((size_t)nnz*sizeof(*a));
        MKL_Complex16 *b = malloc((size_t)n*sizeof(*b));
        MKL_Complex16 *x = malloc((size_t)n*sizeof(*x));
        if (!a || !b || !x) exit(EXIT_FAILURE);
#if SC26_PROBLEM_NUMBER != 10
        for (int k = 0; k < nnz; ++k) a[k] = (MKL_Complex16){input->val[k], input->val_im[k]};
        for (int i = 0; i < n; ++i) b[i] = (MKL_Complex16){input->b[i], input->b_im[i]};
#endif
        state->values = a; state->rhs = b; state->solution = x;
    }
}

static void prepare_direct(struct PardisoState *state, const struct SC26_SolverInput *input)
{
    double started = dsecnd();
    if (state->matrix_type == 13)
        memset(state->solution, 0, (size_t)input->global_n*sizeof(MKL_Complex16));
#if SC26_PROBLEM_NUMBER == 10
    int rows = input->global_n;
    int *row_order = state->row_order;
    for (int i = 0; i < rows; ++i) row_order[i] = -1;
    int missing_diagonal = 0;
    for (int i = 0; i < rows; ++i) {
        for (int k = input->row_ptr[i]; k < input->row_ptr[i+1]; ++k) {
            if (input->col_idx[k] == i) {
                row_order[i] = i;
                break;
            }
        }
        missing_diagonal += row_order[i] < 0;
    }
    int nearby_pairs = 0;
    for (int row = 0; row < rows; ++row) {
        if (row_order[row] >= 0) continue;
        int nearest = -1, distance = rows;
        for (int k = input->row_ptr[row]; k < input->row_ptr[row+1]; ++k) {
            int column = input->col_idx[k], delta = abs(column-row);
            if (row_order[column] != column || delta >= distance) continue;
            for (int reverse = input->row_ptr[column]; reverse < input->row_ptr[column+1]; ++reverse) {
                if (input->col_idx[reverse] != row) continue;
                nearest = column;
                distance = delta;
                break;
            }
        }
        if (nearest < 0) {
            fprintf(stderr, "T10 structural matching has no reciprocal partner for row %d\n", row);
            exit(EXIT_FAILURE);
        }
        row_order[row] = nearest; row_order[nearest] = row;
        ++nearby_pairs;
    }
    state->row_ptr[0] = 0;
    int moved = 0;
    for (int i = 0; i < rows; ++i) {
        int source = row_order[i];
        moved += source != i;
        state->row_ptr[i+1] = state->row_ptr[i]+input->row_ptr[source+1]-input->row_ptr[source];
        SC26_DirectInt destination = state->row_ptr[i];
        for (int k = input->row_ptr[source]; k < input->row_ptr[source+1]; ++k)
            state->col_idx[destination++] = input->col_idx[k];
    }
    printf("T10_STRUCTURE_MATCH missing_diagonal=%d rows_moved=%d matched=%d nearby_pairs=%d\n",
           missing_diagonal, moved, rows, nearby_pairs);
    if (state->matrix_type == 13) {
        MKL_Complex16 *a = state->values, *b = state->rhs;
        for (int i = 0; i < rows; ++i) {
            int source = row_order[i];
            SC26_DirectInt destination = state->row_ptr[i];
            for (int k = input->row_ptr[source]; k < input->row_ptr[source+1]; ++k)
                a[destination++] = (MKL_Complex16){input->val[k], input->val_im[k]};
            b[i] = (MKL_Complex16){input->b[source], input->b_im[source]};
        }
        /* The supplied T10 CSR contains an unsorted final row. */
        int sorted_rows = 0;
        for (int i = 0; i < rows; ++i) {
            int begin = state->row_ptr[i], end = state->row_ptr[i+1], unsorted = 0;
            for (int k = begin+1; k < end; ++k)
                if (state->col_idx[k] < state->col_idx[k-1]) { unsorted = 1; break; }
            if (!unsorted) continue;
            struct ComplexEntry *entries = state->entries;
            for (int k = begin; k < end; ++k)
                entries[k-begin] = (struct ComplexEntry){state->col_idx[k], a[k]};
            qsort(entries, (size_t)(end-begin), sizeof(*entries), compare_entry);
            for (int k = begin; k < end; ++k) {
                state->col_idx[k] = entries[k-begin].column;
                a[k] = entries[k-begin].value;
            }
            ++sorted_rows;
        }
        printf("T10_PARDISO_SORT rows=%d\n", sorted_rows);
        fflush(stdout);
    }
#endif
    pardiso_phase(state, input, 11);
    state->analyse_seconds = dsecnd()-started;
    long long memory_kib = (long long)state->parameters[15]+state->parameters[16];
    if (memory_kib < state->parameters[14]) memory_kib = state->parameters[14];
    printf("T%d_PARDISO_ANALYSE seconds=%.6f estimated_peak_kib=%lld factor_nnz=%lld\n",
           SC26_PROBLEM_NUMBER, state->analyse_seconds, memory_kib, (long long)state->parameters[17]);
    fflush(stdout);
    long long budget_gib = SC26_PROBLEM_NUMBER == 9 ? 85 : 400;
    if (memory_kib > budget_gib*1024*1024) {
        fprintf(stderr, "PARDISO memory estimate exceeds the %lld GiB experiment budget\n", budget_gib);
        pardiso_phase(state, input, -1);
        exit(EXIT_FAILURE);
    }
}

static void factor_direct(struct PardisoState *state, const struct SC26_SolverInput *input)
{
    double started = dsecnd();
#if SC26_PROBLEM_NUMBER == 10
    int n = input->global_n;
    MKL_Complex16 *a = state->values, *b = state->rhs;
    for (int i = 0; i < n; ++i) {
        double maximum = 0;
        for (SC26_DirectInt k = state->row_ptr[i]; k < state->row_ptr[i+1]; ++k)
            maximum = fmax(maximum, fmax(fabs(a[k].real), fabs(a[k].imag)));
        state->scale[i] = 1/sqrt(maximum);
    }
    for (int i = 0; i < n; ++i) {
        b[i].real *= state->scale[i]; b[i].imag *= state->scale[i];
        for (SC26_DirectInt k = state->row_ptr[i]; k < state->row_ptr[i+1]; ++k) {
            double column_scale = state->scale[state->col_idx[k]];
            a[k].real = (a[k].real*state->scale[i])*column_scale;
            a[k].imag = (a[k].imag*state->scale[i])*column_scale;
        }
    }
    printf("T10_DIAGONAL_EQUILIBRATION stage=numerical_preparation matrix=D(PA)D rhs=DPb solution=Dy\n");
#endif
    pardiso_phase(state, input, 22);
    state->factor_seconds = dsecnd()-started;
    printf("T%d_PARDISO_FACTOR seconds=%.6f perturbed_pivots=%lld\n", SC26_PROBLEM_NUMBER,
           state->factor_seconds, (long long)state->parameters[13]);
    fflush(stdout);
}

static void finish_direct(struct PardisoState *state, const struct SC26_SolverInput *input)
{
    double started = dsecnd();
    pardiso_phase(state, input, 33);
    int refinements = state->parameters[6];
    if (state->matrix_type == 13) {
        MKL_Complex16 *x = state->solution;
#if SC26_PROBLEM_NUMBER == 10
        for (int i = 0; i < input->global_n; ++i) {
            x[i].real *= state->scale[i]; x[i].imag *= state->scale[i];
        }
#endif
        for (int i = 0; i < input->global_n; ++i) {
            input->x[i] = x[i].real; input->x_im[i] = x[i].imag;
        }
    }
    printf("T%d_PARDISO_DONE refinements=%d\n", SC26_PROBLEM_NUMBER, refinements);
    printf("T%d_PHASE_SECONDS analyse=%.6f factor=%.6f solve=%.6f\n",
           SC26_PROBLEM_NUMBER, state->analyse_seconds, state->factor_seconds, dsecnd()-started);
    fflush(stdout);
}

void destroy_direct(struct PardisoState *state, const struct SC26_SolverInput *input)
{
    pardiso_phase(state, input, -1);
#if SC26_PROBLEM_NUMBER == 4 || SC26_PROBLEM_NUMBER == 10
    free(state->row_ptr);
    free(state->col_idx);
#endif
#if SC26_PROBLEM_NUMBER == 10
    free(state->scale);
    free(state->row_order);
    free(state->entries);
#endif
    if (state->matrix_type == 13) {
        free(state->values);
        free(state->rhs);
        free(state->solution);
    }
}

void preprocess(struct MySolver* solver, const struct SC26_SolverInput* input)
{ prepare_direct(&solver->direct, input); }
void direct_solver(struct MySolver* solver, const struct SC26_SolverInput* input)
{ factor_direct(&solver->direct, input); }
void solve(struct MySolver* solver, const struct SC26_SolverInput* input)
{ finish_direct(&solver->direct, input); }
void preprocess_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{ prepare_direct(&solver->direct, input); }
void direct_solver_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{ factor_direct(&solver->direct, input); }
void solve_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{ finish_direct(&solver->direct, input); }
#endif

#ifdef ITERATIVE_SOLVER
#ifdef MPI_USE
#if !defined(SC26_FIELD_SPLIT) && (SC26_PROBLEM_NUMBER == 5 || SC26_PROBLEM_NUMBER == 6 || SC26_PROBLEM_NUMBER == 7 || SC26_PROBLEM_NUMBER == 8 || SC26_PROBLEM_NUMBER == 10)
#define SC26_LOCAL_ILU
#include <_hypre_parcsr_ls.h>
#endif
#define HYPRE_CALL(call) do { \
    HYPRE_Int code = (call); \
    if (code) { \
        fprintf(stderr, "%s failed: HYPRE error %d\n", #call, (int)code); \
        MPI_Abort(input->comm, 1); \
    } \
} while (0)

void create_iterative(struct MySolver* solver, const struct SC26_SolverInput* input)
{
    HYPRE_CALL(HYPRE_Initialize());
    solver->tolerance = SC26_PROBLEM_NUMBER == 5 ? 5e-9 :
                        SC26_PROBLEM_NUMBER == 7 ? 1e-12 : 1e-11;
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
    HYPRE_BigInt lower = input->row_begin;
    HYPRE_BigInt upper = lower + input->local_n - 1;
    HYPRE_CALL(HYPRE_IJMatrixCreate(input->comm, lower, upper, lower, upper, &solver->matrix));
    HYPRE_CALL(HYPRE_IJMatrixSetObjectType(solver->matrix, HYPRE_PARCSR));
    for (int i = 0; i < input->local_n; ++i) {
        solver->rows[i] = input->row_begin + i;
        solver->row_sizes[i] = input->row_ptr[i + 1] - input->row_ptr[i];
    }
    HYPRE_CALL(HYPRE_IJMatrixSetRowSizes(solver->matrix, solver->row_sizes));
    HYPRE_CALL(HYPRE_IJMatrixInitialize(solver->matrix));
    int size;
    MPI_Comm_size(input->comm, &size);
    solver->counts = malloc((size_t)size * sizeof(int));
    solver->offsets = malloc((size_t)size * sizeof(int));
    solver->local_scale = malloc((size_t)input->local_n * sizeof(double));
    solver->scale = malloc((size_t)input->global_n * sizeof(double));
    int nnz = input->row_ptr[input->local_n];
    solver->scaled_values = malloc((size_t)nnz * sizeof(double));
    solver->scaled_rhs = malloc((size_t)input->local_n * sizeof(double));
    if (!solver->counts || !solver->offsets || !solver->scale ||
        (input->local_n && (!solver->local_scale || !solver->scaled_rhs)) || (nnz && !solver->scaled_values))
        MPI_Abort(input->comm, 1);
    HYPRE_CALL(HYPRE_IJVectorCreate(input->comm, lower, upper, &solver->rhs));
    HYPRE_CALL(HYPRE_IJVectorSetObjectType(solver->rhs, HYPRE_PARCSR));
    HYPRE_CALL(HYPRE_IJVectorInitialize(solver->rhs));
    HYPRE_CALL(HYPRE_IJVectorAssemble(solver->rhs));
    HYPRE_CALL(HYPRE_IJVectorGetObject(solver->rhs, (void **)&solver->par_rhs));
    HYPRE_CALL(HYPRE_IJVectorCreate(input->comm, lower, upper, &solver->solution));
    HYPRE_CALL(HYPRE_IJVectorSetObjectType(solver->solution, HYPRE_PARCSR));
    HYPRE_CALL(HYPRE_IJVectorInitialize(solver->solution));
    HYPRE_CALL(HYPRE_IJVectorAssemble(solver->solution));
    HYPRE_CALL(HYPRE_IJVectorGetObject(solver->solution, (void **)&solver->par_solution));

#ifdef SC26_FIELD_SPLIT
    HYPRE_Int block = SC26_PROBLEM_NUMBER == 5 ? 4 : 3;
    HYPRE_Int pressure = SC26_PROBLEM_NUMBER == 5 ? 3 : 0;
    HYPRE_Int coarse_count = 1, *coarse_indices = &pressure;
    solver->fields = malloc((size_t)input->local_n*sizeof(*solver->fields));
    if (input->local_n && !solver->fields) MPI_Abort(input->comm, 1);
    for (int i = 0; i < input->local_n; ++i)
        solver->fields[i] = (input->row_begin+i)%block;
    HYPRE_CALL(HYPRE_MGRCreate(&solver->amg));
    HYPRE_CALL(HYPRE_MGRSetCpointsByPointMarkerArray(solver->amg, block, 1,
        &coarse_count, &coarse_indices, solver->fields));
    HYPRE_CALL(HYPRE_MGRSetNonCpointsToFpoints(solver->amg, 1));
    HYPRE_CALL(HYPRE_MGRSetInterpType(solver->amg, 2));
    HYPRE_CALL(HYPRE_MGRSetRestrictType(solver->amg, 0));
    HYPRE_CALL(HYPRE_MGRSetRelaxType(solver->amg, 6));
    HYPRE_CALL(HYPRE_MGRSetNumRelaxSweeps(solver->amg, 1));
    HYPRE_CALL(HYPRE_MGRSetGlobalSmoothType(solver->amg, 16));
    HYPRE_CALL(HYPRE_MGRSetMaxGlobalSmoothIters(solver->amg, 1));
    HYPRE_CALL(HYPRE_MGRSetMaxIter(solver->amg, 1));
    HYPRE_CALL(HYPRE_MGRSetTol(solver->amg, 0));
    HYPRE_CALL(HYPRE_BoomerAMGCreate(&solver->coarse));
    HYPRE_CALL(HYPRE_BoomerAMGSetCoarsenType(solver->coarse, 10));
    HYPRE_CALL(HYPRE_BoomerAMGSetInterpType(solver->coarse, 6));
    HYPRE_CALL(HYPRE_BoomerAMGSetPMaxElmts(solver->coarse, 4));
    HYPRE_CALL(HYPRE_BoomerAMGSetRelaxType(solver->coarse, 6));
    HYPRE_CALL(HYPRE_BoomerAMGSetMaxIter(solver->coarse, 1));
    HYPRE_CALL(HYPRE_BoomerAMGSetTol(solver->coarse, 0));
    HYPRE_CALL(HYPRE_MGRSetCoarseSolver(solver->amg,
        HYPRE_BoomerAMGSolve, HYPRE_BoomerAMGSetup, solver->coarse));
#elif defined(SC26_LOCAL_ILU)
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
        (SC26_PROBLEM_NUMBER == 3 || SC26_PROBLEM_NUMBER == 4) ? 0.5 : 0.25));
    HYPRE_CALL(HYPRE_BoomerAMGSetRelaxType(solver->amg, 6));
    HYPRE_CALL(HYPRE_BoomerAMGSetNumSweeps(solver->amg, 1));
    HYPRE_CALL(HYPRE_BoomerAMGSetTol(solver->amg, 0));
    HYPRE_CALL(HYPRE_BoomerAMGSetMaxIter(solver->amg, 1));
#if SC26_PROBLEM_NUMBER == 3 || SC26_PROBLEM_NUMBER == 4
    HYPRE_CALL(HYPRE_BoomerAMGSetNumFunctions(solver->amg, 3));
#endif
#endif
    HYPRE_CALL(HYPRE_ParCSRGMRESCreate(input->comm, &solver->gmres));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetKDim(solver->gmres, SC26_PROBLEM_NUMBER == 1 ? 30 : 50));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetMaxIter(solver->gmres, SC26_PROBLEM_NUMBER == 5 ? 450 : 300));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetTol(solver->gmres, solver->tolerance));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetAbsoluteTol(solver->gmres, 0));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetLogging(solver->gmres, 1));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetPrintLevel(solver->gmres, 2));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetPrecond(solver->gmres,
#ifdef SC26_FIELD_SPLIT
        HYPRE_MGRSolve, HYPRE_MGRSetup, solver->amg));
#elif defined(SC26_LOCAL_ILU)
        HYPRE_ILUSolve, HYPRE_ILUSetup, solver->amg));
#else
        HYPRE_BoomerAMGSolve, HYPRE_BoomerAMGSetup, solver->amg));
#endif
}

void analyse(struct MySolver* solver, const struct SC26_SolverInput* input)
{
    double started = MPI_Wtime();
    for (int i = 0; i < input->local_n; ++i) {
        double maximum = 0;
        for (int k = input->row_ptr[i]; k < input->row_ptr[i+1]; ++k)
            maximum = fmax(maximum, fabs(input->val[k]));
        if (!(maximum > 0) || !isfinite(maximum)) {
            fprintf(stderr, "Invalid row scale at row %d\n", input->row_begin+i);
            MPI_Abort(input->comm, 1);
        }
        solver->local_scale[i] = 1/sqrt(maximum);
    }
    MPI_Allgather(&input->local_n, 1, MPI_INT, solver->counts, 1, MPI_INT, input->comm);
    MPI_Allgather(&input->row_begin, 1, MPI_INT, solver->offsets, 1, MPI_INT, input->comm);
    MPI_Allgatherv(solver->local_scale, input->local_n, MPI_DOUBLE, solver->scale,
                  solver->counts, solver->offsets, MPI_DOUBLE, input->comm);
    for (int i = 0; i < input->local_n; ++i) {
        solver->scaled_rhs[i] = input->b[i]*solver->local_scale[i];
        for (int k = input->row_ptr[i]; k < input->row_ptr[i+1]; ++k)
            solver->scaled_values[k] = (input->val[k]*solver->local_scale[i])*solver->scale[input->col_idx[k]];
    }
    solver->analyse_seconds = MPI_Wtime() - started;
}

void preprocess(struct MySolver* solver, const struct SC26_SolverInput* input)
{
    double started = MPI_Wtime();
    HYPRE_CALL(HYPRE_IJMatrixSetValues(solver->matrix, input->local_n,
        solver->row_sizes, solver->rows, input->col_idx, solver->scaled_values));
    HYPRE_CALL(HYPRE_IJMatrixAssemble(solver->matrix));
    HYPRE_CALL(HYPRE_IJMatrixGetObject(solver->matrix, (void **)&solver->par_matrix));
    HYPRE_CALL(HYPRE_IJVectorSetValues(solver->rhs, input->local_n, solver->rows, solver->scaled_rhs));
    HYPRE_CALL(HYPRE_IJVectorSetValues(solver->solution, input->local_n, solver->rows, input->x));
#ifdef SC26_LOCAL_ILU
    /* HYPRE 2.33 caches the local RCM ordering in the ILU handle. */
    hypre_ParILUData *ilu = (hypre_ParILUData *)solver->amg;
    hypre_TFree(hypre_ParILUDataPerm(ilu), HYPRE_MEMORY_HOST);
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
    HYPRE_Int iterations;
    HYPRE_Real residual;
    HYPRE_CALL(HYPRE_ParCSRGMRESGetNumIterations(solver->gmres, &iterations));
    HYPRE_CALL(HYPRE_ParCSRGMRESGetFinalRelativeResidualNorm(solver->gmres, &residual));
    if (!isfinite(residual)) {
        fprintf(stderr, "CPU GMRES did not converge: residual=%.12e tolerance=%.12e\n",
                residual, solver->tolerance);
        MPI_Abort(input->comm, 1);
    }
    double times[3] = {solver->analyse_seconds, solver->preprocess_seconds, MPI_Wtime() - started};
    double maximum[3];
    MPI_Reduce(times, maximum, 3, MPI_DOUBLE, MPI_MAX, 0, input->comm);
    int rank;
    MPI_Comm_rank(input->comm, &rank);
    if (rank == 0) {
        printf("T%d_GMRES iterations=%d scaled_relative_residual=%.12e rtol=%.1e converged=%d\n",
               SC26_PROBLEM_NUMBER, (int)iterations, residual, solver->tolerance,
               !status && residual <= solver->tolerance);
        printf("T%d_PHASE_SECONDS analyse=%.6f preprocess=%.6f solve=%.6f\n",
               SC26_PROBLEM_NUMBER, maximum[0], maximum[1], maximum[2]);
        fflush(stdout);
    }
}
void destroy_iterative(struct MySolver* solver, const struct SC26_SolverInput* input)
{
    HYPRE_CALL(HYPRE_ParCSRGMRESDestroy(solver->gmres));
#ifdef SC26_FIELD_SPLIT
    HYPRE_CALL(HYPRE_MGRDestroy(solver->amg));
    HYPRE_CALL(HYPRE_BoomerAMGDestroy(solver->coarse));
    free(solver->fields);
#elif defined(SC26_LOCAL_ILU)
    HYPRE_CALL(HYPRE_ILUDestroy(solver->amg));
#else
    HYPRE_CALL(HYPRE_BoomerAMGDestroy(solver->amg));
#endif
    HYPRE_CALL(HYPRE_IJMatrixDestroy(solver->matrix));
    HYPRE_CALL(HYPRE_IJVectorDestroy(solver->rhs));
    HYPRE_CALL(HYPRE_IJVectorDestroy(solver->solution));
    free(solver->rows);
    free(solver->row_sizes);
    free(solver->counts);
    free(solver->offsets);
    free(solver->local_scale);
    free(solver->scale);
    free(solver->scaled_values);
    free(solver->scaled_rhs);
    HYPRE_CALL(HYPRE_Finalize());
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
void create_iterative_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{
    int n = input->local_n, nnz = input->row_ptr[n];
    if (nnz > INT_MAX/4) {
        fprintf(stderr, "Complex realification exceeds 32-bit local CSR; use more MPI ranks\n");
        MPI_Abort(input->comm, 1);
    }
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
    create_iterative(&solver->real, &solver->expanded);
}

void analyse_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
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
    if (input->local_n) memset(solver->solution, 0, (size_t)2*input->local_n*sizeof(double));
    analyse(&solver->real, &solver->expanded);
    solver->real.analyse_seconds = MPI_Wtime()-started;
}

void preprocess_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{
    (void)input;
    preprocess(&solver->real, &solver->expanded);
}

void iterative_solver_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{
    iterative_solver(&solver->real, &solver->expanded);
    for (int i = 0; i < input->local_n; ++i) {
        input->x[i] = solver->solution[2*i];
        input->x_im[i] = solver->solution[2*i+1];
    }
}

void destroy_iterative_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{
    (void)input;
    destroy_iterative(&solver->real, &solver->expanded);
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

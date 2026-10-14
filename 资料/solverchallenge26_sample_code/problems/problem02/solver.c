/* SolverChallenge26 problem 02 solver implementation. */
#include "solver.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef DIRECT_SOLVER
void preprocess(struct MySolver* solver, const struct SC26_SolverInput* input)
{
    /* add the code */
}

void direct_solver(struct MySolver* solver, const struct SC26_SolverInput* input)
{
    /* add the code */
}

void solve(struct MySolver* solver, const struct SC26_SolverInput* input)
{
    /* add the code */
}

void preprocess_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{
    /* add the code */
}

void direct_solver_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{
    /* add the code */
}

void solve_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{
    /* add the code */
}
#endif

#ifdef ITERATIVE_SOLVER
#ifdef MPI_USE
#define HYPRE_CALL(call) do { \
    HYPRE_Int code = (call); \
    if (code) { \
        fprintf(stderr, "%s failed: HYPRE error %d\n", #call, (int)code); \
        MPI_Abort(input->comm, code); \
    } \
} while (0)

void analyse(struct MySolver* solver, const struct SC26_SolverInput* input)
{
    double started = MPI_Wtime();
    HYPRE_CALL(HYPRE_Initialize());
#ifdef HYPRE_USING_HIP
    HYPRE_CALL(HYPRE_SetMemoryLocation(HYPRE_MEMORY_HOST));
    HYPRE_CALL(HYPRE_DeviceInitialize());
    HYPRE_CALL(HYPRE_PrintDeviceInfo());
    HYPRE_CALL(HYPRE_MemoryPrintUsage(input->comm, 1, "T2_HIP_ANALYSE", -1));
#endif
    solver->tolerance = 1e-7;
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
    HYPRE_CALL(HYPRE_IJMatrixInitialize(solver->matrix));
    HYPRE_CALL(HYPRE_IJMatrixSetValues(solver->matrix, input->local_n,
        solver->row_sizes, solver->rows, input->col_idx, input->val));
    HYPRE_CALL(HYPRE_IJMatrixAssemble(solver->matrix));
    HYPRE_CALL(HYPRE_IJVectorCreate(input->comm, lower, upper, &solver->rhs));
    HYPRE_CALL(HYPRE_IJVectorSetObjectType(solver->rhs, HYPRE_PARCSR));
    HYPRE_CALL(HYPRE_IJVectorInitialize(solver->rhs));
    const char *project_constant = getenv("SC26_PROJECT_CONSTANT");
    double *projected_rhs = NULL;
    if (!project_constant || atoi(project_constant)) {
        long double local_sum = 0, global_sum;
        for (int i = 0; i < input->local_n; ++i) local_sum += (long double)input->b[i];
        MPI_Allreduce(&local_sum, &global_sum, 1, MPI_LONG_DOUBLE, MPI_SUM, input->comm);
        long double mean = global_sum / input->global_n;
        projected_rhs = malloc((size_t)input->local_n * sizeof(*projected_rhs));
        if (input->local_n && !projected_rhs) MPI_Abort(input->comm, 1);
        for (int i = 0; i < input->local_n; ++i)
            projected_rhs[i] = (double)((long double)input->b[i] - mean);
        if (input->row_begin == 0)
            printf("T2_RHS_PROJECTION mean=%.18Le\n", mean);
    }
    HYPRE_CALL(HYPRE_IJVectorSetValues(solver->rhs, input->local_n, solver->rows,
        projected_rhs ? projected_rhs : input->b));
    free(projected_rhs);
    HYPRE_CALL(HYPRE_IJVectorAssemble(solver->rhs));
    HYPRE_CALL(HYPRE_IJVectorCreate(input->comm, lower, upper, &solver->solution));
    HYPRE_CALL(HYPRE_IJVectorSetObjectType(solver->solution, HYPRE_PARCSR));
    HYPRE_CALL(HYPRE_IJVectorInitialize(solver->solution));
    HYPRE_CALL(HYPRE_IJVectorSetValues(solver->solution, input->local_n, solver->rows, input->x));
    HYPRE_CALL(HYPRE_IJVectorAssemble(solver->solution));

#ifdef HYPRE_USING_HIP
    HYPRE_CALL(HYPRE_IJMatrixMigrate(solver->matrix, HYPRE_MEMORY_DEVICE));
    HYPRE_CALL(HYPRE_IJVectorMigrate(solver->rhs, HYPRE_MEMORY_DEVICE));
    HYPRE_CALL(HYPRE_IJVectorMigrate(solver->solution, HYPRE_MEMORY_DEVICE));
    HYPRE_CALL(HYPRE_SetMemoryLocation(HYPRE_MEMORY_DEVICE));
    HYPRE_CALL(HYPRE_SetExecutionPolicy(HYPRE_EXEC_DEVICE));
    HYPRE_MemoryLocation location;
    HYPRE_ExecutionPolicy policy;
    HYPRE_CALL(HYPRE_GetMemoryLocation(&location));
    HYPRE_CALL(HYPRE_GetExecutionPolicy(&policy));
    printf("T2_HIP_POLICY memory_device=%d execution_device=%d\n",
           location == HYPRE_MEMORY_DEVICE, policy == HYPRE_EXEC_DEVICE);
#endif
    HYPRE_CALL(HYPRE_IJMatrixGetObject(solver->matrix, (void **)&solver->par_matrix));
    HYPRE_CALL(HYPRE_IJVectorGetObject(solver->rhs, (void **)&solver->par_rhs));
    HYPRE_CALL(HYPRE_IJVectorGetObject(solver->solution, (void **)&solver->par_solution));

    HYPRE_CALL(HYPRE_BoomerAMGCreate(&solver->amg));
#ifdef HYPRE_USING_HIP
    HYPRE_CALL(HYPRE_BoomerAMGSetCoarsenType(solver->amg, 8));
    HYPRE_CALL(HYPRE_BoomerAMGSetRAP2(solver->amg, 1));
    HYPRE_CALL(HYPRE_BoomerAMGSetKeepTranspose(solver->amg, 1));
#else
    HYPRE_CALL(HYPRE_BoomerAMGSetCoarsenType(solver->amg, 10));
#endif
    HYPRE_CALL(HYPRE_BoomerAMGSetInterpType(solver->amg, 6));
    HYPRE_CALL(HYPRE_BoomerAMGSetPMaxElmts(solver->amg, 4));
    HYPRE_CALL(HYPRE_BoomerAMGSetStrongThreshold(solver->amg, 0.25));
    HYPRE_CALL(HYPRE_BoomerAMGSetRelaxType(solver->amg, 6));
    /* Pressure has a constant nullspace; keep the coarse solve iterative. */
    HYPRE_CALL(HYPRE_BoomerAMGSetCycleRelaxType(solver->amg, 6, 3));
    HYPRE_CALL(HYPRE_BoomerAMGSetNumSweeps(solver->amg, 1));
    HYPRE_CALL(HYPRE_BoomerAMGSetTol(solver->amg, 0));
    HYPRE_CALL(HYPRE_BoomerAMGSetMaxIter(solver->amg, 1));
    HYPRE_CALL(HYPRE_ParCSRGMRESCreate(input->comm, &solver->gmres));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetKDim(solver->gmres, 50));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetMaxIter(solver->gmres, 1000));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetTol(solver->gmres, solver->tolerance));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetAbsoluteTol(solver->gmres, 0));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetLogging(solver->gmres, 1));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetPrintLevel(solver->gmres, 2));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetPrecond(solver->gmres,
        HYPRE_BoomerAMGSolve, HYPRE_BoomerAMGSetup, solver->amg));
    HYPRE_CALL(HYPRE_ParCSRGMRESSetup(solver->gmres,
        solver->par_matrix, solver->par_rhs, solver->par_solution));
#ifdef HYPRE_USING_HIP
    HYPRE_CALL(HYPRE_MemoryPrintUsage(input->comm, 1, "T2_HIP_SETUP", -1));
#endif
    solver->preprocess_seconds = MPI_Wtime() - started;
}

void iterative_solver(struct MySolver* solver, const struct SC26_SolverInput* input)
{
    double started = MPI_Wtime();
    HYPRE_CALL(HYPRE_ParCSRGMRESSolve(solver->gmres,
        solver->par_matrix, solver->par_rhs, solver->par_solution));
#ifdef HYPRE_USING_HIP
    HYPRE_CALL(HYPRE_MemoryPrintUsage(input->comm, 1, "T2_HIP_SOLVE", -1));
    HYPRE_CALL(HYPRE_IJVectorMigrate(solver->solution, HYPRE_MEMORY_HOST));
#endif
    HYPRE_CALL(HYPRE_IJVectorGetValues(solver->solution, input->local_n, solver->rows, input->x));
    HYPRE_Int iterations;
    HYPRE_Real residual;
    HYPRE_CALL(HYPRE_ParCSRGMRESGetNumIterations(solver->gmres, &iterations));
    HYPRE_CALL(HYPRE_ParCSRGMRESGetFinalRelativeResidualNorm(solver->gmres, &residual));
    if (!isfinite(residual) || residual > solver->tolerance) {
        fprintf(stderr, "T2 GMRES did not converge: residual=%.12e tolerance=%.12e\n",
                residual, solver->tolerance);
        MPI_Abort(input->comm, 1);
    }
    HYPRE_CALL(HYPRE_ParCSRGMRESDestroy(solver->gmres));
    HYPRE_CALL(HYPRE_BoomerAMGDestroy(solver->amg));
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
        printf("T2_GMRES iterations=%d relative_residual=%.12e rtol=%.1e\n",
               (int)iterations, residual, solver->tolerance);
        printf("T2_PHASE_SECONDS analyse=%.6f preprocess=%.6f solve_cleanup=%.6f\n",
               maximum[0], maximum[1], maximum[2]);
        fflush(stdout);
    }
}
#else
void analyse(struct MySolver* solver, const struct SC26_SolverInput* input)
{
    (void)solver; (void)input;
    fprintf(stderr, "T2 HYPRE baseline requires the MPI_iterative_solver target\n");
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

void analyse_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{
    (void)solver; (void)input;
    fprintf(stderr, "T2 HYPRE baseline supports real systems only\n");
    exit(EXIT_FAILURE);
}

void preprocess_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{
    /* add the code */
}

void iterative_solver_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)
{
    /* add the code */
}
#endif

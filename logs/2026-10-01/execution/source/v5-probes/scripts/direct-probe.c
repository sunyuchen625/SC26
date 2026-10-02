#include "solver.c"
#include "solverchallenge26/residual_check.h"
#include "solverchallenge26/system_loader.h"

int main(int argc, char **argv)
{
    if (argc != 3) return 2;
    MPI_Init(&argc, &argv);
    int m, n, nnz, symmetric;
    int *row_ptr, *col_idx;
    double *values, *imaginary_values, *rhs, *imaginary_rhs;
    if (load_linear_system(argv[1], argv[2], 0, 0, &m, &n, &nnz, &symmetric,
            &row_ptr, &col_idx, &values, &imaginary_values, &rhs, &imaginary_rhs))
        MPI_Abort(MPI_COMM_WORLD, 1);
    double *solution = calloc((size_t)n, sizeof(*solution));
    if (!solution) MPI_Abort(MPI_COMM_WORLD, 1);
    struct SC26_SolverInput input = {
        .global_n = n, .local_n = n, .row_begin = 0,
        .row_ptr = row_ptr, .col_idx = col_idx, .val = values,
        .b = rhs, .x = solution, .comm = MPI_COMM_WORLD
    };
    struct MySolver solver;
    preprocess(&solver, &input);
#if SC26_PROBLEM_NUMBER == 3
    direct_solver(&solver, &input);
    long double rhs_squared = 0;
    for (int i = 0; i < n; ++i) rhs_squared += (long double)rhs[i]*rhs[i];
    for (int steps = 0; steps <= 8; ++steps) {
        /* Each solve starts from b; the budget exposes PARDISO's refinement trace. */
        solver.direct.parameters[7] = -steps;
        memset(solution, 0, (size_t)n*sizeof(*solution));
        pardiso_phase(&solver.direct, &input, 33);
        long double absolute_ax_inf = 0;
        double x_inf = 0;
        for (int i = 0; i < n; ++i) {
            x_inf = fmax(x_inf, fabs(solution[i]));
            long double row_sum = 0;
            for (int k = row_ptr[i]; k < row_ptr[i+1]; ++k)
                row_sum += fabsl((long double)values[k]*solution[col_idx[k]]);
            absolute_ax_inf = fmaxl(absolute_ax_inf, row_sum);
        }
        printf("T3_REFINEMENT_BUDGET requested=%d performed=%lld x_inf=%.12e absolute_ax_inf=%.12Le rhs_norm2=%.12Le absolute_ax_inf_over_rhs_norm2=%.12Le\n",
               steps, (long long)solver.direct.parameters[6], x_inf,
               absolute_ax_inf, sqrtl(rhs_squared), absolute_ax_inf/sqrtl(rhs_squared));
        check_correctness_q_d2q(n, row_ptr, col_idx, values, solution, rhs);
        fflush(stdout);
    }
#endif
    pardiso_phase(&solver.direct, &input, -1);
    free(solution); free(row_ptr); free(col_idx); free(values); free(rhs);
    free(imaginary_values); free(imaginary_rhs);
    MPI_Finalize();
    return 0;
}

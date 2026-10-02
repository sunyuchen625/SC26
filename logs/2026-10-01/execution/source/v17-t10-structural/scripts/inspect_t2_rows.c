#include "solverchallenge26/system_loader.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
    if (argc != 3) return 1;
    int m, n, nnz, symmetric, *rp, *ci;
    double *a, *ai, *b, *bi;
    if (load_linear_system(argv[1], argv[2], 0, 0, &m, &n, &nnz,
            &symmetric, &rp, &ci, &a, &ai, &b, &bi)) return 1;
    long double *column_sums = calloc((size_t)n, sizeof(*column_sums));
    if (!column_sums) return 1;
    long double max_ratio = 0, max_sum = 0, row_norm2 = 0, col_norm2 = 0;
    long double rhs_sum = 0, rhs_norm2 = 0, total_sum = 0;
    int notable = 0, max_row = -1;
    for (int i = 0; i < n; ++i) {
        long double sum = 0, diagonal = 0;
        for (int k = rp[i]; k < rp[i + 1]; ++k) {
            sum += (long double)a[k];
            column_sums[ci[k]] += (long double)a[k];
            if (ci[k] == i) diagonal = a[k];
        }
        long double ratio = fabsl(sum / diagonal);
        if (ratio > max_ratio) { max_ratio = ratio; max_row = i; }
        if (fabsl(sum) > max_sum) max_sum = fabsl(sum);
        if (ratio > 1e-12L) {
            if (notable < 20)
                printf("ROW row=%d diagonal=%.18Le row_sum=%.18Le ratio=%.18Le b=%.18e\n",
                       i, diagonal, sum, ratio, b[i]);
            ++notable;
        }
        row_norm2 += sum * sum;
        total_sum += sum;
        rhs_sum += (long double)b[i];
        rhs_norm2 += (long double)b[i] * b[i];
    }
    for (int i = 0; i < n; ++i) col_norm2 += column_sums[i] * column_sums[i];
    printf("n=%d nnz=%d notable_rows=%d max_row=%d max_row_sum_ratio=%.18Le\n", n, nnz, notable, max_row, max_ratio);
    printf("max_abs_row_sum=%.18Le norm_A_ones=%.18Le norm_AT_ones=%.18Le sum_A=%.18Le\n",
           max_sum, sqrtl(row_norm2), sqrtl(col_norm2), total_sum);
    printf("sum_b=%.18Le norm_b=%.18Le constant_rhs_projection_relative=%.18Le\n",
           rhs_sum, sqrtl(rhs_norm2), fabsl(rhs_sum) / sqrtl(n * rhs_norm2));
    free(column_sums); free(rp); free(ci); free(a); free(ai); free(b); free(bi);
    return 0;
}

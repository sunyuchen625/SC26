#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <quadmath.h>
#include "solverchallenge26/system_loader.h"
#include "solverchallenge26/diagnostics.h"

int main(int argc, char **argv) {
    int m, n, nnz, sym, *ptr, *col;
    double *val, *imag, *b, *b_im;
    if (load_linear_system(argv[1], argv[2], 0, 0, &m, &n, &nnz, &sym, &ptr, &col, &val, &imag, &b, &b_im)) return 1;
    __float128 *colsum = calloc(n, sizeof(__float128));
    __float128 bsum = 0, bnorm2 = 0, a1_norm2 = 0, at1_norm2 = 0, a_frob2 = 0;
    double max_rowsum = 0, min_diag = 1e300, max_diag = 0;
    int zero_diag = 0, sym_mismatch = 0;
    for (int i = 0; i < n; ++i) {
        __float128 rs = 0;
        double d = 0;
        for (int k = ptr[i]; k < ptr[i+1]; ++k) {
            rs += val[k];
            colsum[col[k]] += val[k];
            a_frob2 += (__float128)val[k]*val[k];
            if (col[k] == i) d = val[k];
        }
        if (d == 0) zero_diag++;
        if (fabs(d) < min_diag) min_diag = fabs(d);
        if (fabs(d) > max_diag) max_diag = fabs(d);
        double ars = fabsq(rs);
        if (ars > max_rowsum) max_rowsum = ars;
        a1_norm2 += rs * rs;
        bsum += b[i];
        bnorm2 += (__float128)b[i]*b[i];
    }
    double max_colsum = 0;
    for (int j = 0; j < n; ++j) {
        at1_norm2 += colsum[j]*colsum[j];
        double acs = fabsq(colsum[j]);
        if (acs > max_colsum) max_colsum = acs;
    }
    printf("m=%d n=%d nnz=%d sym=%d zero_diag=%d min_diag=%.6e max_diag=%.6e\n",
           m, n, nnz, sym, zero_diag, min_diag, max_diag);
    printf("||A||_F=%.6e ||A*1||_2=%.6e max|A*1|=%.6e ||A^T*1||_2=%.6e max|A^T*1|=%.6e\n",
           (double)sqrtq(a_frob2), (double)sqrtq(a1_norm2), max_rowsum, (double)sqrtq(at1_norm2), max_colsum);
    printf("||b||_2=%.12e sum(b)=%.12e mean(b)=%.12e |sum(b)|/(sqrt(n)*||b||_2)=%.12e\n",
           (double)sqrtq(bnorm2), (double)bsum, (double)(bsum/n), (double)(fabsq(bsum)/(sqrtq((__float128)n)*sqrtq(bnorm2))));
    return 0;
}

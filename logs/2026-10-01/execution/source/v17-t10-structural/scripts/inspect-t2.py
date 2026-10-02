"""Read PETSc metadata and report deterministic sampled coefficient statistics."""
import array
from collections import Counter
import itertools
import json
import math
import struct
import sys

with open(sys.argv[1], "rb") as f:
    class_id, n, columns, nnz = struct.unpack(">4i", f.read(16))
    assert class_id == 1211216 and n == columns
    counts = array.array("i")
    counts.fromfile(f, n)
    if sys.byteorder == "little":
        counts.byteswap()
    offsets = array.array("q", itertools.chain([0], itertools.accumulate(counts)))
    assert offsets[-1] == nnz
    col_idx, values = array.array("i"), array.array("d")
    col_idx.fromfile(f, nnz)
    values.fromfile(f, nnz)
    if sys.byteorder == "little":
        col_idx.byteswap()
        values.byteswap()
    diagonal, row_sums, differences = [], [], []
    offdiag_positive = offdiag_total = 0
    sample_rows = sorted({k * (n - 1) // 4095 for k in range(4096)})
    for i in sample_rows:
        row_sum = 0.0
        for k in range(offsets[i], offsets[i + 1]):
            j, value = col_idx[k], values[k]
            row_sum += value
            if i == j:
                diagonal.append(value)
            else:
                offdiag_total += 1
                offdiag_positive += value > 0
                transpose = 0.0
                for t in range(offsets[j], offsets[j + 1]):
                    if col_idx[t] == i:
                        transpose = values[t]
                        break
                differences.append(abs(value - transpose))
        row_sums.append(row_sum)
    with open(sys.argv[2], "rb") as rhs_file:
        rhs_class, rhs_n = struct.unpack(">2i", rhs_file.read(8))
        assert rhs_class == 1211214 and rhs_n == n
        rhs = array.array("d")
        rhs.fromfile(rhs_file, n)
        if sys.byteorder == "little":
            rhs.byteswap()
    rhs_sum = math.fsum(rhs)
    rhs_norm = math.sqrt(math.fsum(value * value for value in rhs))
    print(json.dumps({
        "n": n, "nnz": nnz, "matrix_bytes": f.tell(),
        "row_nnz_histogram": dict(sorted(Counter(counts).items())),
        "sample_rows": len(sample_rows),
        "sample_diagonal_range": [min(diagonal), max(diagonal)],
        "sample_row_sum_range": [min(row_sums), max(row_sums)],
        "sample_positive_offdiagonals": offdiag_positive,
        "sample_offdiagonals": offdiag_total,
        "sample_max_abs_Aij_minus_Aji": max(differences),
        "rhs_sum": rhs_sum, "rhs_norm2": rhs_norm,
        "constant_rhs_projection_relative": abs(rhs_sum) / (math.sqrt(n) * rhs_norm),
    }, indent=2))

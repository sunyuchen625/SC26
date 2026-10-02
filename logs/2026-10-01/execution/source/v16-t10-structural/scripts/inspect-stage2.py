"""Inspect PETSc storage and sampled field couplings on a compute node."""
import array
from collections import Counter
import itertools
import json
import math
from pathlib import Path
import struct
import sys

problem = sys.argv[1]
base = Path('/data/home/maorz/SolverChallenge26-TenProblems') / f'solverchallenge26_{problem}'
path = base / f'solverchallenge26_{problem}_A.dat'
components = 2 if problem in ('08', '10') else 1
block = {'05': 4, '07': 3, '08': 15, '10': 1}[problem]
with path.open('rb') as f:
    class_id, n, columns, nnz = struct.unpack('>4i', f.read(16))
    assert class_id == 1211216 and n == columns
    counts = array.array('i')
    counts.fromfile(f, n)
    if sys.byteorder == 'little':
        counts.byteswap()
    offsets = array.array('q', itertools.chain([0], itertools.accumulate(counts)))
    assert offsets[-1] == nnz
    indices, values = array.array('i'), array.array('d')
    indices.fromfile(f, nnz)
    values.fromfile(f, components*nnz)
    if sys.byteorder == 'little':
        indices.byteswap()
        values.byteswap()
    assert f.tell() == path.stat().st_size
rows = sorted({k*(n-1)//4095 for k in range(4096)})
fields = [{'rows': 0, 'missing_diagonal': 0, 'zero_diagonal': 0,
           'diagonal_abs_min': float('inf'), 'diagonal_abs_max': 0.0,
           'row_abs_max': 0.0, 'couplings': [0]*block} for _ in range(block)]
column_offsets = Counter()
for i in rows:
    item = fields[i % block]
    item['rows'] += 1
    diagonal = None
    for k in range(offsets[i], offsets[i+1]):
        j = indices[k]
        value = complex(values[2*k], values[2*k+1]) if components == 2 else values[k]
        if i == j:
            diagonal = value
        item['row_abs_max'] = max(item['row_abs_max'], abs(value))
        item['couplings'][j % block] += 1
        column_offsets[j-i] += 1
    item['missing_diagonal'] += int(diagonal is None)
    if diagonal is not None:
        absolute = abs(diagonal)
        item['zero_diagonal'] += int(absolute == 0)
        item['diagonal_abs_min'] = min(item['diagonal_abs_min'], absolute)
        item['diagonal_abs_max'] = max(item['diagonal_abs_max'], absolute)
for item in fields:
    if not math.isfinite(item['diagonal_abs_min']):
        item['diagonal_abs_min'] = None
rhs_stats = []
for rhs_path in sorted(base.glob('*_b*.dat')):
    with rhs_path.open('rb') as f:
        rhs_class, rhs_n = struct.unpack('>2i', f.read(8))
        assert rhs_class == 1211214 and rhs_n == n
        rhs = array.array('d')
        rhs.fromfile(f, components*n)
        if sys.byteorder == 'little':
            rhs.byteswap()
        assert f.tell() == rhs_path.stat().st_size
        max_abs = max(math.hypot(rhs[2*i], rhs[2*i+1]) for i in range(n)) if components == 2 else max(map(abs, rhs))
        rhs_stats.append({'file': rhs_path.name, 'norm2': math.sqrt(math.fsum(v*v for v in rhs)),
                          'max_abs': max_abs})
print(json.dumps({'problem': problem, 'n': n, 'nnz': nnz, 'complex': components == 2,
                  'matrix_bytes': path.stat().st_size, 'sample_rows': len(rows),
                  'field_block_size': block, 'field_stats': fields,
                  'row_nnz_histogram': dict(sorted(Counter(counts).items())),
                  'sample_common_column_offsets': column_offsets.most_common(30),
                  'rhs': rhs_stats}, indent=2))

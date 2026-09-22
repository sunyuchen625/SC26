"""A nonsymmetric complex system with a known complex solution."""
from pathlib import Path
import struct

root = Path(__file__).resolve().parent / 'small_systems'
root.mkdir(exist_ok=True)
nx, ny, nz = 11, 7, 5
n = nx*ny*nz
solution = [complex(i % 7-3, i % 5-2) for i in range(n)]
counts, columns, values, rhs = [], [], [], []
for i in range(n):
    entries = {i: 7+0.5j}
    for coordinate, extent, stride in zip((i % nx, i//nx % ny, i//(nx*ny)), (nx, ny, nz), (1, nx, nx*ny)):
        if coordinate > 0:
            entries[i-stride] = -1.2+0.2j
        if coordinate+1 < extent:
            entries[i+stride] = -0.8-0.3j
    entries = sorted((j, v * 2.0**(i % 9-4) * 2.0**(j % 9-4)) for j, v in entries.items())
    counts.append(len(entries))
    columns.extend(j for j, _ in entries)
    values.extend(v for _, v in entries)
    rhs.append(sum(v*solution[j] for j, v in entries))
with (root/'complex_A.dat').open('wb') as f:
    f.write(struct.pack('>4i', 1211216, n, n, len(values)))
    f.write(struct.pack('>%di' % n, *counts))
    f.write(struct.pack('>%di' % len(columns), *columns))
    f.write(struct.pack('>%dd' % (2*len(values)), *(part for v in values for part in (v.real, v.imag))))
with (root/'complex_b.dat').open('wb') as f:
    f.write(struct.pack('>2i', 1211214, n))
    f.write(struct.pack('>%dd' % (2*n), *(part for v in rhs for part in (v.real, v.imag))))
(root/'complex_x.txt').write_text(''.join(f'{v.real} {v.imag}\n' for v in solution))
print(f'complex: n={n} nnz={len(values)}')

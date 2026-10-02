"""Coupled velocity/pressure and pressure/component systems with known solutions."""
from pathlib import Path
import struct

root = Path(__file__).resolve().parent / 'small_systems'
root.mkdir(exist_ok=True)
for problem, block, pressure in [('05', 4, 3), ('07', 3, 0)]:
    nodes = 97
    n = nodes*block
    solution = [i % 7-3 for i in range(n)]
    counts, columns, values, rhs = [], [], [], []
    for i in range(n):
        node, field = divmod(i, block)
        diagonal = 0.12 if field == pressure else 4.0
        neighbor = -0.02 if field == pressure else -1.0
        entries = {i: diagonal}
        for other in (node-1, node+1):
            if 0 <= other < nodes:
                entries[other*block+field] = neighbor
        for other in range(block):
            if other != field:
                entries[node*block+other] = -0.1 if field == pressure else 0.1
        entries = sorted(entries.items())
        counts.append(len(entries))
        columns.extend(j for j, _ in entries)
        values.extend(v for _, v in entries)
        rhs.append(sum(v*solution[j] for j, v in entries))
    name = f'fields{problem}'
    with (root/f'{name}_A.dat').open('wb') as f:
        f.write(struct.pack('>4i', 1211216, n, n, len(values)))
        f.write(struct.pack(f'>{n}i', *counts))
        f.write(struct.pack(f'>{len(columns)}i', *columns))
        f.write(struct.pack(f'>{len(values)}d', *values))
    with (root/f'{name}_b.dat').open('wb') as f:
        f.write(struct.pack('>2i', 1211214, n))
        f.write(struct.pack(f'>{n}d', *rhs))
    (root/f'{name}_x.txt').write_text(''.join(f'{v}\n' for v in solution))
    print(f'{name}: n={n} nnz={len(values)}')

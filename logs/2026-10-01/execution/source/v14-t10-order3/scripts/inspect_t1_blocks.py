import array
from collections import Counter
import itertools
import json
import struct
import sys

with open(sys.argv[1], 'rb') as f:
    class_id, n, columns, nnz = struct.unpack('>4i', f.read(16))
    counts, indices, values = array.array('i'), array.array('i'), array.array('d')
    counts.fromfile(f, n)
    indices.fromfile(f, nnz)
    values.fromfile(f, nnz)
for a in (counts, indices, values):
    if sys.byteorder == 'little':
        a.byteswap()
offsets = array.array('q', itertools.chain([0], itertools.accumulate(counts)))
shifts = Counter(indices[k]-i for i in range(0, n, max(1, n//4096)) for k in range(offsets[i], offsets[i+1]))
rows = {i: [(indices[k], values[k]) for k in range(offsets[i], offsets[i+1])] for i in (0, 1, 2, n//3, n//2, n-1)}
print(json.dumps({'common_column_offsets': shifts.most_common(25), 'rows': rows}, indent=2))

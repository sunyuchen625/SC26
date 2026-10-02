"""Generate PETSc binary systems with known solutions and uneven MPI row splits."""
from pathlib import Path
import struct

root = Path(__file__).resolve().parent / "small_systems"
root.mkdir(exist_ok=True)
nx, ny, nz = 11, 7, 5
n = nx * ny * nz
solution = [float(i % 7 - 3) for i in range(n)]

for name, backward, forward in [("poisson", -1.0, -1.0), ("nonsymmetric", -1.2, -0.8), ("neumann", -1.0, -1.0), ("scaled", -1.2, -0.8)]:
    rows, columns, values, rhs = [], [], [], []
    for i in range(n):
        coordinates = (i % nx, (i // nx) % ny, i // (nx * ny))
        entries = {i: 6.0}
        for coordinate, extent, stride in zip(coordinates, (nx, ny, nz), (1, nx, nx * ny)):
            if coordinate > 0:
                entries[i - stride] = backward
            if coordinate + 1 < extent:
                entries[i + stride] = forward
        if name == "neumann":
            entries[i] = float(len(entries) - 1)
        if name == "scaled":
            entries = {j: v * 2.0**(i % 9-4) * 2.0**(j % 9-4) for j, v in entries.items()}
        entries = sorted(entries.items())
        rows.append(len(entries))
        columns.extend(j for j, _ in entries)
        values.extend(value for _, value in entries)
        rhs.append(sum(value * solution[j] for j, value in entries))
    with (root / (name + "_A.dat")).open("wb") as f:
        f.write(struct.pack(">4i", 1211216, n, n, len(values)))
        f.write(struct.pack(">%di" % n, *rows))
        f.write(struct.pack(">%di" % len(columns), *columns))
        f.write(struct.pack(">%dd" % len(values), *values))
    with (root / (name + "_b.dat")).open("wb") as f:
        f.write(struct.pack(">2i", 1211214, n))
        f.write(struct.pack(">%dd" % n, *rhs))
    (root / (name + "_x.txt")).write_text("\n".join(map(str, solution)) + "\n")
    print("%s: n=%d nnz=%d" % (name, n, len(values)))

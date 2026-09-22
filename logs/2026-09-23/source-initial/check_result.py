"""Require five completed solves and an official float128 residual below the target."""
import cmath
import math
from pathlib import Path
import re
import sys

log = Path(sys.argv[1]).read_text()
threshold = float(sys.argv[2])
matches = re.findall(r"Q-Check(?: complex)? \|\| b - Ax \|\| 2 / \|\| b \|\| 2 =\s+(\S+)", log)
assert len(matches) == 1, "Expected one official float128 relative residual"
residual = float(matches[0])
assert math.isfinite(residual) and residual < threshold, (residual, threshold)
assert len(re.findall(r"T\d+_GMRES iterations=", log)) == 5, "Expected five independent solves"
if len(sys.argv) >= 5:
    stored = Path(sys.argv[3]).read_text().splitlines()
    expected = [complex(*map(float, value.split())) for value in Path(sys.argv[4]).read_text().splitlines()]
    actual = [complex(*map(float, value.split())) for value in stored[1:]]
    assert int(stored[0]) == len(expected) == len(actual), "Wrong solution length"
    assert all(cmath.isfinite(value) for value in actual), "Non-finite solution"
    difference = [x - y for x, y in zip(actual, expected)]
    shift = 0.0
    if len(sys.argv) == 6 and sys.argv[5] == "constant-nullspace":
        shift = math.fsum(value.real for value in difference) / len(difference)
    error = max(abs(value - shift) for value in difference)
    assert error <= 1e-6, error
    print("KNOWN_SOLUTION_PASS max_abs_error=%.12e" % error)
print("OFFICIAL_RESIDUAL_PASS relative_residual=%.12e threshold=%.1e" % (residual, threshold))

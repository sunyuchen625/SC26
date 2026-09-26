"""Require five completed solves and an official float128 residual below the target."""
import argparse
import cmath
import math
from pathlib import Path
import re
parser = argparse.ArgumentParser()
parser.add_argument("log")
parser.add_argument("threshold", type=float)
parser.add_argument("solution", nargs="?")
parser.add_argument("expected", nargs="?")
parser.add_argument("nullspace", nargs="?", choices=["constant-nullspace"])
parser.add_argument("--metric", choices=["relative", "max"], default="relative")
args = parser.parse_args()
log = Path(args.log).read_text()
threshold = args.threshold
metric = r"MAX\s+" if args.metric == "max" else r"2 / \|\| b \|\| 2 "
matches = re.findall(r"Q-Check(?: complex)? \|\| b - Ax \|\| " + metric + r"=\s+(\S+)", log)
assert len(matches) == 1, "Expected one official float128 residual for " + args.metric
residual = float(matches[0])
assert math.isfinite(residual) and residual < threshold, (residual, threshold)
assert len(re.findall(r"T\d+_(?:GMRES iterations=|PARDISO_DONE refinements=)", log)) == 5, "Expected five independent solves"
if args.solution:
    stored = Path(args.solution).read_text().splitlines()
    expected = [complex(*map(float, value.split())) for value in Path(args.expected).read_text().splitlines()]
    actual = [complex(*map(float, value.split())) for value in stored[1:]]
    assert int(stored[0]) == len(expected) == len(actual), "Wrong solution length"
    assert all(cmath.isfinite(value) for value in actual), "Non-finite solution"
    difference = [x - y for x, y in zip(actual, expected)]
    shift = 0.0
    if args.nullspace == "constant-nullspace":
        shift = math.fsum(value.real for value in difference) / len(difference)
    error = max(abs(value - shift) for value in difference)
    assert error <= 1e-6, error
    print("KNOWN_SOLUTION_PASS max_abs_error=%.12e" % error)
print("OFFICIAL_RESIDUAL_PASS %s_residual=%.12e threshold=%.1e" % (args.metric, residual, threshold))

"""Check completed solves and the official float128 residual."""
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
parser.add_argument("--formal", action="store_true", help="Check the 5+5 competition protocol")
args = parser.parse_args()
log = Path(args.log).read_text()
threshold = args.threshold
metric = r"MAX\s+" if args.metric == "max" else r"2 / \|\| b \|\| 2 "
matches = re.findall(r"Q-Check(?: complex)? \|\| b - Ax \|\| " + metric + r"=\s+(\S+)", log)
assert len(matches) == 1, "Expected one official float128 residual for " + args.metric
residual = float(matches[0])
assert math.isfinite(residual) and residual < threshold, (residual, threshold)
solves = re.findall(r"T\d+_(GMRES iterations=|PARDISO_DONE refinements=)", log)
if args.formal:
    assert len(solves) == 10, "Expected ten independent solves"
    rounds = re.findall(r"^CHECK round (\d+) (warmup|formal) time : (\S+) s$", log, re.M)
    assert [(int(i), phase) for i, phase, _ in rounds] == [
        (i, "warmup" if i <= 5 else "formal") for i in range(1, 11)
    ], "Expected five warmups followed by five formal rounds"
    assert all(math.isfinite(float(t)) and float(t) >= 0 for _, _, t in rounds)
    total, = re.findall(r"^CHECK formal total time : (\S+) s$", log, re.M)
    mean, = re.findall(r"^CHECK end to end time :\s+(\S+) ms$", log, re.M)
    memory, = re.findall(r"^Total memory usage:\s+(\S+) MB$", log, re.M)
    assert math.isfinite(float(memory)) and float(memory) > 0
    assert float(total) > 0 and math.isclose(float(mean), float(total) * 200, abs_tol=1e-6)
    if solves[0] == "PARDISO_DONE refinements=":
        for stage in ("ANALYSE", "FACTOR"):
            assert len(re.findall(r"T\d+_PARDISO_" + stage + " seconds=", log)) == 10, stage
    print(f"FORMAL_5PLUS5_PASS total_s={total} mean_ms={mean} memory_MiB={memory}")
else:
    assert len(solves) == 5, "Expected five independent solves"
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

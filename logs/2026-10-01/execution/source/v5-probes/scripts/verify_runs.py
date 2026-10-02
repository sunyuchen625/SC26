"""Check archived runs with the existing numerical checker and report execution evidence."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import statistics
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument("manifest", type=Path)
args = parser.parse_args()
manifest = json.loads(args.manifest.read_text())
root = args.manifest.parent
checker = Path(__file__).resolve().parents[1] / "tests/check_result.py"
results = []
for row in manifest["results"]:
    run = root / row["run"]
    log = (run / "solver.log").read_text()
    metric = "max" if row["problem"] == "08" else "relative"
    numerical = subprocess.run([sys.executable, str(checker), str(run / "solver.log"),
        str(row["threshold"]), "--metric", metric], capture_output=True, text=True)
    phases = re.findall(r"PHASE_SECONDS analyse=(\S+) (factor|preprocess)=(\S+) solve_cleanup=(\S+)", log)
    time_files = sorted(run.glob("*.time"))
    times = [p.read_text() for p in time_files]
    exits = [int(re.search(r"Exit status: (\d+)", value)[1]) for value in times]
    peak_bytes = sum(int(re.search(r"Maximum resident set size \(kbytes\): (\d+)", value)[1])*1024 for value in times)
    pivots = list(map(int, re.findall(r"perturbed_pivots=(\d+)", log)))
    convergence = list(map(int, re.findall(r"converged=(\d+)", log)))
    configs = re.findall(r"PARDISO_CONFIG .* scaling=(\d+) matching=(\d+)", log)
    job_complete = row["job_state"][:2] == ["COMPLETED", "0:0"]
    memory_pass = peak_bytes < 100_000_000_000 if row["problem"] == "09" else \
                  peak_bytes <= 9_000_000_000 if row["problem"] == "01" else True
    process_exit = int((run / "process.exit").read_text()) if (run / "process.exit").exists() else None
    execution_pass = len(times) == row["ranks"] and exits == [0]*row["ranks"] and \
                     process_exit in (None, 0) and len(phases) == 5 and memory_pass and job_complete
    provenance = None
    if "source_manifest" in row:
        batch = (root / row["batch_log"]).read_text()
        source = root / row["source_manifest"]
        source_verified = hashlib.sha256(source.read_bytes()).hexdigest() in batch and \
            all(line.split("  ", 1)[1]+": OK" in batch for line in source.read_text().splitlines())
        cache_verified = hashlib.sha256((root / row["cmake_cache"]).read_bytes()).hexdigest() == row["cache_sha256"]
        provenance = source_verified and cache_verified and row["binary_sha256"] in batch and row["cache_sha256"] in batch
        execution_pass = execution_pass and provenance
    residual = float(re.findall(r"Q-Check(?: complex)? \|\| b - Ax \|\| " +
        (r"MAX\s+" if metric == "max" else r"2 / \|\| b \|\| 2 ") + r"=\s+(\S+)", log)[0])
    engineering_pass = None
    if "engineering_threshold" in row:
        engineering_pass = residual <= row["engineering_threshold"] and convergence == [1]*5
    result = {
        "job": row["job"], "problem": row["problem"], "rhs": row.get("rhs"),
        "metric": metric, "original_float128_residual_after_fifth_solve": residual,
        "numerical_pass": numerical.returncode == 0,
        "checker_output": numerical.stdout.strip(), "checker_error": numerical.stderr.strip(),
        "job_state": row["job_state"], "job_complete": job_complete,
        "process_exit": process_exit, "rank_process_exits": exits,
        "sum_full_process_peak_bytes": peak_bytes, "memory_pass": memory_pass,
        "framework_memory_MiB": list(map(float, re.findall(r"Total memory usage:\s+(\S+) MB", log))),
        "phase_count": len(phases), "phase_means_seconds": [statistics.mean(float(p[i]) for p in phases) for i in (0, 2, 3)],
        "framework_mean_seconds": float(re.search(r"CHECK end to end time :\s+(\S+)", log)[1]),
        "perturbed_pivots": pivots, "internal_convergence": convergence,
        "analysis_scaling_matching": configs, "provenance_verified": provenance,
        "execution_pass": execution_pass, "engineering_pass": engineering_pass,
        "accepted": numerical.returncode == 0 and execution_pass and engineering_pass is not False,
    }
    results.append(result)
for problem, expected in manifest.get("expected_rhs", {}).items():
    actual = sorted(r["rhs"] for r in results if r["problem"] == problem)
    assert actual == sorted(expected), (problem, actual, expected)
print(json.dumps({"results": results,
    "boundaries": "Original float128 check follows solve five; rank peaks are summed and need not coincide. Pivots and internal convergence are separate diagnostics. Acceptance here does not establish official eligibility."}, indent=2))
sys.exit(0 if all(row["accepted"] for row in results) else 1)

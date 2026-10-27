"""Offline evidence replay; never builds a solver or submits a compute job.

Keep verify_runs.py unchanged because it is part of the frozen provenance.
Check the fixed CPU/GPU archive scope, process records, accounting and candidate identities.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import statistics
import subprocess
import sys
import tarfile


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check(condition, message):
    if not condition:
        raise ValueError(message)


def candidate_check(archive, manifest, prefix, expected_hash):
    check(sha(archive) == expected_hash, "Candidate archive SHA256 mismatch")
    with tarfile.open(archive) as tf:
        check(tf.extractfile(prefix + "source-sha256.txt").read() == manifest.read_bytes(),
              "Candidate/source manifest mismatch")
        entries = (manifest).read_text(encoding="utf-8-sig").splitlines()
        for line in entries:
            digest, name = line.split("  ", 1)
            data = tf.extractfile(prefix + name).read()
            check(hashlib.sha256(data).hexdigest() == digest, "Source mismatch: " + name)
    return {"archive_sha256": sha(archive), "source_entries_verified": len(entries),
            "source_manifest_sha256": sha(manifest)}


def strict_files(run, ranks):
    expected = {"process.time"} if ranks == 1 else {f"rank-{i}.time" for i in range(ranks)}
    check({p.name for p in run.glob("*.time")} == expected, f"Wrong rank time files: {run}")
    check((run / "process.exit").read_text(encoding="utf-8-sig").strip() == "0", f"Missing/nonzero process.exit: {run}")
    for name in expected:
        value = (run / name).read_text(encoding="utf-8-sig")
        check(re.findall(r"Exit status: (\d+)", value) == ["0"], "Bad rank exit: " + name)
        rss = re.findall(r"Maximum resident set size \(kbytes\): (\d+)", value)
        check(len(rss) == 1 and int(rss[0]) > 0, "Invalid RSS: " + name)


def replay(root, manifest):
    proc = subprocess.run([sys.executable, str(root / "scripts/verify_runs.py"), str(manifest)],
                          capture_output=True, text=True, encoding="utf-8")
    check(proc.returncode == 0, "Frozen verifier failed: " + proc.stderr + proc.stdout[-1500:])
    return json.loads(proc.stdout)


def audit(root):
    base = root / "logs/reproduce-scq-20261025"
    gpu = base / "gpu-repro-966565-scq"
    manifest = json.loads((base / "reproduction-runs.json").read_text(encoding="utf-8-sig"))
    check([(r["job"], r["problem"]) for r in manifest["results"]] ==
          [(9275742, "02"), (9275743, "07"), (9275744, "09"), (9275745, "05")],
          "CPU coverage changed")
    cpu_accounting = (base / "logs/reproduction-sacct.log").read_text(encoding="utf-8-sig")
    for row in manifest["results"]:
        strict_files(base / row["run"], row["ranks"])
        lines = [line.split() for line in cpu_accounting.splitlines()
                 if line.split() and line.split()[0] == str(row["job"])]
        check(len(lines) == 1 and lines[0][2:6] == row["job_state"],
              "CPU scheduler record mismatch")
        check((base / row["batch_log"]).is_file(), "Missing batch log")
        check((base / row["batch_log"]).with_suffix(".err").is_file(), "Missing batch stderr")
    cpu = replay(root, base / "reproduction-runs.json")
    check(cpu == json.loads((base / "logs/verify_runs_report.json").read_text(encoding="utf-8-sig")),
          "Archived CPU JSON differs from raw replay")
    cpu_package = candidate_check(root / "deliverables/SC26_CPU_candidate_6b7f675.tar.gz",
        base / "source-sha256.txt", "SC26_CPU_candidate_6b7f675/",
        "dae96e3fa5c8dc4cf8d66469b34797a84a0f3d741d0f8f4d8b4884f16206a111")
    gpu_package = candidate_check(root / "deliverables/SC26_T2_HIP_preparation_20261023.tar.gz",
        gpu / "source-sha256.txt", "",
        "f9482721a702b88d4e1b5e87957f59a8391215eb1938a8599bfc055e1e1c1e3a")
    batch = (gpu / "sc26_t2_hip_scq-966565.out").read_text(encoding="utf-8-sig")
    accounting = (gpu / "gpu-repro-966565-accounting.log").read_text(encoding="utf-8-sig")
    records = [line.split("|") for line in accounting.splitlines() if line.startswith("966565|")]
    check(len(records) == 1 and records[0][5:7] == ["COMPLETED", "0:0"], "GPU scheduler failed")
    check("OPERATOR=scq JOB=966565 NODE=f11r1n20" in batch, "GPU operator/node mismatch")
    check("SC26_GPU_REPRODUCTION_COMPLETE JOB=966565" in batch, "Missing GPU completion receipt")
    check((gpu / "sc26_t2_hip_scq-966565.err").is_file(), "Missing GPU batch stderr")
    # Receipt entries lacking local bytes (binary) remain remote hash receipts, not rehashed binaries.
    receipt = []
    receipt_lines = (gpu / "build-receipt-966565.sha256").read_text(encoding="utf-8-sig").splitlines()
    expected_receipts = {"build-and-run-scq.sbatch", "source-sha256.txt", "parent-commit.txt",
        "src/problems/problem02/solver.c", "src/apps/MPI_iterative_solver.c",
        "build/CMakeCache.txt", "build/bin/MPI_iterative_solver"}
    check(len(receipt_lines) == len(expected_receipts) and
          {line.split("  ", 1)[1] for line in receipt_lines} == expected_receipts,
          "GPU build receipt coverage changed")
    with tarfile.open(root / "deliverables/SC26_T2_HIP_preparation_20261023.tar.gz") as tf:
        for line in receipt_lines:
            digest, name = line.split("  ", 1)
            if (gpu / name).is_file():
                check(sha(gpu / name) == digest, "GPU receipt mismatch: " + name)
                method = "local_file_hash"
            elif name.startswith("src/"):
                check(hashlib.sha256(tf.extractfile(name).read()).hexdigest() == digest,
                      "GPU candidate receipt mismatch: " + name)
                method = "candidate_member_hash"
            else:
                check(digest + "  " + name in batch, "Missing remote binary receipt")
                method = "remote_batch_receipt_only"
            receipt.append({"path": name, "sha256": digest, "method": method})
    gpu_manifest = json.loads((gpu / "reproduction-runs.json").read_text(encoding="utf-8-sig"))
    check([r["run"] for r in gpu_manifest["results"]] ==
          ["runs-966565/full"] + [f"runs-966565/small/{s}" for s in ("poisson", "nonsymmetric", "neumann")],
          "GPU coverage changed")
    check([(row["problem"], row["rhs"], row["ranks"], row["threads"], row["threshold"])
           for row in gpu_manifest["results"]] ==
          [("02", "01", 1, 1, 1e-6)] +
          [("02", case, 1, 1, 1e-10) for case in ("poisson", "nonsymmetric", "neumann")],
          "GPU numerical coverage or threshold changed")
    for row in gpu_manifest["results"]:
        check(row["job"] == 966565 and row["job_state"] ==
              [records[0][5], records[0][6], records[0][7], records[0][10]], "GPU manifest accounting mismatch")
        run = gpu / row["run"]
        strict_files(run, 1)
        check((run / "solver.err").is_file() and (run / "solver.err").stat().st_size == 0,
              "Nonempty/missing GPU solver stderr")
    gpu_replay = replay(root, gpu / "reproduction-runs.json")
    full = (gpu / "runs-966565/full/solver.log").read_text(encoding="utf-8-sig")
    rounds = re.findall(r"^CHECK round (\d+) time : (\S+) s$", full, re.M)
    check([r[0] for r in rounds] == ["1", "2", "3", "4", "5"], "Missing GPU round timings")
    values = [float(r[1]) for r in rounds]
    check(all(math.isfinite(v) and v > 0 for v in values), "Invalid GPU timing")
    check(abs(statistics.mean(values) - gpu_replay["results"][0]["framework_mean_seconds"]) < 2e-6,
          "GPU round mean differs from framework mean")
    check(len(re.findall(r"^T2_HIP_POLICY memory_device=1 execution_device=1$", full, re.M)) == 5,
          "GPU execution policy missing")
    gmres = re.findall(r"^T2_GMRES iterations=(\d+) relative_residual=(\S+) rtol=(\S+)$", full, re.M)
    check(len(gmres) == 5 and all(int(i) > 0 and 0 <= float(r) < float(t) == 1e-7
          for i, r, t in gmres), "GPU convergence/default tolerance missing")
    check(full.count("T2_PREP_CALL_SECONDS ") == 5 and full.count("T2_RHS_PROJECTION ") == 5,
          "GPU preparation/projection records missing")
    build_batch = (base / "logs/sc26_remediation_build-9275741.out").read_text(encoding="utf-8-sig")
    check(build_batch.count("KNOWN_SOLUTION_PASS ") == 24, "CPU known-solution receipt count mismatch")
    check(batch.count("KNOWN_SOLUTION_PASS ") == 3, "GPU known-solution receipt count mismatch")
    lx2 = ["logs/2026-10-14/plan-execution/lx2-environment-verification.json",
           "logs/2026-10-21/plan-execution/lx2-readiness.json",
           "logs/2026-10-23/resource-optimization/lx2-readiness-20261023.json",
           "logs/2026-10-24/lx2-environment/lx2-readiness-user-transcription.json"]
    for name in lx2:
        json.loads((root / name).read_text(encoding="utf-8-sig"))
    historical_path = gpu / "sc26_t2_hip_scq-966318.out"
    historical = (historical_path).read_text(encoding="utf-8-sig")
    historical_check = subprocess.run([sys.executable, str(root / "tests/check_result.py"),
        str(historical_path), "1e-6"], capture_output=True, text=True, encoding="utf-8")
    check(historical_check.returncode == 0, "GPU 966318 archived stdout numerical check failed")
    historical_records = [line.split("|") for line in (gpu / "gpu-repro-966318-accounting.log").read_text(encoding="utf-8-sig").splitlines()
                          if line.startswith("966318|")]
    check(len(historical_records) == 1 and historical_records[0][5:7] == ["COMPLETED", "0:0"],
          "GPU 966318 scheduler record mismatch")
    check("SC26_T2_HIP_FULL_COMPLETE" in historical and
          re.findall(r"Exit status: (\d+)", historical) == ["0"], "GPU 966318 completion/exit missing")
    historical_result = {
        "job": 966318, "evidence_scope": "archived_stdout_and_scheduler_receipts",
        "numerical_log_check_pass": True, "checker_output": historical_check.stdout.strip(),
        "framework_mean_seconds": float(re.search(r"CHECK end to end time :\s+(\S+)", historical)[1]),
        "original_float128_relative_residual": float(re.search(r"Q-Check \|\| b - Ax \|\| 2 / \|\| b \|\| 2 =\s+(\S+)", historical)[1]),
        "full_process_peak_bytes_from_stdout": int(re.search(r"Maximum resident set size \(kbytes\): (\d+)", historical)[1]) * 1024,
        "job_state": historical_records[0][5:7],
        "source_manifest_sha256_receipt": re.search(r"^([0-9a-f]{64})  source-sha256.txt$", historical, re.M)[1],
        "same_source_manifest_as_966565": False,
        "standalone_run_archive_replayed": False,
        "boundary": "Reported source manifest differs from 966565; retain separately, not a matched repeat or complete standalone run archive."
    }
    check(historical_result["source_manifest_sha256_receipt"] != sha(gpu / "source-sha256.txt"),
          "Historical source distinction changed")
    return {
        "evidence_scope": "scq CPU jobs 9275741-9275745 and GPU job 966565; historical 966318 separately",
        "mode": "offline_archived_evidence_replay_no_compute",
        "cpu": cpu, "gpu": gpu_replay, "cpu_candidate": cpu_package, "gpu_candidate": gpu_package,
        "cpu_raw_time_file_count": sum(len(list((base / r["run"]).glob("*.time"))) for r in manifest["results"]),
        "cpu_known_solution_receipts": 24, "gpu_known_solution_receipts": 3,
        "gpu_build_receipt_checks": receipt, "gpu_round_seconds": values,
        "gpu_round_mean_seconds": statistics.mean(values),
        "gpu_sampled_device_used_GiB_max": max(float(v) for v in re.findall(r"Used/Total VRAM: \((\S+) /", full)),
        "gpu_device_memory_scope": "Sampled device-wide usage, not per-process peak allocation",
        "lx2_environment_record_paths": lx2,
        "lx2_latest_user_transcription": json.loads((root / lx2[-1]).read_text(encoding="utf-8-sig")),
        "gpu_historical_966318": historical_result,
        "gpu_known_solution_status": "Three on-node checks passed (batch receipts); answer vectors intentionally excluded at packaging per user; elementwise replay unavailable locally, not a failed validation",
        "archive_replay_pass": True,
        "boundary": "Checks validate supplied logs and hash linkages, not authenticity, fresh numerical execution, or formal eligibility. Source/binary identities are separate from official acceptance."
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    try:
        report = audit(root)
    except (OSError, ValueError, KeyError, TypeError, tarfile.TarError) as exc:
        print(json.dumps({"archive_replay_pass": False, "error": str(exc)}, ensure_ascii=False))
        return 1
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"archive_replay_pass": True, "cpu_runs": 4, "gpu_runs": 4,
                      "cpu_time_files": report["cpu_raw_time_file_count"]}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())

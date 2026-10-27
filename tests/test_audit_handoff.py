"""Regression checks for false acceptance of incomplete or inconsistent archives."""
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("audit_handoff", ROOT / "scripts/audit_handoff.py")
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


class ArchiveAuditTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.root = Path(cls.tmp.name)
        shutil.copytree(ROOT / "logs/reproduce-scq-20261025", cls.root / "logs/reproduce-scq-20261025")
        for name in ["scripts/verify_runs.py", "tests/check_result.py",
                     "deliverables/SC26_CPU_candidate_6b7f675.tar.gz",
                     "deliverables/SC26_T2_HIP_preparation_20261023.tar.gz"]:
            dest = cls.root / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, dest)
        for name in ["logs/2026-10-14/plan-execution/lx2-environment-verification.json",
                     "logs/2026-10-21/plan-execution/lx2-readiness.json",
                     "logs/2026-10-23/resource-optimization/lx2-readiness-20261023.json",
                     "logs/2026-10-24/lx2-environment/lx2-readiness-user-transcription.json"]:
            dest = cls.root / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, dest)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def reject_mutation(self, name, transform):
        path = self.root / name
        original = path.read_bytes()
        try:
            replacement = transform(original)
            if replacement is None:
                path.unlink()
            else:
                path.write_bytes(replacement)
            with self.assertRaises((ValueError, OSError)):
                audit.audit(self.root)
        finally:
            path.write_bytes(original)

    def test_complete_archive_replays(self):
        result = audit.audit(self.root)
        self.assertTrue(result["archive_replay_pass"])
        self.assertEqual(result["cpu_raw_time_file_count"], 129)
        self.assertAlmostEqual(result["gpu_round_mean_seconds"], 3.9021979702)

    def test_missing_launcher_exit_is_rejected(self):
        self.reject_mutation("logs/reproduce-scq-20261025/runs/t02-9275742/rhs-01/process.exit", lambda _: None)

    def test_missing_rank_time_is_rejected(self):
        self.reject_mutation("logs/reproduce-scq-20261025/runs/t05-9275745/rhs-01/rank-95.time", lambda _: None)

    def test_scheduler_failure_is_rejected(self):
        self.reject_mutation("logs/reproduce-scq-20261025/logs/reproduction-sacct.log",
                             lambda b: b.replace(b"COMPLETED", b"FAILED"))

    def test_inconsistent_gpu_round_timing_is_rejected(self):
        self.reject_mutation("logs/reproduce-scq-20261025/gpu-repro-966565-scq/runs-966565/full/solver.log",
                             lambda b: b.replace(b"4.040780419", b"1.040780419"))

    def test_changed_build_cache_is_rejected(self):
        self.reject_mutation("logs/reproduce-scq-20261025/gpu-repro-966565-scq/build/CMakeCache.txt",
                             lambda b: b + b"\n# changed\n")


    def test_relaxed_gpu_threshold_is_rejected(self):
        def relax(value):
            manifest = json.loads(value)
            manifest["results"][0]["threshold"] = 1e-3
            return json.dumps(manifest).encode()
        self.reject_mutation("logs/reproduce-scq-20261025/gpu-repro-966565-scq/reproduction-runs.json", relax)

    def test_truncated_build_receipt_is_rejected(self):
        self.reject_mutation("logs/reproduce-scq-20261025/gpu-repro-966565-scq/build-receipt-966565.sha256",
                             lambda value: value.splitlines(keepends=True)[0])

if __name__ == "__main__":
    unittest.main()

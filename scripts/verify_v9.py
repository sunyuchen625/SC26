"""Independent verification script for SolverChallenge26 v9 package and report."""
import argparse
from collections import defaultdict
from decimal import Decimal
from hashlib import sha256
from io import BytesIO
from pathlib import Path
import re
import subprocess
import sys
from tempfile import TemporaryDirectory
from zipfile import ZipFile

from docx import Document

MIB_TO_GB = Decimal('0.001048576')
ROUNDS = [(str(i), 'warmup' if i <= 5 else 'formal') for i in range(1, 11)]
ROUND_RE = r'^CHECK round (\d+) (warmup|formal) time : (\S+) s$'
THRESHOLDS = {
    (1, 'regular'): Decimal('1e-8'),
    (2, 'regular'): Decimal('1e-6'),
    (2, 'high'): Decimal('1e-10'),
    (3, 'regular'): Decimal('1e-8'),
    (4, 'regular'): Decimal('1e-8'),
    (5, 'regular'): Decimal('5e-9'),
    (6, 'regular'): Decimal('1e-10'),
    (7, 'regular'): Decimal('1e-6'),
    (8, 'regular'): Decimal('1e-10'),
    (9, 'regular'): Decimal('1e-10'),
    (10, 'regular'): Decimal('1e-10'),
}
T05_EXTRA_PATHS = (
    '$deps/hypre-2.33.0/src/parcsr_ls/par_mgr_setup.c',
    '$deps/hypre-build/CMakeFiles/HYPRE.dir/flags.make',
)


def parse_job_log(topic: str, job: str, log: str, sacct: str, prefix: str):
    """Parse and validate all RHS measurements in one Slurm job log."""
    m_sacct = re.search(rf'^{re.escape(job)}\|COMPLETED\|0:0\|[^|]+\|[^|]+\|[^|]+\|([^|]+)\|([^\n]+)$', sacct, re.M)
    assert m_sacct, f'{prefix} job {job}: sacct missing COMPLETED 0:0'
    sacct_node = m_sacct.group(1)
    alloc = dict(item.split('=', 1) for item in m_sacct.group(2).split(','))
    assert alloc.get('node') == '1', f'{prefix} job {job}: expected node=1, got {alloc}'

    number = int(topic)
    rhs_records = {}
    configs = []
    for match in re.finditer(
        r'^SC26_RUN problem=(\d\d) rhs=(\d\d) ([^\n]*)\n((?:(?!^SC26_RUN ).)*)',
        log, re.M | re.S,
    ):
        found_topic, rhs, config_str, body = match.groups()
        assert found_topic == topic, (topic, found_topic)
        cfg = dict(item.split('=', 1) for item in config_str.split() if '=' in item)
        assert cfg.get('node') == sacct_node, (job, cfg.get('node'), sacct_node)
        grade = 'high' if cfg.get('grade') == 'high' else 'regular'
        assert (number == 2 and grade == 'high') == prefix.endswith('/高档')

        rounds = re.findall(ROUND_RE, body, re.M)
        assert [(int(i), phase) for i, phase, _ in rounds] == [(i, 'warmup' if i <= 5 else 'formal') for i in range(1, 11)], (topic, rhs, rounds)
        assert all(Decimal(t) > 0 for _, _, t in rounds)

        total, = re.findall(r'^CHECK formal total time : (\S+) s$', body, re.M)
        mean, = re.findall(r'^CHECK end to end time\s*:\s+(\S+) ms$', body, re.M)
        memory_mib, = re.findall(r'^Total memory usage:\s+(\S+) MB$', body, re.M)
        metric = r'MAX' if number == 8 else r'2 / \|\| b \|\| 2'
        residual, = re.findall(rf'^Q-Check(?: complex)? \|\| b - Ax \|\| {metric}\s+=\s+(\S+)$', body, re.M)
        kind = 'max' if number == 8 else 'relative'
        passed, _ = map(Decimal, re.findall(rf'^OFFICIAL_RESIDUAL_PASS {kind}_residual=(\S+) threshold=(\S+)$', body, re.M)[-1])
        assert re.search(r'^FORMAL_5PLUS5_PASS .+$', body, re.M)

        total, mean, memory_mib, residual = map(Decimal, (total, mean, memory_mib, residual))
        assert total > 0 and abs(total * 200 - mean) <= Decimal('0.000001'), (topic, rhs, total, mean)
        gb = memory_mib * MIB_TO_GB
        assert gb > 0
        if number == 1:
            assert gb <= 9, f'T01 exceeded 9 GB: {gb}'
        if number == 9:
            assert gb < 100, f'T09 exceeded 100 GB: {gb}'

        threshold = THRESHOLDS[number, grade]
        assert residual == passed and 0 <= residual < threshold, (topic, rhs, residual, threshold)

        if number == 4:
            assert re.findall(r'^T4_PARDISO_FACTOR .* perturbed_pivots=(\d+)$', body, re.M) == ['0'] * 10
        if number == 10:
            assert len(re.findall(r'^T10_STRUCTURE_MATCH missing_diagonal=1613 rows_moved=3226\b', body, re.M)) == 10

        orderings = re.findall(rf'^T{number}_PARDISO_CONFIG .* ordering=(\d+)\b', body, re.M)
        if orderings:
            assert len(set(orderings)) == 1, (topic, rhs, orderings)
            if orderings[0] == '3':
                assert 'Parallel METIS algorithm at reorder step is turned ON' in body
            elif orderings[0] == '2':
                assert 'METIS algorithm at reorder step is turned ON' in body

        rhs_num = int(rhs)
        assert rhs_num not in rhs_records
        rhs_records[rhs_num] = (mean, gb, residual)
        configs.append((cfg.get('mpi'), cfg.get('threads'), orderings[0] if orderings else None, grade))

    assert rhs_records, f'No SC26_RUN found in {prefix} job {job}'
    assert len(set(configs)) == 1, (prefix, job, configs)
    mpi, threads, ordering, grade = configs[0]
    return {
        'job': job,
        'node': sacct_node,
        'mpi': mpi,
        'threads': threads,
        'ordering': ordering,
        'grade': grade,
        'rhs': rhs_records,
    }


def verify_archive(archive: Path, report: Path | None = None, check_t05_fix: bool = True):
    """Run full audit on archive ZIP and matching DOCX report."""
    records = defaultdict(dict)
    jobs_by_group = defaultdict(list)
    with ZipFile(archive) as z, TemporaryDirectory(prefix='sc26-v9-audit-') as temp:
        assert z.testzip() is None, 'ZIP CRC error'
        names = z.namelist()
        assert len(names) == len(set(names)), 'Duplicate ZIP entries'
        assert {n.split('/')[0] for n in names} == {'比赛报告', '源码及运行脚本', '求解视频'}

        report_bytes = z.read('比赛报告/SC26技术报告.docx')
        if report is not None:
            assert report_bytes == report.read_bytes(), 'Report DOCX differs from ZIP member'

        if check_t05_fix:
            t05_readme = z.read('源码及运行脚本/T05/商业CPU/运行说明.md').decode()
            for p in T05_EXTRA_PATHS:
                assert p in t05_readme, f'Missing T05 doc path {p}'

        manifests = {}
        for name in names:
            if name.endswith('/source-sha256.txt'):
                base = name.rsplit('/', 1)[0]
                raw = z.read(name)
                manifests[base] = (sha256(raw).hexdigest(), raw)
                covered = set()
                for line in raw.decode().splitlines():
                    digest, filename = line.split('  ', 1)
                    member = f'{base}/{filename}'
                    assert sha256(z.read(member)).hexdigest() == digest, (base, filename)
                    covered.add(member)
                # Ensure no stray untracked source/script/test files exist
                for member in names:
                    if not member.startswith(base + '/') or member.endswith('/'):
                        continue
                    rel = member[len(base) + 1:]
                    if rel in ('source-sha256.txt', '运行说明.md', 'official/LICENSE') or rel.startswith(('实测日志/', '高档/', '高档诊断/')):
                        continue
                    assert member in covered, f'Uncovered file in {base}: {rel}'

        assert len(manifests) == 11, f'Expected 11 manifests, got {len(manifests)}'

        expected_videos = set()
        for name in sorted(names):
            if not name.endswith('/slurm.out') or '/实测日志/' not in name:
                continue
            prefix, rest = name.split('/实测日志/', 1)
            job, _ = rest.split('/', 1)
            m_topic = re.search(r'源码及运行脚本/T(\d\d)/商业CPU', prefix)
            assert m_topic, prefix
            topic = m_topic.group(1)
            log = z.read(name).decode()
            sacct = z.read(name.replace('/slurm.out', '/sacct.tsv')).decode()
            info = parse_job_log(topic, job, log, sacct, prefix)
            key = (int(topic), info['grade'])
            for rhs_num, vals in info['rhs'].items():
                assert rhs_num not in records[key], (key, rhs_num)
                records[key][rhs_num] = vals
            jobs_by_group[key].append(info)
            expected_videos.add(f'求解视频/T{topic}_商业CPU_{job}.mp4')

            # Check manifest sha256 appears in slurm.out (for single-job tracks, or latest if T10 split)
            manifest_digest, _ = manifests[prefix]
            if int(topic) != 10:
                assert manifest_digest in log, f'{prefix} job {job}: source-sha256.txt hash not in slurm.out'

        # For T10, at least the jobs using the current source (and all if unified) must match manifest
        t10_manifest_digest, _ = manifests['源码及运行脚本/T10/商业CPU']
        t10_matches = [
            t10_manifest_digest in z.read(f'源码及运行脚本/T10/商业CPU/实测日志/{info["job"]}/slurm.out').decode()
            for info in jobs_by_group[(10, 'regular')]
        ]
        assert any(t10_matches), 'Neither T10 job matches T10 source-sha256.txt'

        video_names = {n for n in names if n.endswith('.mp4')}
        assert video_names == expected_videos and len(video_names) == 12, (video_names, expected_videos)
        for vname in sorted(video_names):
            extracted = z.extract(vname, temp)
            probe = subprocess.check_output(
                ['ffprobe', '-v', 'error', '-select_streams', 'v:0',
                 '-show_entries', 'stream=codec_name,pix_fmt,duration',
                 '-of', 'csv=p=0', extracted],
                text=True,
            ).strip()
            parts = probe.split(',')
            assert len(parts) >= 3 and parts[0] == 'h264' and parts[1] == 'yuv420p', (vname, probe)
            assert float(parts[2]) > 0, (vname, probe)

        doc = Document(BytesIO(report_bytes))
        results = doc.tables[1]
        assert len(records) == 11
        assert sum(map(len, records.values())) == 38
        keys_order = [
            (1, 'regular'), (1, 'regular'), (2, 'regular'), (2, 'high'),
            *((n, 'regular') for n in range(3, 11)),
        ]
        summary_lines = []
        for row, key in enumerate(keys_order, start=1):
            number, grade = key
            group = records[key]
            assert sorted(group) == list(range(1, 11 if number >= 8 else 2))
            mean = sum(r[0] for r in group.values())
            memory = max(r[1] for r in group.values())
            residual = max(r[2] for r in group.values())
            c = results.rows[row].cells
            assert Decimal(c[1].text.splitlines()[0]) == Decimal(f'{mean:.2f}'), (c[0].text, c[1].text, mean)
            assert Decimal(c[5].text.split()[0]) == Decimal(f'{memory:.2f}'), (c[0].text, c[5].text, memory)
            assert c[6].text == '达标'
            # Check platform threads/ranks column
            job_infos = jobs_by_group[key]
            if len({info['threads'] for info in job_infos}) == 1 and len({info['mpi'] for info in job_infos}) == 1:
                mpi, threads = job_infos[0]['mpi'], job_infos[0]['threads']
                expected_plat = f'商业CPU\n{mpi}进程' if int(mpi) > 1 else f'商业CPU\n{threads}线程'
                assert c[4].text == expected_plat, (c[0].text, c[4].text, expected_plat)
            elif number == 10:
                ordered_infos = sorted(job_infos, key=lambda item: min(item['rhs']))
                t10_threads = '/'.join(info['threads'] for info in ordered_infos)
                assert c[4].text == f'商业CPU\n{t10_threads}线程', (c[0].text, c[4].text, t10_threads)
            summary_lines.append(f'{c[0].text} | {len(group)} RHS | {mean:.2f} ms | {memory:.2f} GB | {residual:.6e}')

        breakdown = doc.tables[6]
        for rhs in range(1, 11):
            cells = breakdown.rows[rhs].cells
            assert int(cells[0].text) == rhs
            for offset, number in enumerate((8, 9, 10)):
                mean, _, residual = records[number, 'regular'][rhs]
                assert Decimal(cells[2 * offset + 1].text) == Decimal(f'{mean:.2f}')
                assert Decimal(cells[2 * offset + 2].text) == residual

        # Check all 12 job IDs appear in the report full text
        full_text = '\n'.join(p.text for p in doc.paragraphs)
        for key, infos in jobs_by_group.items():
            for info in infos:
                assert info['job'] in full_text, f'Job {info["job"]} ({key}) missing from report text'

        # Check READMEs contain each job ID, node, video, and ordering=3 docs when used
        for key, infos in jobs_by_group.items():
            number, grade = key
            base = f'源码及运行脚本/T{number:02d}/商业CPU' + ('/高档' if grade == 'high' else '')
            readme_text = z.read(f'{base}/运行说明.md').decode()
            for info in infos:
                assert info['job'] in readme_text, f'Job {info["job"]} missing from {base}/运行说明.md'
                if number in (6, 8, 9, 10):
                    assert info['node'] in readme_text, f'Node {info["node"]} missing from {base}/运行说明.md'
                assert f'T{number:02d}_商业CPU_{info["job"]}.mp4' in readme_text, f'Video missing from {base}/运行说明.md'
            if number in (6, 8, 9, 10) and any(info['ordering'] == '3' for info in infos):
                assert 'SC26_PARDISO_ORDERING=3' in readme_text, f'SC26_PARDISO_ORDERING=3 missing from {base}/运行说明.md'
                assert 'iparm[1] = 3' in readme_text, f'iparm[1] = 3 missing from {base}/运行说明.md'

    size_mb = archive.stat().st_size / (1024 * 1024)
    for line in summary_lines:
        print(line)
    print(f'{archive.name}: 38 benchmark records, 11 source manifests, 12 matching H.264/yuv420p videos, size={archive.stat().st_size} bytes ({size_mb:.2f} MB)')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', type=Path)
    parser.add_argument('report', nargs='?', type=Path)
    parser.add_argument('--skip-t05-check', action='store_true')
    args = parser.parse_args()
    verify_archive(args.archive, args.report, check_t05_fix=not args.skip_t05_check)


if __name__ == '__main__':
    main()

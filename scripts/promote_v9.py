"""Stage v9 promotions, T05 reproducibility doc fix, report updates, and ZIP packaging."""
import argparse
from collections import defaultdict
from copy import copy
from decimal import Decimal
from hashlib import sha256
from io import BytesIO
import json
from pathlib import Path, PurePosixPath
import re
import shlex
import subprocess
import sys
from tarfile import open as taropen
from zipfile import ZIP_DEFLATED, ZipFile

from docx import Document

BASELINE_JOBS = {
    'T06': ('06', '9322169', ('01',), '32', '65G', '00:45:00'),
    'T08': ('08', '9322610', tuple(f'{i:02}' for i in range(1, 11)), '16', '80G', '04:30:00'),
    'T09': ('09', '9322609', tuple(f'{i:02}' for i in range(1, 11)), '16', '95G', '04:30:00'),
    'T10a': ('10', '9322607', tuple(f'{i:02}' for i in range(1, 6)), '32', '210G', '04:30:00'),
    'T10b': ('10', '9322611', tuple(f'{i:02}' for i in range(6, 11)), '32', '210G', '04:30:00'),
}
# Strict v8 summary baselines (ms) to beat
V8_BASELINE_MS = {
    '06': Decimal('50782.06'),
    '08': Decimal('708696.89'),
    '09': Decimal('783227.60'),
    '10': Decimal('2059993.08'),
}
V8_PARTIAL_T10_MS = {
    'T10a': Decimal('1166799.65'),  # sum of RHS 01-05 in 9322607
    'T10b': Decimal('893193.41'),   # sum of RHS 06-10 in 9322611
}
REPORT_MEMBER = '比赛报告/SC26技术报告.docx'
MIB_TO_GB = Decimal('0.001048576')
ROUNDS = [(str(i), 'warmup' if i <= 5 else 'formal') for i in range(1, 11)]
ROUND_RE = r'^CHECK round (\d+) (warmup|formal) time : (\S+) s$'
T05_OLD_BULLET = (
    '- 脚本在本队集群环境使用依赖目录 `/data/home/sunyc/solverchallenge26/deps/`。'
    'HYPRE 安装位于 `hypre/`，GNU time 位于 `gnu-time/time`。'
    '如使用另一套集群安装位置，对应调整批处理脚本中的依赖路径、Slurm 分区和账户。'
)
T05_NEW_BULLET = (
    '- 脚本在本队集群环境使用依赖目录 `/data/home/sunyc/solverchallenge26/deps/`（脚本内记为 `deps`）。'
    'HYPRE 安装位于 `hypre/`，GNU time 位于 `gnu-time/time`；'
    '此外 `scripts/remediation-build.sbatch` 在生成第 5 题 MGR 补丁静态库时还会读取 '
    '`$deps/hypre-2.33.0/src/parcsr_ls/par_mgr_setup.c` 与 `$deps/hypre-build/CMakeFiles/HYPRE.dir/flags.make`。'
    '如使用另一套集群安装位置，对应调整批处理脚本中的依赖路径、Slurm 分区和账户。'
)


def exactly(pattern, content):
    matches = re.findall(pattern, content, re.M)
    assert len(matches) == 1, (pattern, len(matches))
    return matches[0]


def replace_text(paragraph, before, after):
    run, = paragraph.runs
    assert run.text.count(before) == 1, (before, run.text[:120])
    run.text = run.text.replace(before, after)


def fingerprints(log):
    entries = re.findall(r'^([a-f0-9]{64})  (\S+)$', log, re.M)
    result = {Path(path).name: digest for digest, path in entries}
    assert len(result) == len(entries), entries
    return result


def checked_source(path, log):
    with taropen(path) as archive:
        files = {}
        for entry in archive.getmembers():
            if entry.isdir():
                continue
            member = PurePosixPath(entry.name)
            assert entry.isfile() and not member.is_absolute() and '..' not in member.parts
            assert str(member) not in files, member
            files[str(member)] = archive.extractfile(entry).read()
    manifest = files['source-sha256.txt']
    manifest_entries = set()
    for line in manifest.decode().splitlines():
        digest, name = line.split('  ', 1)
        assert sha256(files[name]).hexdigest() == digest, name
        manifest_entries.add(name)
    assert manifest_entries == files.keys() - {'source-sha256.txt'}
    assert f'{sha256(manifest).hexdigest()}  source-sha256.txt' in log
    return files


def parse_measurement(task, output):
    rounds = re.findall(ROUND_RE, output, re.M)
    assert [(i, phase) for i, phase, _ in rounds] == ROUNDS, (task, rounds)
    assert all(Decimal(t) > 0 for _, _, t in rounds)
    total = Decimal(exactly(r'^CHECK formal total time : (\S+) s$', output))
    mean = Decimal(exactly(r'^CHECK end to end time\s*:\s+(\S+) ms$', output))
    gb = Decimal(exactly(r'^Total memory usage:\s+(\S+) MB$', output)) * MIB_TO_GB
    metric = r'MAX' if task == '08' else r'2 / \|\| b \|\| 2'
    residual = Decimal(exactly(
        rf'^Q-Check(?: complex)? \|\| b - Ax \|\| {metric}\s+=\s+(\S+)$',
        output,
    ))
    residual_kind = 'max' if task == '08' else 'relative'
    passed, _ = map(Decimal, re.findall(
        rf'^OFFICIAL_RESIDUAL_PASS {residual_kind}_residual=(\S+) threshold=(\S+)$',
        output, re.M,
    )[-1])
    exactly(r'^FORMAL_5PLUS5_PASS .+$', output)
    assert total > 0 and abs(total * 200 - mean) <= Decimal('0.000001')
    assert gb > 0 and (task != '09' or gb < 100), (task, gb)
    assert residual == passed and 0 <= residual < Decimal('1e-10'), (task, residual)
    return mean, gb, residual


def parse_job_slurm(task, rhs_values, log, accounting, expected_threads=None):
    job, node, allocation = exactly(
        r'^(\d+)\|COMPLETED\|0:0\|[^|]+\|[^|]+\|[^|]+\|([^|]+)\|([^\n]+)$',
        accounting,
    )
    allocated = dict(item.split('=', 1) for item in allocation.split(','))
    assert allocated.get('node') == '1', allocated

    pattern = r'^SC26_RUN problem=(\d\d) rhs=(\d\d) node=(\S+) mpi=(\d+) threads=(\d+)\n'
    parts = re.split(pattern, log, flags=re.M)[1:]
    assert len(parts) == 6 * len(rhs_values), (task, job, rhs_values, len(parts))

    measurements = {}
    ran_threads_set = set()
    for offset, expected_rhs in enumerate(rhs_values):
        problem, rhs, ran_node, ranks, ran_threads, output = parts[offset * 6:offset * 6 + 6]
        assert (problem, rhs, ran_node, ranks) == (task, expected_rhs, node, '1'), (problem, rhs, ran_node, ranks, node)
        ran_threads_set.add(ran_threads)
        measurements[rhs] = parse_measurement(task, output)

    assert len(ran_threads_set) == 1, ran_threads_set
    threads, = ran_threads_set
    if expected_threads is not None:
        assert threads == expected_threads, (threads, expected_threads)
    assert int(allocated['cpu']) >= int(threads), (allocated, threads)

    number = int(task)
    orderings = re.findall(rf'^T{number}_PARDISO_CONFIG .* ordering=(\d+)\b', log, re.M)
    assert len(orderings) == len(rhs_values) and len(set(orderings)) == 1, (task, orderings)
    ordering = orderings[0]
    if ordering == '3':
        assert len(re.findall(r'^Parallel METIS algorithm at reorder step is turned ON$', log, re.M)) == 10 * len(rhs_values)
    elif ordering == '2':
        assert len(re.findall(r'^METIS algorithm at reorder step is turned ON$', log, re.M)) == 10 * len(rhs_values)
    else:
        raise AssertionError(f'Unexpected PARDISO ordering {ordering}')

    pivots = re.findall(rf'^T{number}_PARDISO_FACTOR .* perturbed_pivots=(\d+)$', log, re.M)
    assert len(pivots) == 10 * len(rhs_values), (task, len(pivots))

    if task == '10':
        assert len(re.findall(r'^T10_STRUCTURE_MATCH missing_diagonal=1613 rows_moved=3226\b', log, re.M)) == 10 * len(rhs_values)

    return {
        'job': job,
        'node': node,
        'threads': threads,
        'ordering': ordering,
        'pivots': pivots,
        'measurements': measurements,
    }


def verify_recording(path, job, log):
    with path.open() as stream:
        header = json.loads(next(stream))
        events = [json.loads(line) for line in stream]
    assert header['version'] == 2
    assert all(0 <= left[0] <= right[0] for left, right in zip(events, events[1:]))
    transcript = ''.join(event[2] for event in events if event[1] == 'o').replace('\r', '')
    assert not re.search(r'Reconnected to Slurm|archived remainder|SSH drop', transcript, re.I)

    # Support optional env assignment prefixes before sbatch (e.g. + SC26_PARDISO_ORDERING=3 sbatch ...)
    raw_cmd = exactly(r'^\+ ((?:[A-Z0-9_]+=\S+\s+)*sbatch .+)$', transcript)
    tokens = shlex.split(raw_cmd)
    env_vars = {}
    idx = 0
    while idx < len(tokens) and '=' in tokens[idx] and tokens[idx] != 'sbatch':
        k, v = tokens[idx].split('=', 1)
        env_vars[k] = v
        idx += 1
    assert idx < len(tokens) and tokens[idx] == 'sbatch', tokens
    command = tokens[idx:]

    marker_pattern = r'^(?:SC26_RUN |CHECK round |FORMAL_5PLUS5_PASS |OFFICIAL_RESIDUAL_PASS ).+$'
    markers = re.findall(marker_pattern, log, re.M)
    transcript_markers = re.findall(marker_pattern, transcript, re.M)
    assert transcript_markers[:len(markers)] == markers, (len(transcript_markers), len(markers))
    for extra in transcript_markers[len(markers):]:
        assert extra.startswith(('FORMAL_5PLUS5_PASS ', 'OFFICIAL_RESIDUAL_PASS ')), extra

    submitted = exactly(rf'^(Submitted (?:Slurm|batch) job {re.escape(job)})$', transcript)
    completed = f'Job {job} completed successfully'
    assert transcript.count(submitted) == 1 and transcript.count(completed) == 1
    assert transcript.index(submitted) < transcript.index(markers[0])
    assert transcript.index(markers[-1]) < transcript.index(completed)
    exactly(rf'^.+ JOB {re.escape(job)} RUNNING\|0:0\|.+$', transcript)
    exactly(rf'^{re.escape(job)}\|COMPLETED\|0:0\|.+$', transcript)
    assert fingerprints(log).items() <= fingerprints(transcript).items()
    return command, env_vars


def parse_sbatch_options(command, env_vars, task, expected_rhs):
    """Extract --cpus-per-task, --mem, --time, --exclusive, and ordering env from sbatch command."""
    opts = {}
    i = 1
    script_idx = None
    while i < len(command):
        arg = command[i]
        if not arg.startswith('-'):
            script_idx = i
            break
        if arg == '--exclusive':
            opts['exclusive'] = True
            i += 1
        elif '=' in arg:
            k, v = arg.split('=', 1)
            opts[k] = v
            i += 1
        elif i + 1 < len(command) and not command[i + 1].startswith('-'):
            opts[arg] = command[i + 1]
            i += 2
        else:
            opts[arg] = True
            i += 1
    assert script_idx is not None, command
    assert Path(command[script_idx]).name == 'remediation-baseline.sbatch', command
    assert command[script_idx + 1:] == [task, *expected_rhs], (command, task, expected_rhs)
    assert opts.get('--nodes') == '1' and opts.get('--ntasks') == '1', opts
    threads = opts['--cpus-per-task']
    memory = opts['--mem']
    time_limit = opts['--time']
    exclusive = bool(opts.get('exclusive', False))
    export_opt = opts.get('--export', '')
    ordering_env = env_vars.get('SC26_PARDISO_ORDERING')
    for part in export_opt.split(','):
        if part.startswith('SC26_PARDISO_ORDERING='):
            ordering_env = part.split('=', 1)[1]
    return {
        'threads': threads,
        'memory': memory,
        'time_limit': time_limit,
        'exclusive': exclusive,
        'ordering_env': ordering_env,
    }


def summary(measurements):
    return (
        f'{sum(record[0] for record in measurements.values()):.2f}',
        f'{max(record[1] for record in measurements.values()):.2f}',
        f'{max(record[2] for record in measurements.values()):.6e}',
    )


def find_log_file(directory: Path, primary: str, job: str):
    p = directory / primary
    if p.is_file():
        return p
    alt = directory / primary.replace('.', f'-{job}.')
    assert alt.is_file(), f'Missing {primary} or {alt.name} in {directory}'
    return alt


def find_mp4(directory: Path, explicit_mp4: Path | None):
    if explicit_mp4 is not None:
        assert explicit_mp4.is_file(), explicit_mp4
        return explicit_mp4
    default = directory / 'video.mp4'
    if default.is_file():
        return default
    mp4s = list(directory.glob('*.mp4'))
    assert len(mp4s) == 1, f'Expected 1 mp4 in {directory}, found {mp4s}'
    return mp4s[0]


def verify_mp4(mp4: Path):
    probe = subprocess.check_output(
        ['ffprobe', '-v', 'error', '-select_streams', 'v:0',
         '-show_entries', 'stream=codec_name,pix_fmt,duration',
         '-of', 'csv=p=0', str(mp4)],
        text=True,
    ).strip()
    parts = probe.split(',')
    assert len(parts) >= 3 and parts[0] == 'h264' and parts[1] == 'yuv420p' and float(parts[2]) > 0, (mp4, probe)


def format_platform_paragraph(meta):
    """Build P007 (软硬件平台) cleanly from actual final thread counts."""
    # Single-MPI OpenMP tasks: T01 (16T, HYPRE OpenMP), T03 (16T), T04 (32T), T06, T08, T09, T10a/b
    # Group direct solvers T03, T04, T06, T08, T09, T10 by thread count
    groups = defaultdict(list)
    groups[int(meta['04']['threads'])].append('第 4')
    groups[int(meta['06']['threads'])].append('第 6')
    groups[int(meta['08']['threads'])].append('第 8')
    groups[int(meta['09']['threads'])].append('第 9')
    t10a_t = int(meta['T10a']['threads'])
    t10b_t = int(meta['T10b']['threads'])
    if t10a_t == t10b_t:
        groups[t10a_t].append('第 10')
    else:
        groups[t10a_t].append('第 10 题前半部分（右端 01 至 05）')
        groups[t10b_t].append('第 10 题后半部分（右端 06 至 10）')

    def fmt_items(items):
        # e.g. ['第 4', '第 6'] -> '第 4、6 题' unless item already contains '题'
        if all('题' not in x for x in items):
            nums = '、'.join(x.replace('第 ', '') for x in items)
            return f'第 {nums} 题'
        normalized = [x if '题' in x else f'{x} 题' for x in items]
        return '、'.join(normalized)

    direct_clauses = [
        f'{fmt_items(groups[t])}使用单 MPI 进程配 {t} 个 OpenMP 线程'
        for t in sorted(groups.keys(), reverse=True)
    ]
    direct_str = '，'.join(direct_clauses)
    return (
        '商业 CPU 集群通过 Slurm 调度单节点作业，每节点配备双路 Intel Xeon Platinum 8488C 处理器（共 96 个物理核心）。'
        f'正式作业按题目特征配置并行度：直接法{direct_str}；'
        '第 1 题（HYPRE 启用 OpenMP）与第 3 题采用单进程 16 线程；'
        '第 2 题（高低两档）、第 5 题及第 7 题的迭代求解使用 96 个单线程 MPI 进程。'
    )


def format_ordering_clause(meta):
    """Build iparm[1] clause cleanly for P021."""
    ord3 = []
    ord2 = []
    # Check 3, 4, 6, 8, 9, 10
    for label, name in (('03', '第 3 题'), ('04', '第 4 题'), ('06', '第 6 题'), ('08', '第 8 题'), ('09', '第 9 题')):
        if meta[label]['ordering'] == '3':
            ord3.append(name)
        else:
            ord2.append(name)
    o10a, o10b = meta['T10a']['ordering'], meta['T10b']['ordering']
    if o10a == o10b:
        (ord3 if o10a == '3' else ord2).append('第 10 题')
    else:
        (ord3 if o10a == '3' else ord2).append('第 10 题右端 01 至 05')
        (ord3 if o10b == '3' else ord2).append('第 10 题右端 06 至 10')

    def fmt(names):
        if all(n.endswith('题') for n in names):
            return '第 ' + '、'.join(n[2:-1].strip() for n in names) + ' 题'
        return '、'.join(names)

    if not ord2:
        return '全部启用 OpenMP 并行重排 iparm[1]=3'
    if len(ord3) <= len(ord2):
        s = fmt(ord3)
        sep = ' ' if s[-1].isdigit() else ''
        return f'{s}{sep}并行排序 iparm[1]=3，其余 iparm[1]=2'
    s = fmt(ord2)
    sep = ' ' if s[-1].isdigit() else ''
    return f'{s}{sep}使用 iparm[1]=2，其余并行排序 iparm[1]=3'


def update_report(data, meta, old_values, new_values):
    doc = Document(BytesIO(data))
    table = doc.tables[1]
    breakdown = doc.tables[6]

    # Table 1 updates (rows: T06=8, T08=10, T09=11, T10=12)
    row_map = {'06': 8, '08': 10, '09': 11, '10': 12}
    for task, row in row_map.items():
        old_ms, old_gb, _ = summary(old_values[task])
        ms, gb, _ = summary(new_values[task])
        assert table.cell(row, 0).text == str(int(task))
        replace_text(table.cell(row, 1).paragraphs[0], old_ms, ms)
        replace_text(table.cell(row, 5).paragraphs[0], f'{old_gb} GB', f'{gb} GB')
        if task != '10':
            t = meta[task]['threads']
            old_t = BASELINE_JOBS[f'T{task}'][3]
            replace_text(table.cell(row, 4).paragraphs[0], f'商业CPU\n{old_t}线程', f'商业CPU\n{t}线程')
        else:
            t10a_t, t10b_t = meta['T10a']['threads'], meta['T10b']['threads']
            new_plat = f'商业CPU\n{t10a_t}线程' if t10a_t == t10b_t else f'商业CPU\n{t10a_t}/{t10b_t}线程'
            replace_text(table.cell(row, 4).paragraphs[0], '商业CPU\n32线程', new_plat)

    # Table 6 (表5 多右端明细)
    for task in ('08', '09', '10'):
        time_col = 2 * (int(task) - 8) + 1
        for rhs, (mean, _, residual) in new_values[task].items():
            assert breakdown.cell(int(rhs), 0).text == rhs
            old_mean, _, old_residual = old_values[task][rhs]
            replace_text(breakdown.cell(int(rhs), time_col).paragraphs[0], f'{old_mean:.2f}', f'{mean:.2f}')
            replace_text(breakdown.cell(int(rhs), time_col + 1).paragraphs[0], f'{old_residual:.6e}', f'{residual:.6e}')

    # P007 软硬件平台
    p_plat, = (p for p in doc.paragraphs if p.text.startswith('商业 CPU 集群通过 Slurm 调度单节点作业'))
    run, = p_plat.runs
    run.text = format_platform_paragraph(meta)

    # P014 内存上限实测 (T09)
    old_t9_gb = summary(old_values['09'])[1]
    new_t9_gb = summary(new_values['09'])[1]
    if new_t9_gb != old_t9_gb:
        p_mem, = (p for p in doc.paragraphs if '本队商业 CPU 正式实测分别为 5.32 GB 与' in p.text)
        replace_text(p_mem, f'5.32 GB 与 {old_t9_gb} GB', f'5.32 GB 与 {new_t9_gb} GB')

    # P021 直接求解器 PARDISO 参数
    p_direct, = (p for p in doc.paragraphs if p.text.startswith('第 3、4、6、8、9、10 题均基于 oneMKL PARDISO 求解'))
    replace_text(p_direct, '第 3 题并行排序 iparm[1]=3，其余 iparm[1]=2', format_ordering_clause(meta))

    # P022 T06 / T08 / T09 段落
    t6_ms, _, t6_res = summary(new_values['06'])
    t8_ms, _, t8_res = summary(new_values['08'])
    t9_ms, t9_gb, t9_res = summary(new_values['09'])
    t6_pivots = [int(x) for x in meta['06']['pivots']]
    if all(p == 0 for p in t6_pivots):
        t6_pivot_str = '十轮数值分解无扰动主元'
    elif len(set(t6_pivots)) == 1:
        t6_pivot_str = f'十轮数值分解每轮扰动主元 {t6_pivots[0]} 个'
    else:
        t6_pivot_str = f'十轮数值分解扰动主元 {min(t6_pivots)}–{max(t6_pivots)} 个'
    t6_excl = '，独占节点' if meta['06']['exclusive'] else ''
    t6_clause = (
        f'第 6 题运行于 {meta["06"]["threads"]} 线程（作业 {meta["06"]["job"]}{t6_excl}），'
        f'{t6_pivot_str}，正式均时 {t6_ms} ms，原系统相对残差 {t6_res}。'
    )
    t8_excl = '，独占节点' if meta['08']['exclusive'] else ''
    t9_excl = '，独占节点' if meta['09']['exclusive'] else ''
    if meta['08']['threads'] == meta['09']['threads'] and not t8_excl and not t9_excl:
        t89_head = f'第 8、9 题均以 {meta["08"]["threads"]} 线程跑完全部 10 个右端项（作业 {meta["08"]["job"]}、{meta["09"]["job"]}）：'
    else:
        t89_head = (
            f'第 8 题以 {meta["08"]["threads"]} 线程（作业 {meta["08"]["job"]}{t8_excl}）、'
            f'第 9 题以 {meta["09"]["threads"]} 线程（作业 {meta["09"]["job"]}{t9_excl}）分别跑完全部 10 个右端项：'
        )
    t89_clause = (
        f'{t89_head}'
        f'第 8 题十项均时之和 {t8_ms} ms，最大绝对残差不超过 {t8_res}；'
        f'第 9 题十项均时之和 {t9_ms} ms，最大相对残差不超过 {t9_res}，峰值内存最大 {t9_gb} GB。'
    )
    p_t689, = (p for p in doc.paragraphs if p.text.startswith('第 6 题运行于'))
    run, = p_t689.runs
    run.text = t6_clause + t89_clause

    # P023 T10 段落
    t10_ms, t10_gb, t10_res = summary(new_values['10'])
    t10a_m, t10b_m = meta['T10a'], meta['T10b']
    if t10a_m['threads'] == t10b_m['threads']:
        if t10a_m['exclusive'] and t10b_m['exclusive']:
            excl_suffix = '，均独占节点'
        elif t10a_m['exclusive']:
            excl_suffix = f'，{t10a_m["job"]} 独占节点'
        elif t10b_m['exclusive']:
            excl_suffix = f'，{t10b_m["job"]} 独占节点'
        else:
            excl_suffix = ''
        t10_batch_desc = (
            f'两批 {t10a_m["threads"]} 线程作业（{t10a_m["job"]} 完成右端 01 至 05，'
            f'{t10b_m["job"]} 完成右端 06 至 10{excl_suffix}）'
        )
    else:
        t10a_excl = '独占节点' if t10a_m['exclusive'] else ''
        t10b_excl = '独占节点' if t10b_m['exclusive'] else ''
        t10_batch_desc = (
            f'两批作业（{t10a_m["job"]} 以 {t10a_m["threads"]} 线程{t10a_excl}完成右端 01 至 05，'
            f'{t10b_m["job"]} 以 {t10b_m["threads"]} 线程{t10b_excl}完成右端 06 至 10）'
        )
    p_t10, = (p for p in doc.paragraphs if p.text.startswith('第 10 题采用 64 位 pardiso_64 接口'))
    old_t10_tail = (
        '两批 32 线程作业（9322607 完成右端 01 至 05，9322611 完成右端 06 至 10）测得十项均时之和为 '
        f'{summary(old_values["10"])[0]} ms，最大相对残差 {summary(old_values["10"])[2]}，峰值内存 {summary(old_values["10"])[1]} GB。'
    )
    new_t10_tail = f'{t10_batch_desc}测得十项均时之和为 {t10_ms} ms，最大相对残差 {t10_res}，峰值内存 {t10_gb} GB。'
    replace_text(p_t10, old_t10_tail, new_t10_tail)

    # P048 商业CPU新规实测段落
    p_overall, = (p for p in doc.paragraphs if p.text.startswith('商业 CPU 正式实测中'))
    if t10a_m['threads'] == t10b_m['threads']:
        if t10a_m['node'] == t10b_m['node']:
            t10_overall = f'第 10 题分两批 {t10a_m["threads"]} 线程作业在 {t10a_m["node"]} 节点完成（{t10a_m["job"]} 负责右端 01 至 05，{t10b_m["job"]} 负责右端 06 至 10）'
        else:
            t10_overall = f'第 10 题分两批 {t10a_m["threads"]} 线程作业在 {t10a_m["node"]}（{t10a_m["job"]}，右端 01 至 05）与 {t10b_m["node"]}（{t10b_m["job"]}，右端 06 至 10）节点完成'
    else:
        t10_overall = (
            f'第 10 题分两批作业在 {t10a_m["node"]}（{t10a_m["threads"]} 线程 {t10a_m["job"]}，右端 01 至 05）与 '
            f'{t10b_m["node"]}（{t10b_m["threads"]} 线程 {t10b_m["job"]}，右端 06 至 10）节点完成'
        )
    run, = p_overall.runs
    run.text = (
        '商业 CPU 正式实测中，全部 10 道赛题对应的 12 个 Slurm 作业均完成了 5 次预热与 5 次正式运行并正常退出（0:0）。'
        '按题号顺序，作业编号分别为第 1 题 9322544，第 2 题低档 9322168 与高档 9322595，第 3 题 9322616，'
        f'第 4 至第 7 题依次为 9322608、9322170、{meta["06"]["job"]}、9322171，第 8、9 题为 {meta["08"]["job"]}、{meta["09"]["job"]}；'
        f'{t10_overall}。表 5 列出第 8 至第 10 题共 30 个右端项的正式均时与官方残差，全部低于 1e-10；'
        f'第 9 题十项峰值内存最大为 {t9_gb} GB。'
    )

    return doc


def update_readme(old_text, task, labels, meta, new_values):
    """Regenerate or cleanly update T06/T08/T09/T10 运行说明.md to match exact promoted specs."""
    ms, gb, residual = summary(new_values[task])
    text = old_text

    # 1. Update ordering description if any promoted job in this task used ordering=3
    orderings = {meta[lb]['ordering'] for lb in labels}
    if '3' in orderings:
        if 'METIS 嵌套剖分' in text:
            if orderings == {'3'}:
                text = text.replace(
                    'METIS 嵌套剖分',
                    'OpenMP 并行 METIS 嵌套剖分（`iparm[1] = 3`，通过环境变量 `SC26_PARDISO_ORDERING=3` 启用）',
                    1,
                )
            else:
                text = text.replace(
                    'METIS 嵌套剖分',
                    'METIS 嵌套剖分（部分批处理通过 `SC26_PARDISO_ORDERING=3` 启用 OpenMP 并行排序 `iparm[1] = 3`）',
                    1,
                )
        else:
            anchor = '使用 64 位索引及 pardiso_64。'
            assert anchor in text, f'Unexpected README header in T{task}'
            if orderings == {'3'}:
                note = 'OpenMP 并行 METIS 嵌套剖分（`iparm[1] = 3`，通过环境变量 `SC26_PARDISO_ORDERING=3` 启用）。'
            else:
                note = '默认使用 METIS 嵌套剖分，部分批处理通过 `SC26_PARDISO_ORDERING=3` 启用 OpenMP 并行排序（`iparm[1] = 3`）。'
            text = text.replace(anchor, anchor + note, 1)
        assert 'iparm[1] = 3' in text and 'SC26_PARDISO_ORDERING=3' in text, (task, orderings)

    # 2. Update sbatch snippet in ## 编译与运行
    # Locate the formal sbatch code block between "构建作业达到" and "- 每个右端依次执行"
    start_marker = '构建作业达到 `COMPLETED 0:0` 后'
    end_marker = '- 每个右端依次执行 5 次完整预热和 5 次正式运行。'
    s_idx = text.index(start_marker)
    e_idx = text.index(end_marker)
    block = text[s_idx:e_idx]
    cmd_lines = []
    for lb in labels:
        m = meta[lb]
        rhs_str = ' '.join(BASELINE_JOBS[lb][2])
        excl_flag = ' --exclusive' if m['exclusive'] else ''
        export_flag = ' --export=ALL,SC26_PARDISO_ORDERING=3' if m['ordering'] == '3' else ''
        cmd_lines.append(
            f'job=$(sbatch --parsable --chdir="$PWD" --nodes=1 --ntasks=1{excl_flag}{export_flag} \\\n'
            f'  --cpus-per-task={m["threads"]} --mem={m["memory"]} --time={m["time_limit"]} \\\n'
            f'  scripts/remediation-baseline.sbatch {task} {rhs_str})\n'
            'job=${job%%;*}\n'
            'printf \'%s\\n\' "$job"\n'
            'sacct -j "$job" -P -o JobID,State,ExitCode,Elapsed,NodeList,AllocTRES'
        )
    new_block = (
        '构建作业达到 `COMPLETED 0:0` 后，按以下参数提交正式求解。每个命令启动一个批处理作业。\n\n'
        '```bash\nunset SC26_RTOL SC26_PROJECT_CONSTANT SC26_PARDISO_ORDERING\n'
        + '\n\n'.join(cmd_lines) + '\n```\n\n'
    )
    text = text[:s_idx] + new_block + text[e_idx:]

    # Update check_result.py threshold from 1e-8 -> 1e-10 in snippet
    text = text.replace(' 1e-8 --metric ', ' 1e-10 --metric ')

    # 3. Rewrite ## 对应实测 section cleanly
    sec_idx = text.index('## 对应实测')
    rows = []
    video_bullets = []
    for lb in labels:
        m = meta[lb]
        rhs = BASELINE_JOBS[lb][2]
        rhs_span = rhs[0] if len(rhs) == 1 else f'{rhs[0]}–{rhs[-1]}'
        rows.append(
            f'| {m["job"]} | {m["node"]} | 1 | {m["threads"]} | {m["memory"]} | {m["time_limit"]} | {rhs_span} |'
        )
        notes = []
        if m['exclusive']:
            notes.append('启用 `--exclusive` 独占计算节点')
        if m['ordering'] == '3':
            notes.append('`SC26_PARDISO_ORDERING=3`')
        note_str = f'（{"，".join(notes)}）' if notes else ''
        video_bullets.append(
            f'- `T{task}_商业CPU_{m["job"]}.mp4` 从作业 `{m["job"]}` 提交至验算通过及调度退出连续录制{note_str}。'
            '画面包含每个右端的十轮计时与原系统残差。'
        )
    metric_label = '最大绝对残差的最大值' if task == '08' else '相对二范数残差的最大值'
    if task == '06':
        summary_line = f'正式均时为 {ms} ms，最大官方内存为 {gb} GB，相对二范数残差的最大值为 {residual}。调度记录与程序输出见 `实测日志/`，录像位于包内 `求解视频/`。'
    else:
        summary_line = f'十个右端的正式均时之和为 {ms} ms，最大官方内存为 {gb} GB，{metric_label}为 {residual}。调度记录与程序输出见 `实测日志/`，录像位于包内 `求解视频/`。'

    new_sec = (
        '## 对应实测\n\n'
        '| 作业号 | 节点 | MPI 进程 | 每进程 CPU 线程 | 请求内存 | 时限 | 右端 |\n'
        '| --- | --- | ---: | ---: | ---: | --- | --- |\n'
        + '\n'.join(rows) + '\n\n'
        + summary_line + '\n\n'
        + '\n'.join(video_bullets) + '\n'
    )
    return text[:sec_idx] + new_sec


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base', type=Path, required=True, help='Immutable v8 ZIP archive')
    parser.add_argument('--out', type=Path, required=True, help='Staging output directory')
    parser.add_argument('--promote', action='append', default=[], metavar='LABEL=DIR',
                        help='Optional promoted tracks: T06, T08, T09, T10a, T10b')
    parser.add_argument('--mp4', action='append', default=[], metavar='LABEL=MP4',
                        help='Optional explicit mp4 path for a promoted label')
    parser.add_argument('--version', default='v9')
    args = parser.parse_args()

    promotions = {}
    for pair in args.promote:
        lb, path = pair.split('=', 1)
        assert lb in BASELINE_JOBS and lb not in promotions, pair
        promotions[lb] = Path(path)

    explicit_mp4s = {}
    for pair in args.mp4:
        lb, path = pair.split('=', 1)
        assert lb in promotions, pair
        explicit_mp4s[lb] = Path(path)

    with ZipFile(args.base) as base:
        old_values = defaultdict(dict)
        new_values = defaultdict(dict)
        meta = {
            '03': {'threads': '16', 'ordering': '3'},
            '04': {'threads': '32', 'ordering': '2'},
        }
        add = {}
        remove = set()
        promoted_tasks = set()

        # First load all v8 baseline info for T06, T08, T09, T10a, T10b
        for label, (task, old_job, rhs, threads, memory, time_limit) in BASELINE_JOBS.items():
            case = f'源码及运行脚本/T{task}/商业CPU/'
            old_dir = f'{case}实测日志/{old_job}/'
            old_log = base.read(old_dir + 'slurm.out').decode()
            old_sacct = base.read(old_dir + 'sacct.tsv').decode()
            info = parse_job_slurm(task, rhs, old_log, old_sacct, expected_threads=threads)
            assert info['job'] == old_job
            old_values[task].update(info['measurements'])

            if label not in promotions:
                new_values[task].update(info['measurements'])
                entry = {
                    'job': old_job,
                    'node': info['node'],
                    'threads': threads,
                    'memory': memory,
                    'time_limit': time_limit,
                    'exclusive': False,
                    'ordering': info['ordering'],
                    'pivots': info['pivots'],
                    'source_files': None,
                }
            else:
                promoted_tasks.add(task)
                directory = promotions[label]
                sacct_bytes = (directory / 'sacct.tsv').read_bytes()
                out_path = find_log_file(directory, 'slurm.out', '') if (directory / 'slurm.out').is_file() else next(directory.glob('slurm-*.out'))
                job_guess = out_path.stem.split('-')[-1] if out_path.stem.startswith('slurm-') else ''
                err_path = find_log_file(directory, 'slurm.err', job_guess)
                log_bytes = out_path.read_bytes()
                err_bytes = err_path.read_bytes()
                log_text = log_bytes.decode()

                info = parse_job_slurm(task, rhs, log_text, sacct_bytes.decode())
                job = info['job']
                assert job != old_job and job not in {e[1] for e in BASELINE_JOBS.values()}, job
                assert (directory / 'record.exit').read_text().strip() == '0', label

                command, env_vars = verify_recording(directory / 'recording.cast', job, log_text)
                sbatch_opts = parse_sbatch_options(command, env_vars, task, list(rhs))
                assert sbatch_opts['threads'] == info['threads'], (label, sbatch_opts, info)
                if sbatch_opts['ordering_env'] is not None:
                    assert sbatch_opts['ordering_env'] == info['ordering'], (label, sbatch_opts, info)

                # Verify source provenance
                source_tar = directory / 'source.tar.gz'
                if source_tar.is_file():
                    source_files = checked_source(source_tar, log_text)
                else:
                    # Must match v8 source-sha256.txt
                    v8_manifest = base.read(case + 'source-sha256.txt')
                    assert sha256(v8_manifest).hexdigest() + '  source-sha256.txt' in log_text, (label, 'missing source.tar.gz and hash differs from v8')
                    source_files = None

                # Verify optional CMakeCache.txt & build/smoke logs
                cmake_cache = directory / 'CMakeCache.txt'
                if cmake_cache.is_file():
                    assert sha256(cmake_cache.read_bytes()).hexdigest() in log_text, (label, 'CMakeCache.txt mismatch')
                for sp in [directory / 'smoke.log', directory / 'build-slurm.out', *directory.glob('build-*.out')]:
                    if sp.is_file():
                        assert 'KNOWN_SOLUTION_PASS' in sp.read_text(), (label, sp.name)

                # Verify MP4
                mp4 = find_mp4(directory, explicit_mp4s.get(label))
                verify_mp4(mp4)

                # Verify strict improvement for single-RHS or partial-T10 tracks
                cand_ms = sum(r[0] for r in info['measurements'].values())
                if label in V8_PARTIAL_T10_MS:
                    assert cand_ms < V8_PARTIAL_T10_MS[label], (label, cand_ms, V8_PARTIAL_T10_MS[label])
                else:
                    assert cand_ms < V8_BASELINE_MS[task], (label, cand_ms, V8_BASELINE_MS[task])

                new_values[task].update(info['measurements'])
                entry = {
                    'job': job,
                    'node': info['node'],
                    'threads': info['threads'],
                    'memory': sbatch_opts['memory'],
                    'time_limit': sbatch_opts['time_limit'],
                    'exclusive': sbatch_opts['exclusive'],
                    'ordering': info['ordering'],
                    'pivots': info['pivots'],
                    'source_files': source_files,
                }
                add[f'{case}实测日志/{job}/sacct.tsv'] = sacct_bytes
                add[f'{case}实测日志/{job}/slurm.out'] = log_bytes
                add[f'{case}实测日志/{job}/slurm.err'] = err_bytes
                add[f'求解视频/T{task}_商业CPU_{job}.mp4'] = mp4.read_bytes()
                remove.update(n for n in base.namelist() if n.startswith(old_dir))
                remove.add(f'求解视频/T{task}_商业CPU_{old_job}.mp4')

            if task in ('06', '08', '09'):
                meta[task] = entry
            else:
                meta[label] = entry

        # Verify combined T10 improvement if either T10a or T10b promoted
        if '10' in promoted_tasks:
            t10_total = sum(r[0] for r in new_values['10'].values())
            assert t10_total < V8_BASELINE_MS['10'], (t10_total, V8_BASELINE_MS['10'])

        # Update source files in 源码及运行脚本/Txx/商业CPU/ for promoted tasks
        for task in sorted(promoted_tasks):
            case = f'源码及运行脚本/T{task}/商业CPU/'
            if task != '10':
                src_files = meta[task]['source_files']
            else:
                s10a = meta['T10a']['source_files']
                s10b = meta['T10b']['source_files']
                if s10a is not None and s10b is not None:
                    assert s10a == s10b, 'T10a and T10b used different source trees!'
                    src_files = s10a
                else:
                    src_files = s10a if s10a is not None else s10b
            if src_files is not None:
                for rel, content in src_files.items():
                    add[case + rel] = content

        # Update 运行说明.md for promoted tasks
        task_labels = {'06': ('T06',), '08': ('T08',), '09': ('T09',), '10': ('T10a', 'T10b')}
        for task in sorted(promoted_tasks):
            readme_path = f'源码及运行脚本/T{task}/商业CPU/运行说明.md'
            add[readme_path] = update_readme(
                base.read(readme_path).decode(),
                task,
                task_labels[task],
                {**{lb: meta[lb] for lb in ('T10a', 'T10b')}, 'T06': meta['06'], 'T08': meta['08'], 'T09': meta['09']},
                new_values,
            ).encode()

        # Always apply T05 reproducibility doc fix
        t05_readme_path = '源码及运行脚本/T05/商业CPU/运行说明.md'
        t05_text = base.read(t05_readme_path).decode()
        assert t05_text.count(T05_OLD_BULLET) == 1, 'T05 bullet not found'
        add[t05_readme_path] = t05_text.replace(T05_OLD_BULLET, T05_NEW_BULLET, 1).encode()

        # Update report DOCX
        doc = update_report(base.read(REPORT_MEMBER), meta, old_values, new_values)
        args.out.mkdir(parents=True, exist_ok=True)
        report = args.out / f'SC26技术报告_{args.version}.docx'
        archive = args.out / f'SolverChallenge26_CUDA OOM!_{args.version}.zip'
        assert archive.resolve() != args.base.resolve()
        doc.save(report)
        add[REPORT_MEMBER] = report.read_bytes()

        with ZipFile(archive, 'w', ZIP_DEFLATED, compresslevel=6) as target:
            for item in base.infolist():
                name = item.filename
                if name not in remove and name not in add:
                    target.writestr(copy(item), base.read(item))
            for name, content in sorted(add.items()):
                target.writestr(name, content)

        with ZipFile(archive) as target:
            for name in set(base.namelist()) - remove - add.keys():
                assert target.read(name) == base.read(name), name
            assert not remove.intersection(target.namelist())

    verify_script = Path(__file__).resolve().with_name('verify_v9.py')
    subprocess.run([sys.executable, str(verify_script), str(archive), str(report)], check=True)
    result = {
        'promoted_labels': sorted(promotions.keys()),
        'archive': str(archive),
        'archive_bytes': archive.stat().st_size,
        'report': str(report),
        'summary': {t: summary(new_values[t]) for t in ('06', '08', '09', '10')},
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()

"""Summarize this batch's solver logs and Slurm states on the compute platform."""
import datetime
import json
import math
from pathlib import Path
import re
import subprocess

root = Path('/data/home/sunyc/solverchallenge26')
cases = [(9193128, '05', 'ILU', ['']), (9193138, '05', 'MGR', ['']),
         (9193129, '07', 'ILU', ['']), (9193139, '07', 'MGR', ['']),
         (9193126, '08', 'PARDISO', ['01']),
         (9193141, '08', 'PARDISO', ['02', '03', '04']),
         (9193142, '08', 'PARDISO', ['05', '06', '07']),
         (9193143, '08', 'PARDISO', ['08', '09', '10']),
         (9193127, '10', 'PARDISO32', ['01']),
         (9193140, '10', 'PARDISO64', ['01']),
         (9193147, '10', 'PARDISO64_sorted', ['01'])]
job_ids = [9193122, 9193123, 9193124, 9193132, 9193137, 9193145, 9193146] + [c[0] for c in cases]
sacct = subprocess.check_output(['sacct', '-X', '-n', '-P', '-j', ','.join(map(str, job_ids)),
    '--format=JobID,State,ExitCode,Elapsed,NodeList'], text=True)
states = {row.split('|')[0]: row.split('|')[1:5] for row in sacct.splitlines() if row.strip()}
results = []
for job, problem, method, right_sides in cases:
    for rhs in right_sides:
        path = root/'runs'/('t'+problem+('-direct-' if rhs else '-')+str(job))/(('rhs-'+rhs) if rhs else '1e-12')
        result = {'job': job, 'problem': problem, 'method': method, 'rhs': rhs or None,
                  'job_state': states[str(job)], 'remote_run': str(path),
                  'metric': 'max_absolute' if problem == '08' else 'relative_l2',
                  'threshold': 1e-6 if problem == '07' else 1e-8}
        if (path/'solver.log').exists():
            log = (path/'solver.log').read_text()
            relative = re.findall(r'Q-Check(?: complex)? \|\| b - Ax \|\| 2 / \|\| b \|\| 2 =\s+(\S+)', log)
            maximum = re.findall(r'Q-Check(?: complex)? \|\| b - Ax \|\| MAX\s+=\s+(\S+)', log)
            average = re.findall(r'CHECK end to end time :\s+(\S+)', log)
            done = len(re.findall(r'T\d+_(?:GMRES iterations=|PARDISO_DONE refinements=)', log))
            result['completed_solves'] = done
            result['relative_residual'] = float(relative[0]) if relative else None
            result['max_absolute_residual'] = float(maximum[0]) if maximum else None
            result['five_solve_average_seconds'] = float(average[0]) if average else None
            residual = result['max_absolute_residual'] if problem == '08' else result['relative_residual']
            result['residual_pass'] = (math.isfinite(residual) and residual < result['threshold'] and done == 5) if residual is not None else None
            peaks = [int(re.search(r'Maximum resident set size \(kbytes\): (\d+)', p.read_text())[1])*1024
                     for p in path.glob('*.time') if 'Maximum resident set size' in p.read_text()]
            result['peak_bytes_sum'] = sum(peaks) if len(peaks) == (1 if rhs else 96) else None
            result['iterations'] = list(map(int, re.findall(r'T\d+_GMRES iterations=(\d+)', log)))
        results.append(result)
output = {'recorded_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'results': results}
(root/'runs/stage2-summary.json').write_text(json.dumps(output, indent=2)+'\n')
(root/'runs/stage2-jobs.log').write_text(sacct)
for r in results:
    print(r['job'], r['problem'], r['method'], r['rhs'], r['job_state'][0], r.get('completed_solves'),
          r.get('relative_residual'), r.get('max_absolute_residual'), r.get('five_solve_average_seconds'), r.get('peak_bytes_sum'))

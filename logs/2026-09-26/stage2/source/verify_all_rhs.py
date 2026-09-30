import datetime,json,re,statistics,subprocess,sys
from pathlib import Path
rows=json.loads(Path('runs/stage2-summary.json').read_text())['results']
complete=[r for r in rows if r['problem']=='08' or r['problem']=='10' and r['job_state'][:2]==['COMPLETED','0:0']]
print('Validated UTC:',datetime.datetime.now(datetime.timezone.utc).isoformat(),flush=True)
assert len(complete)==20
for row in complete:
 assert row['job_state'][:2]==['COMPLETED','0:0'],row
 run=Path(row['remote_run'])
 subprocess.run([sys.executable,'tests/check_result.py',str(run/'solver.log'),'1e-8','--metric','max' if row['problem']=='08' else 'relative'],check=True)
 assert re.search(r'Exit status: 0\s*$',(run/'process.time').read_text())
 log=(run/'solver.log').read_text()
 assert re.findall(r'perturbed_pivots=(\d+)',log)==['0']*5
 phases=re.findall(r'PHASE_SECONDS analyse=(\S+) factor=(\S+) solve_cleanup=(\S+)',log)
 assert len(phases)==5
 print('VALIDATED',row['problem'],row['rhs'],'mean_seconds',row['five_solve_average_seconds'],'peak_GiB',row['peak_bytes_sum']/2**30,'phase_means',[statistics.mean(float(p[i]) for p in phases) for i in range(3)],flush=True)
for problem in ['08','10']:
 found=[r for r in complete if r['problem']==problem]
 assert sorted(r['rhs'] for r in found)==['%02d'%i for i in range(1,11)]
 print('ALL_RHS_PASS',problem,'max_relative',max(r['relative_residual'] for r in found),'max_absolute',max(r['max_absolute_residual'] for r in found),'time_range',[min(r['five_solve_average_seconds'] for r in found),max(r['five_solve_average_seconds'] for r in found)],'sum_mean_seconds',sum(r['five_solve_average_seconds'] for r in found),'peak_bytes',max(r['peak_bytes_sum'] for r in found))

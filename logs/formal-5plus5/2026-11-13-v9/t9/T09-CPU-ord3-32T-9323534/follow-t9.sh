#!/bin/bash
set -euo pipefail
cd "$1"
label=$2; problem=$3; ranks=$4; threads=$5; memory=$6; limit=$7
shift 7
export LC_ALL=C
export SC26_PARDISO_ORDERING=3
date '+%F %T %Z'
printf 'SC26 | %s | %s MPI x %s threads | SC26_PARDISO_ORDERING=%s | RHS %s\n' \
    "$label" "$ranks" "$threads" "$SC26_PARDISO_ORDERING" "$*"
submit=(sbatch --parsable --job-name="sc26_$label" --chdir="$PWD"
    --output="$PWD/logs/%x-%j.out" --error="$PWD/logs/%x-%j.err"
    --exclusive --nodes=1 --ntasks="$ranks" --cpus-per-task="$threads" --mem="$memory"
    --time="$limit" --export=ALL,SC26_PARDISO_ORDERING=3 ./remediation-baseline.sbatch "$problem" "$@")
printf '+'
printf ' %q' "${submit[@]}"
printf '\n'
job=$("${submit[@]}")
job=${job%%;*}
printf 'Submitted Slurm job %s\n' "$job"
out="logs/sc26_$label-$job.out"
err="logs/sc26_$label-$job.err"
seen=0
drain_output() {
    [[ -s "$out" ]] || return 0
    local end
    end=$(wc -l < "$out")
    if (( end > seen )); then
        sed -n "$((seen+1)),${end}p" "$out" |
            awk '/^([[:xdigit:]]{64} |T[0-9]+_(PARDISO_|STRUCTURE_MATCH|DIAGONAL_EQUILIBRATION|RHS_PROJECTION|GMRES)|SC26_RUN|SC26_PARDISO_ORDERING|CHECK |Q-Check|Total memory usage|FORMAL_5PLUS5_PASS|OFFICIAL_RESIDUAL_PASS|matrix name|vectorb name|sys_type)/ && !/PARDISO_CONFIG|LIBRARY_DEFAULTS|PARDISO_SORT/ {print}'
        seen=$end
    fi
}
previous=
heartbeat=0
while :; do
    drain_output
    status=$(sacct -n -X -P -j "$job" -o State,ExitCode,NodeList,Elapsed | head -n1)
    state=${status%%|*}
    if [[ -n "$state" && "$state" != "$previous" ]]; then
        printf '%s JOB %s %s\n' "$(date '+%F %T %Z')" "$job" "$status"
        previous=$state
    fi
    case "$state" in
        COMPLETED|FAILED|TIMEOUT|OUT_OF_MEMORY|NODE_FAIL|PREEMPTED|CANCELLED*) break ;;
    esac
    if (( SECONDS >= heartbeat )); then
        printf '%s job %s %s\n' "$(date '+%F %T %Z')" "$job" "$status"
        heartbeat=$((SECONDS+55))
    fi
    sleep 8
done
sleep 3
drain_output
sacct -j "$job" -P -o JobID,State,ExitCode,Start,End,Elapsed,NodeList,AllocTRES
if [[ $status == COMPLETED\|0:0\|* ]] &&
   [[ $(grep -c '^OFFICIAL_RESIDUAL_PASS ' "$out") -eq $# ]]; then
    python3 - "$out" "$#" <<'PYCHK'
import re, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text()
expected = int(sys.argv[2])
qrels = [float(x) for x in re.findall(r"^Q-Check \|\| b - Ax \|\| 2 / \|\| b \|\| 2 =\s+(\S+)$", text, re.M)]
mems = [float(x) for x in re.findall(r"^Total memory usage:\s+(\S+) MB$", text, re.M)]
assert len(qrels) == expected and all(q < 1e-10 for q in qrels), qrels
assert len(mems) == expected and max(mems) * 1048576 < 100_000_000_000, mems
print(f"T09_V9_STRICT_PASS rhs_count={expected} max_qrel={max(qrels):.6e} max_mem_MiB={max(mems):.4f} max_mem_GB={max(mems)*0.001048576:.2f}")
PYCHK
    printf 'Job %s completed successfully\n' "$job"
else
    printf 'Job %s ended with %s\n' "$job" "$status"
    if [[ -s "$err" ]]; then tail -n 12 "$err"; fi
    exit 1
fi
sleep 3

#!/bin/bash
set -euo pipefail
cd /data/home/sunyc/solverchallenge26/formal-20261113-t3-ordering3-formal
export LC_ALL=C
date '+%F %T %Z'
printf 'SC26 | T03 commercial CPU | PARDISO iparm[1]=3 | 1 task, 16 CPU threads | RHS 01\n'
printf 'Checker: SolverChallenge26 official 046abcb check_correctness_q_xq\n'
submit=(sbatch --parsable --chdir="$PWD"
    --output="$PWD/slurm-%j.out" --error="$PWD/slurm-%j.err" ./run-t3.sbatch formal)
printf '+'
printf ' %q' "${submit[@]}"
printf '\n'
job=$("${submit[@]}")
job=${job%%;*}
printf '%s\n' "$job" > job.id
printf 'Submitted Slurm job %s\n' "$job"
out="slurm-$job.out"
err="slurm-$job.err"
seen=0
drain_output() {
    [[ -s "$out" ]] || return 0
    local end
    end=$(wc -l < "$out")
    if (( end > seen )); then
        sed -n "$((seen+1)),${end}p" "$out" |
            awk '/^([[:xdigit:]]{64} |T[0-9]+_(SMOKE_PASS|QUAD_REFINEMENT|PARDISO_|STRUCTURE_MATCH|DIAGONAL_EQUILIBRATION|RHS_PROJECTION|GMRES)|SC26_RUN|CHECK |Q-Check|Total memory usage|FORMAL_5PLUS5_PASS|OFFICIAL_RESIDUAL_PASS|matrix name|vectorb name|sys_type)/ && !/PARDISO_CONFIG|LIBRARY_DEFAULTS|PARDISO_SORT/ {print}'
        seen=$end
    fi
}
previous=
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
    sleep 8
done
drain_output
sacct -j "$job" -P -o JobID,State,ExitCode,Start,End,Elapsed,NodeList,AllocTRES
if [[ $status == COMPLETED\|0:0\|* ]] && grep -q '^OFFICIAL_RESIDUAL_PASS ' "$out"; then
    printf 'Job %s completed successfully\n' "$job"
else
    printf 'Job %s ended with %s\n' "$job" "$status"
    if [[ -s "$err" ]]; then tail -n 12 "$err"; fi
    exit 1
fi
sleep 3

#!/bin/bash
set -euo pipefail
cd "$1"
label=$2; problem=$3; ranks=$4; threads=$5; memory=$6; limit=$7
shift 7
export LC_ALL=C
date "+%F %T %Z"
printf "SC26 | %s | %s MPI x %s threads | ordering=%s | RHS %s\n" \
    "$label" "$ranks" "$threads" "${SC26_PARDISO_ORDERING:-2}" "$*"
submit=(sbatch --parsable --exclusive --export="ALL,SC26_PARDISO_ORDERING=${SC26_PARDISO_ORDERING:-2}"
    --job-name="sc26_$label" --chdir="$PWD"
    --output="$PWD/logs/%x-%j.out" --error="$PWD/logs/%x-%j.err"
    --nodes=1 --ntasks="$ranks" --cpus-per-task="$threads" --mem="$memory"
    --time="$limit" ./remediation-baseline.sbatch "$problem" "$@")
printf "+"
printf " %q" "${submit[@]}"
printf "\n"
job=$("${submit[@]}")
job=${job%%;*}
printf "%s\n" "$job" > "$PWD/$label.job"
printf "Submitted Slurm job %s\n" "$job"
out="logs/sc26_$label-$job.out"
err="logs/sc26_$label-$job.err"
seen=0
drain_output() {
    [[ -s "$out" ]] || return 0
    local end
    end=$(wc -l < "$out")
    if (( end > seen )); then
        sed -n "$((seen+1)),${end}p" "$out" |
            awk "/^([[:xdigit:]]{64} |SC26_PARDISO_ORDERING=|T[0-9]+_(PARDISO_|STRUCTURE_MATCH|DIAGONAL_EQUILIBRATION|RHS_PROJECTION|GMRES)|SC26_RUN|CHECK |Q-Check|Total memory usage|FORMAL_5PLUS5_PASS|OFFICIAL_RESIDUAL_PASS|matrix name|vectorb name|sys_type)/ && !/LIBRARY_DEFAULTS|PARDISO_SORT/ && (!/PARDISO_CONFIG/ || !seen_cfg++) {print}"
        seen=$end
    fi
}
previous=
heartbeat=0
while :; do
    drain_output
    status=$(sacct -n -X -P -j "$job" -o State,ExitCode,NodeList,Elapsed | head -n1 || true)
    state=${status%%|*}
    if [[ -n "$state" && "$state" != "$previous" ]]; then
        printf "%s JOB %s %s\n" "$(date "+%F %T %Z")" "$job" "$status"
        previous=$state
    fi
    case "$state" in
        COMPLETED|FAILED|TIMEOUT|OUT_OF_MEMORY|NODE_FAIL|PREEMPTED|CANCELLED*) break ;;
    esac
    if (( SECONDS >= heartbeat )); then
        printf "%s job %s %s\n" "$(date "+%F %T %Z")" "$job" "$status"
        heartbeat=$((SECONDS+55))
    fi
    sleep 8
done
drain_output
sacct -j "$job" -P -o JobID,State,ExitCode,Start,End,Elapsed,NodeList,AllocTRES
if [[ $status == COMPLETED\|0:0\|* ]] &&
   [[ $(grep -c "^OFFICIAL_RESIDUAL_PASS " "$out") -eq $# ]]; then
    for rhs in "$@"; do
        python3 "$PWD/tests/check_result.py" "$PWD/runs/t$problem-$job/rhs-$rhs/solver.log" 1e-10 --metric relative --formal
    done
    printf "Job %s completed successfully\n" "$job"
else
    printf "Job %s ended with %s\n" "$job" "$status"
    if [[ -s "$err" ]]; then tail -n 12 "$err"; fi
    exit 1
fi
sleep 3

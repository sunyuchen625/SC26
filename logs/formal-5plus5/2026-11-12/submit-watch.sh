#!/bin/bash
set -euo pipefail
cd /data/home/sunyc/solverchallenge26/formal-20261112
label=$1; problem=$2; ranks=$3; threads=$4; memory=$5; limit=$6
shift 6
export LC_ALL=C
date '+%F %T %Z'
printf 'SC26 %s | %s | %s MPI ranks x %s threads | RHS %s\n' "$label" "$(hostname)" "$ranks" "$threads" "$*"
printf 'Upstream sample and report template: 046abcb4045773feb55e4913234607c4d9887dc5\n'
build=9321498
if [[ $problem == 05 ]]; then build=9321499; fi
submit=(sbatch --parsable --dependency="afterok:$build" --job-name="sc26_$label" --chdir="$PWD" --nodes=1
    --ntasks="$ranks" --cpus-per-task="$threads" --mem="$memory" --time="$limit"
    ./remediation-baseline.sbatch "$problem" "$@")
printf '+'
printf ' %q' "${submit[@]}"
printf '\n'
job=$( "${submit[@]}" )
job=${job%%;*}
printf 'Submitted Slurm job %s\n' "$job"
printf '%s\n' "$job" > "logs/$label.job"
out="logs/sc26_$label-$job.out"
err="logs/sc26_$label-$job.err"
tail --pid=$$ -n +1 --retry -s 1 -F "$out" 2>/dev/null |
    stdbuf -oL awk '/^([[:xdigit:]]{64} |T[0-9]+_(PARDISO_|STRUCTURE_MATCH|DIAGONAL_EQUILIBRATION|RHS_PROJECTION|GMRES)|SC26_RUN|CHECK |Q-Check|Total memory usage|FORMAL_5PLUS5_PASS|OFFICIAL_RESIDUAL_PASS|matrix name|vectorb name|sys_type)/ && !/PARDISO_CONFIG|LIBRARY_DEFAULTS|PARDISO_SORT/ {print}' &
watcher=$!
trap 'kill "$watcher" 2>/dev/null || true' EXIT
previous=
while :; do
    status=$(sacct -n -X -P -j "$job" -o State,ExitCode,NodeList,Elapsed | head -n1)
    state=${status%%|*}
    if [[ $state != "$previous" && -n $status ]]; then
        printf '%s JOB %s %s\n' "$(date '+%F %T %Z')" "$job" "$status"
        previous=$state
    fi
    case "$state" in
        COMPLETED|FAILED|TIMEOUT|OUT_OF_MEMORY|NODE_FAIL|PREEMPTED|CANCELLED*) break ;;
    esac
    if [[ $(squeue -h -j "$job" -o '%r' 2>/dev/null) == DependencyNeverSatisfied ]]; then
        printf 'Build and small-case job did not pass. Cancelling dependent job %s.\n' "$job"
        scancel "$job"
    fi
    sleep 10
done
sleep 2
kill "$watcher" 2>/dev/null || true
sacct -j "$job" -P -o JobID,State,ExitCode,Start,End,Elapsed,NodeList,AllocTRES
if [[ -s "$err" ]]; then
    printf 'Slurm stderr (last 12 lines)\n'
    tail -n 12 "$err"
fi
[[ $state == COMPLETED ]]
printf 'Job %s completed successfully\n' "$job"
sleep 3

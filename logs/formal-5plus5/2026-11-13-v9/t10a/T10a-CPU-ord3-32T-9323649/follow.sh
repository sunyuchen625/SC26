#!/bin/bash
set -euo pipefail
cd "$1"
label=$2; problem=$3; ranks=$4; threads=$5; memory=$6; limit=$7
shift 7
export LC_ALL=C
date '+%F %T %Z'
printf 'SC26 | %s | %s MPI x %s threads | RHS %s\n' "$label" "$ranks" "$threads" "$*"
extra_args=(--exclusive)
if [[ -n "${SC26_PARDISO_ORDERING:-}" ]]; then
    extra_args+=(--export="ALL,SC26_PARDISO_ORDERING=$SC26_PARDISO_ORDERING")
fi
submit=(sbatch --parsable --job-name="sc26_$label" --chdir="$PWD"
    --output="$PWD/logs/%x-%j.out" --error="$PWD/logs/%x-%j.err"
    --nodes=1 --ntasks="$ranks" --cpus-per-task="$threads" --mem="$memory"
    --time="$limit" "${extra_args[@]}" ./remediation-baseline.sbatch "$problem" "$@")
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
            awk '/^([[:xdigit:]]{64} |T[0-9]+_(PARDISO_|STRUCTURE_MATCH|DIAGONAL_EQUILIBRATION|RHS_PROJECTION|GMRES)|SC26_RUN|CHECK |Q-Check|Total memory usage|FORMAL_5PLUS5_PASS|OFFICIAL_RESIDUAL_PASS|matrix name|vectorb name|sys_type)/ && !/PARDISO_CONFIG|LIBRARY_DEFAULTS|PARDISO_SORT/ {print}'
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
drain_output
sacct -j "$job" -P -o JobID,State,ExitCode,Start,End,Elapsed,NodeList,AllocTRES
if [[ $status == COMPLETED\|0:0\|* ]] &&
   [[ $(grep -c '^OFFICIAL_RESIDUAL_PASS ' "$out") -eq $# ]]; then
    for rhs in "$@"; do
        python3 -c 'import re,sys; v=float(re.findall(r"^Q-Check complex \|\| b - Ax \|\| 2 / \|\| b \|\| 2 =\s+(\S+)$", open(sys.argv[1]).read(), re.M)[-1]); assert v < 1e-10, v; print(f"STRICT_1E10_PASS rhs={sys.argv[2]} qrel={v:.6e}")' "runs/t$problem-$job/rhs-$rhs/solver.log" "$rhs"
    done
    printf 'Job %s completed successfully\n' "$job"
else
    printf 'Job %s ended with %s\n' "$job" "$status"
    if [[ -s "$err" ]]; then tail -n 12 "$err"; fi
    exit 1
fi
sleep 3

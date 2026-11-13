#!/bin/bash
set -euo pipefail
root=$(cd "$(dirname "$0")" && pwd)
label=$1
shift
dest="$root/recordings/$label"
mkdir -p "$root/recordings"
mkdir "$dest"
printf -v command '%q ' python3 "$root/record.py" "$dest/recording.cast" "SolverChallenge26 CUDA OOM! | $label" "$@"
printf -v launch '%s; rc=$?; printf "%%s\\n" "$rc" > %q' "$command" "$dest/record.exit"
tmux new-session -d -s "sc26-$label" "$launch"
printf '%s\n' "$dest"

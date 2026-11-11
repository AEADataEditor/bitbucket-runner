#!/bin/bash
# cron_add.sh
# Install the runner's maintenance entries (cron_entries.sh) in the current
# user's crontab. Replaces earlier versions of them; other lines are kept.
# Safe to run again.

. "$(dirname "$(readlink -f "$0")")/cron_entries.sh"

mkdir -p "$RUNNER_DIR/logs"
# read it completely before writing: don't rely on crontab buffering its input
others=$(current_crontab | grep -vF "$MARKER")
{
    [ -n "$others" ] && printf '%s\n' "$others"
    printf '%s\n' "${ENTRIES[@]}"
} | $CRONTAB - || { echo "cron_add: could not install the crontab"; exit 1; }

echo "cron_add: installed ${#ENTRIES[@]} entr$([ ${#ENTRIES[@]} -eq 1 ] && echo y || echo ies):"
printf '  %s\n' "${ENTRIES[@]}"

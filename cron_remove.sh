#!/bin/bash
# cron_remove.sh
# Remove the runner's maintenance entries (those ending with MARKER, see
# cron_entries.sh) from the current user's crontab. Other lines are kept.

. "$(dirname "$(readlink -f "$0")")/cron_entries.sh"

before=$(current_crontab)
n=$(grep -cF "$MARKER" <<< "$before")
if [ "$n" -eq 0 ]; then
    echo "cron_remove: no maintenance entries installed"
    exit 0
fi
grep -vF "$MARKER" <<< "$before" | $CRONTAB - || { echo "cron_remove: could not update the crontab"; exit 1; }
echo "cron_remove: removed $n entr$([ "$n" -eq 1 ] && echo y || echo ies)"

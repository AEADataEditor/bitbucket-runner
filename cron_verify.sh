#!/bin/bash
# cron_verify.sh
# Check that the crontab holds exactly the runner's maintenance entries
# (cron_entries.sh), and that what they call can run.
# Exit 0 if everything is in place, 1 otherwise.

. "$(dirname "$(readlink -f "$0")")/cron_entries.sh"

status=0
installed=$(current_crontab | grep -F "$MARKER")

for entry in "${ENTRIES[@]}"; do
    if grep -qxF -- "$entry" <<< "$installed"; then
        echo "ok      $entry"
    else
        echo "MISSING $entry"
        status=1
    fi
done
while IFS= read -r line; do
    [ -z "$line" ] && continue
    printf '%s\n' "${ENTRIES[@]}" | grep -qxF -- "$line" || { echo "STALE   $line"; status=1; }
done <<< "$installed"

if [ -x "$RUNNER_DIR/prune_step_images.sh" ]; then
    echo "ok      prune_step_images.sh is executable"
else
    echo "FAIL    $RUNNER_DIR/prune_step_images.sh is missing or not executable"
    status=1
fi
if docker info >/dev/null 2>&1; then
    echo "ok      docker is usable by $(id -un)"
else
    echo "FAIL    docker is not usable by $(id -un)"
    status=1
fi
if [ -d "$RUNNER_DIR/logs" ] && [ -w "$RUNNER_DIR/logs" ]; then
    echo "ok      $RUNNER_DIR/logs is writable"
else
    echo "FAIL    $RUNNER_DIR/logs is missing or not writable"
    status=1
fi

[ $status -eq 0 ] && echo "cron_verify: all good" || echo "cron_verify: problems found (run cron_add.sh to fix the crontab)"
exit $status

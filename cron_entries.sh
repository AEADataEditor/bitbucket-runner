# cron_entries.sh
# The crontab entries for the Bitbucket runner's maintenance. Sourced by
# cron_add.sh, cron_verify.sh and cron_remove.sh; not run on its own.
#
# Every entry ends with MARKER, which is how the scripts find their own lines
# and leave all other crontab lines alone. Set CRONTAB to use another crontab
# command (for testing).

RUNNER_DIR=/home/bitbucket-runner
MARKER='# bitbucket-runner-maintenance'
CRONTAB="${CRONTAB:-crontab}"

ENTRIES=(
    "0 3 * * 0 $RUNNER_DIR/prune_step_images.sh >> $RUNNER_DIR/logs/prune_step_images.log 2>&1 $MARKER"
)

current_crontab() {
    # an empty or missing crontab is not an error
    $CRONTAB -l 2>/dev/null || true
}

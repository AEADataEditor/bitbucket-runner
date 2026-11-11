#!/bin/bash
# prune_step_images.sh
# Remove Docker images left behind by Bitbucket runner steps, and nothing else.
#
# Only images that match PATTERNS and that no container (running or stopped)
# uses are removed. Bitbucket pulls them again when a step needs them. A plain
# "docker image prune -a" is NOT safe on this machine: it would also remove the
# images of stacks that happen to be down (openwebui, litellm, firefly-iii, ...).
#
# Usage: prune_step_images.sh [--dry-run]

PATTERNS=(
    '^python:'                                          # step image of p-pii-checker
    '^docker-public\.packages\.atlassian\.com/sox/atlassian/'  # runner and its helper images
)

dry_run=no
[ "$1" = "--dry-run" ] && dry_run=yes

echo "$(date '+%Y-%m-%d %H:%M:%S') prune_step_images (dry run: $dry_run)"
removed=0
while read -r ref id; do
    match=no
    for pattern in "${PATTERNS[@]}"; do
        [[ "$ref" =~ $pattern ]] && match=yes
    done
    [ "$match" = yes ] || continue
    if [ -n "$(docker ps -a -q --filter "ancestor=$id")" ]; then
        echo "  keep   $ref (in use)"
        continue
    fi
    echo "  remove $ref"
    removed=$((removed + 1))
    [ "$dry_run" = yes ] || docker image rm "$ref" >/dev/null || echo "  failed to remove $ref"
done < <(docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep -v ':<none> ')
# untagged leftovers of re-pulled images
[ "$dry_run" = yes ] || docker image prune -f >/dev/null
echo "  $removed image(s) $([ "$dry_run" = yes ] && echo 'would be ' )removed"

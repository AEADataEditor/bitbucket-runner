#!/bin/bash
# start_runner.sh
# Start (or restart) the self-hosted Bitbucket Pipelines runner on this machine.
#
# The runner's credentials (ACCOUNT_UUID, RUNNER_UUID, OAUTH_CLIENT_ID,
# OAUTH_CLIENT_SECRET) are in .env next to this script, which is never
# committed; .env.example lists them. They are passed to the container with
# --env-file, so they don't appear on the command line or in `ps`.
#
# Usage: start_runner.sh

cd "$(dirname "$(readlink -f "$0")")" || exit 1

if [ ! -f .env ]; then
    echo "start_runner: .env not found; copy .env.example and fill it in" >&2
    exit 1
fi
if [ -n "$(find .env -perm /077)" ]; then
    echo "start_runner: .env is readable by others; run: chmod 600 .env" >&2
    exit 1
fi
RUNNER_UUID=$(grep -m1 '^RUNNER_UUID=' .env | cut -d= -f2-)
RUNNER_UUID=${RUNNER_UUID//[\{\}]/}
if [ -z "$RUNNER_UUID" ]; then
    echo "start_runner: RUNNER_UUID missing from .env" >&2
    exit 1
fi
name="runner-$RUNNER_UUID"
image=docker-public.packages.atlassian.com/sox/atlassian/bitbucket-pipelines-runner

docker pull --quiet "$image" >/dev/null || echo "start_runner: could not pull $image, using the local one" >&2
if docker container inspect "$name" >/dev/null 2>&1; then
    echo "start_runner: replacing the running container $name"
    docker container rm -f "$name" >/dev/null || exit 1
fi

docker container run -d --restart unless-stopped \
    -v /tmp:/tmp \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /var/lib/docker/containers:/var/lib/docker/containers:ro \
    --env-file .env \
    -e RUNTIME_PREREQUISITES_ENABLED=true \
    -e WORKING_DIRECTORY=/tmp \
    --name "$name" \
    "$image" >/dev/null || exit 1
echo "start_runner: started $name; follow it with: docker logs -f $name"

# Self-hosted Bitbucket Pipelines runner

Scripts to run a Bitbucket Pipelines workspace runner in Docker on a Linux host, plus weekly cleanup of step images.

Used so pipelines can reach services on the host's local network or tailnet (e.g. an LLM API) without inbound ports or proxies. The runner connects outbound only.

How the pipelines use the runner (`runs-on` labels, step images, variables): see [replication-template-development](https://github.com/AEADataEditor/replication-template-development).

| File | Purpose |
|---|---|
| `start_runner.sh` | Pull the runner image, (re)start the container with credentials from `.env` |
| `.env.example` | Template for `.env` (credentials, never committed) |
| `prune_step_images.sh` | Remove unused runner/step images only. `--dry-run` to preview |
| `cron_entries.sh` | Crontab entries (sourced, not run) |
| `cron_add.sh` / `cron_verify.sh` / `cron_remove.sh` | Install / check / remove the crontab entries |

## System requirements

- [ ] 64-bit Linux, x86_64
- [ ] Docker Engine ≥ 19.03, running, started at boot
- [ ] 8 GB RAM minimum free for the runner and its steps (Atlassian minimum); more for heavy steps
- [ ] Disk for step images and build caches (several GB)
- [ ] Outbound HTTPS to `*.atlassian.com`, `*.bitbucket.org`, `*.atlassian.net` and to whatever registries the step images come from
- [ ] A user in the `docker` group, with a crontab
- [ ] Bitbucket workspace admin rights (to register the runner)

## Setup from scratch

1. [ ] Install Docker; add the runner user to the `docker` group; log out and in. Check: `docker info`.
2. [ ] Clone this repo as that user: `git clone https://github.com/AEADataEditor/bitbucket-runner.git` (any location; scripts find their own directory).
3. [ ] Bitbucket: Workspace settings → Workspace runners → Add runner. System: Linux Docker (x86_64). Add the custom labels the pipelines expect (see replication-template-development).
4. [ ] From the `docker container run` command shown, copy `ACCOUNT_UUID`, `RUNNER_UUID`, `OAUTH_CLIENT_ID`, `OAUTH_CLIENT_SECRET`. Do not run that command.
5. [ ] `cp .env.example .env`, fill in the four values, `chmod 600 .env`.
6. [ ] `./start_runner.sh`
7. [ ] `docker logs -f runner-<RUNNER_UUID>` until it reports the runner online; Bitbucket shows it as ONLINE.
8. [ ] Add patterns to `PATTERNS` in `prune_step_images.sh` for any step images the pipelines use beyond `python:*`.
9. [ ] `./prune_step_images.sh --dry-run` — check it would only remove runner/step images.
10. [ ] `./cron_add.sh`, then `./cron_verify.sh` (must end with `all good`).
11. [ ] Trigger a pipeline that uses the runner's labels; confirm it runs here.

## Security

- **Root-equivalent.** The runner mounts `/var/run/docker.sock`. Any pipeline step that runs on it can control Docker, and thus the host. Treat every repo allowed to use the runner as having root on this machine.
- **Who can use it.** A workspace runner is available to every repo in the workspace that names its labels. Keep the workspace limited to trusted repos and members; prefer a repository runner if only one repo needs it. Do not use it for pull requests from forks.
- **Network reach.** Steps see everything the host sees: LAN, tailnet, local services. Do not run it on a host with services that must stay isolated from CI code.
- **`/tmp` is shared** with the host (Atlassian's default mount). Do not keep anything sensitive in the host's `/tmp`.
- **Credentials.** `.env` holds the OAuth secret; it is git-ignored, mode 600 (enforced by `start_runner.sh`), and passed with `--env-file` so it does not show in `ps`. If leaked: delete the runner in Bitbucket, add a new one, update `.env`, restart.
- **No inbound ports.** The runner connects out to Bitbucket; nothing needs to be opened or forwarded.
- **Image source.** The runner image is pulled from `docker-public.packages.atlassian.com` on every start. Step images come from wherever the pipelines name them; pin them by tag or digest in the pipeline.

## Ongoing maintenance

Automatic:

- [ ] Weekly (Sun 03:00): `prune_step_images.sh` removes unused runner/step images. Log: `logs/prune_step_images.log`.
- [ ] Container restarts after reboot or crash (`--restart unless-stopped`).

Manual:

- [ ] After any change to `cron_entries.sh` or moving the repo: `./cron_add.sh && ./cron_verify.sh`.
- [ ] Update the runner: `./start_runner.sh` (pulls the latest image, replaces the container). Do this when Bitbucket flags the runner as outdated, or monthly.
- [ ] Check `logs/prune_step_images.log` and `docker system df` occasionally; add patterns for new step images.
- [ ] Check the runner is ONLINE in Workspace settings → Workspace runners; if not, `docker logs runner-<RUNNER_UUID>`.
- [ ] Keep Docker and the OS patched.
- [ ] Decommission: `./cron_remove.sh`, `docker rm -f runner-<RUNNER_UUID>`, delete the runner in Bitbucket, delete `.env`.

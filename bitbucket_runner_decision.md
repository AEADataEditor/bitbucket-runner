---
name: bitbucket-runner-decision
description: "Decided to use a self-hosted Bitbucket Pipelines runner (not Tailscale-in-ephemeral-cloud-runner) for CI access to the home LLM API, set up in a separate folder/environment"
metadata: 
  node_type: memory
  type: project
  originSessionId: 155747e7-651d-49be-8b8c-eb2fb1251b20
  modified: 2026-09-15T21:26:26.580Z
---

Chosen approach (decided 2026-09-15) for giving Bitbucket Pipelines CI jobs access to the home server's Ollama/Open WebUI API: a self-hosted Bitbucket runner, not Tailscale joined from Bitbucket's ephemeral cloud-hosted runners.

**Why:** Bitbucket's cloud-hosted runners don't grant `--cap-add`/`/dev/net/tun`, so running Tailscale there would require userspace-networking mode plus routing every tool through a local SOCKS5/HTTP proxy — workable but fiddly to wire into arbitrary scripts. A self-hosted runner instead registers outbound-only to Bitbucket (no inbound port-forwarding, no proxy shims) and reaches the API directly over the local/tailnet network. Tradeoff accepted: pipeline code now executes on home hardware, so it's a trust boundary (fine for a private/controlled repo) and competes for CPU/GPU with other workloads. A Tailscale tailnet is already running and available to the home server if the runner needs it.

**How to apply:** The runner is being set up in a separate folder/environment on the same home server — deliberately *not* added to `/home/openwebui`'s `docker-compose.yml` or wired into the `openwebui`/`ollama` services, since that stack is general-purpose and not runner-specific. If asked to add CI/runner config inside `/home/openwebui`, point back to the separate runner environment instead of adding it here.

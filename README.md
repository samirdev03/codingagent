# CodingAgent Remote Workspace

A Codex workspace for a Linux SSH server. Codex runs on the server host when the ChatGPT desktop app connects to it; Docker Compose keeps the Obsidian MCP vault service and headless Playwright MCP available. Codex also registers GitHub's official MCP server over stdio, supplied with the token from the server user's authenticated GitHub CLI. The workspace includes the MIT-licensed Obsidian Second Brain Agent Skills package.

This repository does not run ChatGPT Work or Codex inside Docker. The supported design uses Codex on the SSH host and the ChatGPT desktop app as the client. ChatGPT mobile's Remote tab can access supported desktop Codex chats; whether an SSH-hosted workspace appears there depends on the currently supported Remote connection flow. See [Remote setup](docs/REMOTE_SETUP.md).

## Quick setup

1. Prepare a Linux server with SSH access, Docker Engine plus Compose plugin, Git, and Node.js/npm.
2. Clone this repository on the server and enter it:

   ```sh
git clone --branch feat/codex-remote-obsidian https://github.com/samirdev03/codingagent.git
cd codingagent
```

3. Set the container UID/GID to the SSH user's IDs so the Obsidian MCP can write the mounted vault, then install Codex CLI:

   ```sh
   cp .env.example .env
   sed -i "s/^OBSIDIAN_UID=.*/OBSIDIAN_UID=$(id -u)/; s/^OBSIDIAN_GID=.*/OBSIDIAN_GID=$(id -g)/" .env
   bash scripts/install-codex-host.sh
   codex login
   ```

4. Start the persistent MCP services:

   ```sh
   docker compose up -d --build
   ```

5. Install GitHub CLI if needed and authenticate once with `gh auth login --hostname github.com --git-protocol https --web`. From the ChatGPT desktop app, connect to the server as an SSH host and open this repository as the workspace. Initialize the vault with the `obsidian-init` skill if desired.

Read [Remote setup](docs/REMOTE_SETUP.md) before connecting and [Operations](docs/OPERATIONS.md) for restarts, backups, health checks, and updates.

## Services and persistence

| Component | Runs where | Persistent data |
| --- | --- | --- |
| Codex CLI | Linux server host | Codex account state in the host user's Codex config |
| GitHub MCP | Official Docker image, launched over stdio | GitHub CLI credential in the server user's home directory |
| Obsidian MCP | Docker Compose | `obsidian-vault/` bind-mounted read/write at `/vault` |
| Playwright MCP | Docker Compose, host port bound to loopback | test artifacts under `workspace/test-results/` |
| Second Brain skills | Repository checkout | `.agents/skills/`, versioned and MIT-attributed |

No GitHub PAT file or Obsidian account is required by the default setup. GitHub CLI stores its login on the server and the MCP wrapper passes it only to the running container. Obsidian Sync is optional and configured in an Obsidian client, not this headless service. Keep `.env`, Codex auth data, and vault notes out of Git.

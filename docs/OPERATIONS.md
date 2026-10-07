# Operations

## Check readiness

```sh
scripts/remote-doctor.sh
scripts/mcp/playwright-check.sh
```

The doctor checks Codex, Docker Compose, vault presence, Compose safety, and running services. The Playwright script checks the container's Docker health status. These commands do not print credentials.

## Start, stop, and restart

```sh
docker compose up -d --build
docker compose ps
docker compose logs --tail=100 obsidian-mcp playwright
docker compose restart
```

Both services use `restart: unless-stopped`. The MCP processes are available to Codex while the host and Docker daemon are running. The server can stay online continuously, but a Codex interaction is started through a supported desktop app connection; this setup is not an autonomous 24/7 Codex conversation daemon.

## Back up the vault

Back up `obsidian-vault/` with your server's normal encrypted backup process. It contains personal notes and is ignored by Git. Test restore to a separate directory before replacing the live vault. Do not publish the vault or include it in a public repository.

## Update

Review upstream/repository changes before pulling. Rebuild the containers after Dockerfile or Compose image updates:

```sh
git pull --ff-only
docker compose pull
docker compose up -d --build
scripts/remote-doctor.sh
```

Update the Second Brain package separately via `scripts/install-second-brain.sh`; review its generated skill diff and pinned MIT attribution before committing.

## Renew access

Codex sign-in and GitHub CLI authentication are separate. If either expires, run `codex login` or `gh auth login --hostname github.com --git-protocol https --web` on the server user account. Authentication state belongs to that user's configuration directories; protect them with normal host account permissions and backups. Obsidian vault access is filesystem access and has no token to renew. Optional Obsidian Sync credentials are managed by the Obsidian client.

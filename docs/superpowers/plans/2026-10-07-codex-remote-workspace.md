# Codex Remote Workspace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current OpenCode/Discord project with a Codex Remote SSH server setup and persistent Docker MCP services reachable from ChatGPT mobile Remote.

**Architecture:** Codex runs on the Linux server host and is launched by the Codex desktop app over SSH. Docker Compose manages the Playwright MCP, Obsidian vault/MCP process, and supporting persistent storage; GitHub MCP runs as the official pinned container over stdio and receives the persistent host GitHub CLI token at launch. Install the MIT-licensed cross-agent `obsidian-second-brain` Agent Skills build for Codex.

**Tech Stack:** Codex CLI + Codex SSH remote workspace, Docker Compose, official GitHub MCP, Microsoft Playwright MCP, Node.js Obsidian MCP v2, Agent Skills.

**Spec:** `docs/superpowers/specs/2026-10-07-codex-remote-workspace-design.md`

## Global Constraints

- Codex runs on the SSH server host; do not present a Dockerized Codex process as a supported ChatGPT Remote SSH target.
- Do not publish MCP ports publicly; bind any host-accessible MCP endpoint to loopback or use stdio.
- Keep secrets out of the image and Git; use environment variables and ignored local files.
- Keep the Obsidian vault persistent and allowlisted to the Obsidian MCP process.
- Vendor or install upstream Second Brain skills with MIT attribution and a pinned upstream revision.
- Remove the existing OpenCode, Discord bridge, and their configuration from this branch.

## Review Focus

- SSH login shell has Codex on PATH so the desktop app can start its remote app server.
- GitHub authorization is available to the headless remote Codex MCP connection through the host's GitHub CLI login without exposing a public callback or storing a token in the repository.
- Obsidian MCP read/write is limited to the configured vault and works through Docker stdio.
- Playwright MCP reaches local server projects without publishing its browser endpoint to the internet.
- The second-brain package's installer is pinned, reproducible, and does not overwrite user vault data.

---

### Task 1: Replace the OpenCode/Discord Compose stack

**Files:**
- Modify: `Dockerfile`
- Modify: `compose.yaml`
- Modify: `.env.example`
- Modify: `.gitignore`
- Delete: `opencode.json`
- Delete: `.opencode/agents/architect.md`
- Delete: `.opencode/agents/coder.md`
- Delete: `discord-bridge/Dockerfile`
- Delete: `discord-bridge/index.mjs`
- Delete: `discord-bridge/package.json`

**Interfaces:**
- Produces: Compose services for `playwright` and `obsidian-mcp`, plus persistent vault/workspace paths; no public unauthenticated listener.

- [x] **Step 1: Add Compose validation checks** — create `scripts/validate-compose.sh` and assert the required service names, loopback-only published ports, persistent vault mount, and ignored secret file.
- [x] **Step 2: Run the checks to confirm they fail against the legacy stack.**
- [x] **Step 3: Replace the Dockerfile and Compose config** with pinned MCP runtime images/commands; keep MCP stdio services private and persist the vault under `./obsidian-vault`.
- [x] **Step 4: Update `.env.example` and `.gitignore`** for GitHub auth, local runtime settings, the vault, and secret files; remove Discord/OpenRouter variables.
- [x] **Step 5: Delete OpenCode and Discord configuration/source files** listed above.
- [x] **Step 6: Run `scripts/validate-compose.sh`; parse Compose YAML and verify no secrets are embedded.** `docker compose config` is deferred to the target server because Docker is not installed in this workspace.

### Task 2: Configure Codex Remote SSH and MCP access

**Files:**
- Create: `.codex/config.toml`
- Create: `scripts/install-codex-host.sh`
- Create: `scripts/remote-doctor.sh`
- Create: `scripts/mcp/obsidian.sh`
- Create: `scripts/mcp/playwright-check.sh`
- Modify: `compose.yaml`
- Modify: `.env.example`

**Interfaces:**
- `.codex/config.toml` registers `github`, `obsidian`, and `playwright` with Codex.
- Host scripts install/check Codex CLI and report SSH/Compose readiness without printing credentials.

- [x] **Step 1: Add failing shell checks** for missing Codex, Docker/Compose, absent vault path, and insecure published MCP ports.
- [x] **Step 2: Run the checks and confirm the expected failures.**
- [x] **Step 3: Implement the host installer and doctor** with the current supported Codex install method, PATH setup for non-interactive SSH login shells, explicit authentication instructions, and SSH-key guidance.
- [x] **Step 4: Configure GitHub MCP** as a local stdio server using the pinned official image; pass the host GitHub CLI token as an environment variable and do not commit it.
- [x] **Step 5: Configure Obsidian MCP** to run through the Compose service's stdio process and point only to the persistent vault.
- [x] **Step 6: Configure Playwright MCP** through the private Compose endpoint and add a readiness check for the MCP/browser container.
- [x] **Step 7: Validate Codex MCP TOML, run the remote doctor/MCP checks with mocks, and verify no token appears in output.** Actual `codex mcp list` and container health checks are deferred until the server has Codex and Docker.

### Task 3: Add the Second Brain Agent Skills package

**Files:**
- Create: `scripts/install-second-brain.sh`
- Create: `docs/SECOND_BRAIN.md`
- Create: `third_party/obsidian-second-brain/NOTICE.md`
- Create: `.agents/skills/` via the upstream Codex Agent Skills build.

**Interfaces:**
- The installer builds the `agent-skills` output from `eugeniughelbur/obsidian-second-brain` at a pinned revision and installs it into the project skill directory.
- The package includes developer-oriented vault architecture notes and general capture/search/maintenance skills.

- [x] **Step 1: Add installer checks** for an existing install, an invalid upstream revision, and a missing build output.
- [x] **Step 2: Verify the checks fail before the installer exists.**
- [x] **Step 3: Implement a pinned, repeatable upstream install/build** that preserves the upstream MIT license and records the source revision in `NOTICE.md`.
- [x] **Step 4: Add local Codex skill guidance** in `AGENTS.md` so the agent knows how to discover the vault, use MCP tools, and avoid writing unsupported facts.
- [x] **Step 5: Validate installed SKILL.md frontmatter, referenced files, and Codex-compatible paths.**

### Task 4: Document first-time setup, mobile access, and persistence

**Files:**
- Modify: `README.md`
- Create: `docs/REMOTE_SETUP.md`
- Create: `docs/OPERATIONS.md`

**Interfaces:**
- Setup guide covers server prerequisites, GitHub authentication, Codex sign-in, SSH configuration in the desktop app, and mobile Remote.
- Operations guide covers updates, health checks, vault backups, restart behavior, and auth renewal.

- [x] **Step 1: Write docs against the final scripts and Compose services**; clearly distinguish GitHub MCP auth from Codex ChatGPT sign-in and Obsidian vault access.
- [x] **Step 2: Explain that Obsidian desktop GUI/Obsidian Sync login is not run in the headless server container; the shared vault is Markdown files, and Sync can be configured separately in an Obsidian client if desired.**
- [x] **Step 3: Include mobile Remote steps**: connect SSH host from Codex desktop app, open a supported session, then use the ChatGPT mobile app Remote tab.
- [x] **Step 4: Verify all documented commands and environment variable names against the implementation; remove references to Discord/OpenCode.**

### Task 5: Verify the replacement branch

**Files:**
- Test: `scripts/validate-compose.sh`
- Test: `scripts/remote-doctor.sh`
- Test: `scripts/install-second-brain.sh`

- [x] **Step 1: Run shell syntax checks** with `bash -n scripts/*.sh scripts/mcp/*.sh`.
- [x] **Step 2: Parse Compose YAML and run static safety validation.** Actual `docker compose config` is deferred because Docker is absent here. with `docker compose config` using a temporary test env file.
- [x] **Step 3: Run installer and config validation checks** without logging in or storing real credentials.
- [x] **Step 4: Search the branch for legacy files and configuration references** and confirm OpenCode/Discord variables, files, and services are gone.
- [x] **Step 5: Report which runtime checks need to be run on the actual server**, since this workspace cannot perform that server’s SSH or account login.

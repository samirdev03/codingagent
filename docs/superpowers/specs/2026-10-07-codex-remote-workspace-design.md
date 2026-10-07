# Codex Remote Workspace Design

**Date:** 2026-10-07
**Repository:** samirdev03/codingagent
**Branch:** feat/codex-remote-obsidian

## Goal

Replace the existing OpenCode and Discord stack with a server workspace that can be opened from the ChatGPT Codex desktop app through Remote SSH and then reached from the ChatGPT mobile app Remote tab. Keep the durable workspace, Obsidian knowledge vault, GitHub MCP, and Playwright MCP in Docker-managed services.

## User requirements

- Codex work must execute on the always-on server and be reachable from the ChatGPT mobile app.
- Create a new branch from `main`; replace the current project on this branch.
- Provide Obsidian knowledge access with an Obsidian-focused Second Brain skill suited to software engineering and general agent work.
- Provide GitHub and Playwright MCP tools in the Codex environment.
- Make first-time setup straightforward, with credentials and login instructions documented.

## Architecture

1. **Remote Codex host:** Install and run the supported Codex remote workspace on the Linux server host. The ChatGPT Codex desktop app connects to it over SSH; supported sessions can then be accessed in the ChatGPT mobile app Remote view. Codex itself will not run inside a Docker container because direct SSH attachment to Codex inside Docker is not currently a supported remote-host workflow.
2. **Container services:** Docker Compose runs the Playwright MCP server and the Obsidian MCP server. A persistent bind-mounted Obsidian vault is the shared source of Markdown knowledge. GitHub MCP is configured for Codex with least-privilege GitHub authentication.
3. **Obsidian application:** A GUI Obsidian desktop application is not required in the headless server container. Codex and the Obsidian MCP work against the vault files. The setup guide must explain how the user can use/sync that vault with their Obsidian client and how any required Obsidian plugin or token is configured.
4. **Skills:** Add an Agent Skills-format Second Brain skill to the Codex environment, with instructions for capturing, linking, retrieving, and maintaining general and software-engineering knowledge in the vault. Select a maintained, widely used upstream package after verifying its source, license, and Codex-compatible format; adapt only as needed and attribute it.
5. **Persistence and access:** Persist the workspace, vault, Codex config, MCP config, and credentials through appropriate host paths or named volumes. Publish no unauthenticated MCP ports to the public internet. Document SSH key setup, server prerequisites, startup, health checks, backup, and mobile access.
6. **Existing stack:** Remove OpenCode, Discord bridge, and old agent configuration from this branch. Keep no unrelated legacy services.

## Acceptance criteria

- The branch is based on the current `main` and contains a clean replacement of the existing stack.
- A documented Linux server setup can install the supported Codex remote host and expose the intended project folder through SSH.
- The ChatGPT desktop Codex app can select the server workspace, and a supported session is reachable through ChatGPT mobile Remote.
- Docker Compose starts healthy GitHub, Obsidian, and Playwright MCP services with persistent vault and workspace data.
- The Codex config exposes those MCPs and the Second Brain skill.
- Secrets are excluded from Git; setup uses an example environment file and explicit least-privilege guidance.
- Build/config validation and available integration checks pass; documentation clearly lists any required manual authentication or first-time authorization.

## Constraints and open implementation decisions

- Remote SSH is the supported connection path; it requires a reachable SSH server and Codex installed/configured on the remote Linux host.
- The user’s phrase “log in to Obsidian” may mean Obsidian Sync or configuring the Obsidian MCP. The server does not need the GUI app to operate on a vault. The implementation must choose a usable vault-sync/auth model and document the exact one-time steps without requesting secrets in chat.
- Codex authentication, GitHub authentication, Obsidian vault access, and MCP process credentials must remain separate. Never bake credentials into the image or commit them.
- Before implementing the replacement, confirm the skill source and the exact authentication flow supported by the selected MCP servers.

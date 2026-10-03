# CodingAgent

A persistent OpenCode server configured with an Architect primary agent and a DeepSeek-powered Coder subagent. Architect uses Obra Superpowers to prepare a specification and implementation plan before delegating approved coding tasks.

Discord is available in two ways: a bot bridge lets authorized Discord users chat with the Architect, and a Discord MCP server gives OpenCode tools to read and operate on the configured server. The official GitHub MCP provides repository, issue, and pull request tools. A separate Playwright container gives the agent a real headless Chromium browser for web application testing.

## Requirements

- Docker Engine with the Compose plugin
- An OpenRouter API key with access to Claude Sonnet 5 and DeepSeek V3
- A Discord application and bot added to your private server
- A fine-grained GitHub Personal Access Token scoped to the repositories the agent should use

## Configure Discord and GitHub

1. In the Discord Developer Portal, create an application and add a bot.
2. Under Bot > Privileged Gateway Intents, enable Message Content Intent. The bridge needs this to read messages in your configured channel.
3. Under OAuth2 > URL Generator, select the bot scope and grant only View Channels, Read Message History, and Send Messages. Do not grant Administrator.
4. Invite the bot to your server.
5. In Discord, enable User Settings > Advanced > Developer Mode. Copy the server ID, a private channel ID, and your own user ID.
6. Create a fine-grained GitHub PAT. Select only the repositories the agent should access; grant Metadata read-only, Contents read/write, and Issues and Pull requests read/write if needed.
7. Copy .env.example to .env. Set the Discord and OpenRouter values, the OpenCode server password, and `GITHUB_PERSONAL_ACCESS_TOKEN`. Never send the GitHub token through Discord.

Messages from users or channels outside the configured allowlists are ignored. The bridge keeps one OpenCode conversation per Discord channel and saves the channel-to-session mapping in a Docker volume.

The Discord MCP integration is scoped to the configured server and allowed channels. MCP writes are disabled by default; set DISCORD_ALLOW_WRITES=true only if you want the Architect to perform ordinary Discord writes through MCP. Keep DISCORD_ALLOW_DESTRUCTIVE_ADMIN=false.

## Start

1. Put or clone the target project into workspace/.
2. Build and start the services:

   docker compose up -d --build

The services restart automatically unless stopped manually. OpenCode listens on 127.0.0.1:4096 by default and requires HTTP Basic authentication using the username and password from .env. The Discord bridge and Playwright MCP communicate with OpenCode over the private Compose network; neither publishes a host port.

## Use Discord, GitHub, and the browser

In Discord, send a message in an allowed channel or mention the bot. The bridge explicitly selects the `architect` agent and Claude Sonnet model for each message, then replies in the same channel.

The GitHub MCP is configured for repositories, issues, and pull requests. OpenCode's GitHub integration uses the PAT from `.env` (not the generic `/mcps` OAuth flow). After adding or changing the token, recreate the codingagent service. The same token is supplied to GitHub CLI so the agent can clone authorized repositories into `/workspace`.

The Architect prepares a specification and implementation plan; review and explicitly approve those before it delegates bounded implementation tasks to coder.

The `playwright` service runs Microsoft's Playwright MCP with headless Chromium. It shares `workspace/` for test artifacts under `workspace/test-results/`. To test an app in the codingagent container, start its development server bound to `0.0.0.0` on a port such as 3000; the browser can then reach it at `http://codingagent:3000`.

## Agent setup abilities

Both agents can run shell commands inside the OpenCode container. Architect can install requested npm tools, Python tools in virtual environments, standalone binaries, global skills, and MCP servers. Global MCP configuration and skills persist in Docker volumes. Run `opencode reload` after adding an MCP config so the running server connects it.

When an MCP needs credentials, the Architect gives the exact variable name and where to add it. Do not paste secrets into Discord. Add them to the server's `.env` and recreate the affected service so the environment is refreshed. Local MCP processes should be launched with only the environment variables they need.

npm global packages and their cache persist under `/home/opencode/.local/tools`. Python packages should be installed in virtual environments under that directory. Global OpenCode config and skills persist in the `opencode-config` volume; GitHub CLI credentials and OpenCode session data persist in `opencode-data`.

## Agent boundaries

The OpenCode container runs as the unprivileged `opencode` user, drops Linux capabilities, and has no Docker socket mount. The agents can change the OpenCode user's files, workspace, dependencies, skills, and persistent MCP configuration, and they can access the internet. They cannot install operating-system packages live or alter the Docker host. If a requested tool needs system libraries or root access, update the Dockerfile and rebuild the image.

OpenCode's edit permission rules do not constrain writes performed through shell commands. Architect is instructed not to edit application files, but that instruction is not a hard filesystem boundary while both agents share the writable workspace.

## Secrets and persistence

The .env file is local and must not be committed. Keep API keys and bot credentials out of Discord messages, shell command arguments, and JSON configuration files. The workspace and all OpenCode data/config/tool caches persist independently in bind mounts or Docker volumes.

# CodingAgent

A persistent OpenCode server configured with an Architect primary agent and a DeepSeek-powered Coder subagent. Architect uses Obra Superpowers to prepare a specification and implementation plan before delegating approved coding tasks.

Discord is available in two ways: a bot bridge lets authorized Discord users chat with the Architect, and a Discord MCP server gives OpenCode tools to read and operate on the configured server. The official GitHub MCP provides repository, issue, and pull request tools after you authorize it.

## Requirements

- Docker Engine with the Compose plugin
- An OpenRouter API key with access to Claude Sonnet 5 and DeepSeek V3
- A Discord application and bot added to your private server

## Configure Discord

1. In the Discord Developer Portal, create an application and add a bot.
2. Under Bot > Privileged Gateway Intents, enable Message Content Intent. The bridge needs this to read messages in your configured channel.
3. Under OAuth2 > URL Generator, select the bot scope and grant only View Channels, Read Message History, and Send Messages. Do not grant Administrator.
4. Invite the bot to your server.
5. In Discord, enable User Settings > Advanced > Developer Mode. Copy the server ID, a private channel ID, and your own user ID.
6. Copy .env.example to .env. Set the bot token, server ID, allowed user IDs, allowed channel IDs, OpenRouter key, and a strong OpenCode server password. IDs may be comma-separated.

Messages from users or channels outside the configured allowlists are ignored. The bridge keeps one OpenCode conversation per Discord channel and saves the channel-to-session mapping in a Docker volume. To start, mention the bot or send a message in an allowed channel.

The MCP integration is also enabled in OpenCode. It is scoped to the configured Discord server and allowed channels. MCP writes are disabled by default; set DISCORD_ALLOW_WRITES=true only if you want the Architect to perform ordinary Discord writes through MCP. Keep DISCORD_ALLOW_DESTRUCTIVE_ADMIN=false.

## Start

1. Put or clone the target project into workspace/.
2. Build and start the services:

   docker compose up -d --build

The services restart automatically unless stopped manually. OpenCode listens on 127.0.0.1:4096 and requires HTTP Basic authentication using the username and password from .env. The Discord bridge communicates with OpenCode over the private Compose network; it does not publish another host port.

## Use Discord and GitHub

In Discord, send a message in an allowed channel or mention the bot. The bridge creates or reuses that channel's OpenCode session, explicitly selects the `architect` agent and Claude Sonnet model, then replies in the same channel.

The GitHub MCP is configured for repositories, issues, and pull requests. To authorize it, open the OpenCode web UI, enter `/mcps`, choose `github`, and complete GitHub's OAuth flow. OpenCode stores the OAuth credentials in its persistent data volume. The Architect can then use those GitHub tools in Discord conversations.

For local Git operations, ask Architect to clone a repository into `/workspace`. GitHub CLI is installed for authenticated Git operations; if it needs a separate login, run `gh auth login --web` inside the container and finish the one-time browser/device authorization. The GitHub MCP and Git CLI share GitHub account permissions, but writing, pushing, or creating pull requests still requires your explicit instruction.

The Architect prepares a specification and implementation plan; review and explicitly approve those before it delegates bounded implementation tasks to coder.

## Agent setup abilities

Both agents can run shell commands inside the OpenCode container. Architect can install requested npm tools, Python tools in virtual environments, standalone binaries, global skills, and MCP servers. It can update the persistent global OpenCode config and run `opencode reload` to load a newly configured MCP without rebuilding the image.

When an MCP needs OAuth, the Architect guides you through OpenCode's `/mcps` interface. When it needs an API key, do not paste the secret into Discord: add it to the server's `.env` using the exact variable name Architect gives you, then recreate the service so the new variable is passed into the container. The Compose `env_file` makes added variables available to configured MCP processes. Local MCP processes should be launched with only the environment variables they need.

npm global packages and their cache persist under `/home/opencode/.local/tools`. Python packages should be installed in virtual environments under that directory. Global OpenCode config, installed skills, MCP definitions, and GitHub CLI credentials persist in the `opencode-config` volume. OpenCode session and OAuth data persist in `opencode-data`.

## Agent boundaries

The OpenCode container runs as the unprivileged `opencode` user, drops Linux capabilities, and has no Docker socket mount. The agents can change the OpenCode user's files, workspace, dependencies, skills, and persistent MCP configuration, and they can access the internet. They cannot install operating-system packages live or alter the Docker host. If a requested tool needs system libraries or root access, update the Dockerfile and rebuild the image.

OpenCode's edit permission rules do not constrain writes performed through shell commands. Architect is instructed not to edit application files, but that instruction is not a hard filesystem boundary while both agents share the writable workspace.

## Secrets and persistence

The .env file is local and must not be committed. Keep API keys and bot credentials out of Discord messages, shell command arguments, and JSON configuration files. The workspace and all OpenCode data/config/tool caches persist independently in bind mounts or Docker volumes.

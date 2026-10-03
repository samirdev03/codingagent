# CodingAgent

A persistent OpenCode server configured with an Architect primary agent and a DeepSeek-powered Coder subagent. Architect uses Obra Superpowers to prepare a specification and implementation plan before delegating approved coding tasks.

Discord is available in two ways: a bot bridge lets authorized Discord users chat with the Architect, and a Discord MCP server gives OpenCode tools to read and operate on the configured server.

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

## Use

Connect an OpenCode client to http://localhost:4096. In Discord, send a message in an allowed channel or mention the bot. The bridge forwards it to the architect agent and replies in the same channel. The Architect prepares a specification and implementation plan; review and explicitly approve those before it delegates bounded implementation tasks to coder.

## Agent boundaries

Both agents can run shell commands inside the OpenCode container. Architect uses shell for inspection and environment setup; its instructions still reserve application implementation for Coder. Coder uses shell to install project dependencies, download tools, and run approved implementation and verification commands.

The OpenCode container runs as the unprivileged `opencode` user, drops Linux capabilities, and has no Docker socket mount. npm global packages install under `/home/opencode/.local/tools/npm`, which is persisted in a Docker volume; Python packages should be installed in virtual environments under `/home/opencode/.local/tools` so they persist as well. Shell commands cannot install OS packages at runtime because the agent is not root; add those to the Dockerfile and rebuild.

OpenCode's edit permission rules do not constrain writes performed through shell commands. Architect is instructed not to edit application files, but that instruction is not a hard filesystem boundary while both agents share the writable workspace.

## Secrets and persistence

The .env file is local and must not be committed. The workspace, OpenCode session data, cache, and Discord channel session mappings persist independently in bind mounts or Docker volumes.

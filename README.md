# CodingAgent

A persistent OpenCode server configured with an Architect primary agent and a DeepSeek-powered Coder subagent. Architect uses Obra Superpowers to prepare a specification and implementation plan before delegating approved coding tasks.

## Requirements

- Docker Engine with the Compose plugin
- An OpenRouter API key with access to Claude Sonnet 5 and DeepSeek V3

## Start

1. Copy `.env.example` to `.env` and set a private OpenRouter key and a strong server password.
2. Put or clone the target project into `workspace/`.
3. Build and start the service:

   ```sh
   docker compose up -d --build
   ```

The service restarts automatically unless stopped manually. OpenCode listens on `127.0.0.1:4096` and requires HTTP Basic authentication using the username and password from `.env`.

## Use

Connect an OpenCode client to `http://localhost:4096`. Select the `architect` agent for new requests. Once the specification and plan are ready, review and explicitly approve them; Architect then uses Superpowers' subagent-driven development workflow to assign bounded implementation tasks to `coder`.

The workspace and OpenCode session data persist in Docker volumes. The `.env` file is local and must not be committed.

## Agent boundaries

Architect can read the project and write only under `docs/superpowers/specs/` and `docs/superpowers/plans/`. It cannot run shell commands or edit application files. Coder implements approved tasks in the workspace and reports the verification results to Architect.

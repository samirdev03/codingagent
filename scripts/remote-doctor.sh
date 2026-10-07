#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="${CODEX_PROJECT_DIR:-$DEFAULT_PROJECT_DIR}"
COMPOSE_FILE="${COMPOSE_FILE:-$PROJECT_DIR/compose.yaml}"
VAULT_DIR="${OBSIDIAN_VAULT_DIR:-$PROJECT_DIR/obsidian-vault}"
CODEX_BIN="${CODEX_BIN:-codex}"
DOCKER_BIN="${DOCKER_BIN:-docker}"

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

command -v "$CODEX_BIN" >/dev/null 2>&1 || fail "Codex CLI not found; run scripts/install-codex-host.sh"
command -v "$DOCKER_BIN" >/dev/null 2>&1 || fail "Docker Compose not found; install Docker Engine with the Compose plugin"
"$DOCKER_BIN" compose version >/dev/null 2>&1 || fail "Docker Compose not found; install the Docker Compose plugin"
[[ -d "$VAULT_DIR/.obsidian" ]] || fail "Obsidian vault is missing or lacks its .obsidian directory: $VAULT_DIR"
[[ -f "$COMPOSE_FILE" ]] || fail "Compose file not found: $COMPOSE_FILE"

"$PROJECT_DIR/scripts/validate-compose.sh" "$COMPOSE_FILE" "$PROJECT_DIR"
"$DOCKER_BIN" compose -f "$COMPOSE_FILE" config --quiet

if ! command -v gh >/dev/null 2>&1; then
  fail "GitHub CLI not found; install gh and authenticate with gh auth login"
fi
if ! gh auth status --hostname github.com >/dev/null 2>&1; then
  fail "GitHub CLI is not authenticated; run gh auth login --hostname github.com --git-protocol https --web"
fi

RUNNING_SERVICES="$("$DOCKER_BIN" compose -f "$COMPOSE_FILE" ps --services --filter status=running)"
for service in obsidian-mcp playwright; do
  if ! grep -Fxq "$service" <<<"$RUNNING_SERVICES"; then
    fail "Compose service '$service' is not running; start services with docker compose up -d --build"
  fi
done

printf 'Codex CLI: %s\n' "$("$CODEX_BIN" --version 2>/dev/null || printf 'available')"
printf 'Docker Compose: available\n'
printf 'Obsidian MCP vault: %s\n' "$VAULT_DIR"
printf 'Playwright and Obsidian MCP services: running\n'
printf 'GitHub CLI authentication: available\n'

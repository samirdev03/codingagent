#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCKER_BIN="${DOCKER_BIN:-docker}"
CONTAINER_NAME="${PLAYWRIGHT_CONTAINER_NAME:-codingagent-playwright}"

command -v "$DOCKER_BIN" >/dev/null 2>&1 || {
  printf 'Docker is not installed or not on PATH.\n' >&2
  exit 1
}

STATUS="$("$DOCKER_BIN" inspect --format '{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || true)"
if [[ "$STATUS" != healthy ]]; then
  printf 'Playwright MCP is not healthy (status: %s). Run docker compose up -d --build from %s.\n' "${STATUS:-not running}" "$ROOT_DIR" >&2
  exit 1
fi

printf 'Playwright MCP is healthy on 127.0.0.1:8931\n'

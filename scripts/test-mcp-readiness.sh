#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
MOCK_DOCKER="$TEMP_DIR/docker"
cat > "$MOCK_DOCKER" <<'MOCK'
#!/usr/bin/env sh
[ "$1" = inspect ] || exit 2
printf '%s\n' "${MOCK_PLAYWRIGHT_HEALTH:-healthy}"
MOCK
chmod +x "$MOCK_DOCKER"

DOCKER_BIN="$MOCK_DOCKER" bash "$ROOT_DIR/scripts/mcp/playwright-check.sh" >/dev/null
if DOCKER_BIN="$MOCK_DOCKER" MOCK_PLAYWRIGHT_HEALTH=starting bash "$ROOT_DIR/scripts/mcp/playwright-check.sh" >"$TEMP_DIR/out" 2>&1; then
  echo 'expected an unhealthy Playwright service to fail' >&2
  exit 1
fi
grep -q 'not healthy' "$TEMP_DIR/out"
printf 'MCP readiness checks passed\n'

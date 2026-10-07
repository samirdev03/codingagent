#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
MOCK_BIN="$TEMP_DIR/bin"
mkdir -p "$MOCK_BIN"

cat > "$MOCK_BIN/gh" <<'MOCK'
#!/usr/bin/env sh
case "$*" in
  'auth status --hostname github.com') exit "${MOCK_GH_AUTH_STATUS:-0}" ;;
  'auth token --hostname github.com') printf 'private-test-token\n' ;;
  *) exit 2 ;;
esac
MOCK
cat > "$MOCK_BIN/docker" <<'MOCK'
#!/usr/bin/env sh
[ "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" = private-test-token ] || exit 41
case " $* " in
  *' --env GITHUB_PERSONAL_ACCESS_TOKEN '*) ;;
  *) exit 42 ;;
esac
case " $* " in
  *private-test-token*) exit 43 ;;
esac
printf 'docker mock accepted token through environment\n'
MOCK
chmod +x "$MOCK_BIN/gh" "$MOCK_BIN/docker"

output="$(PATH="$MOCK_BIN:$PATH" bash "$ROOT_DIR/scripts/mcp/github.sh")"
[[ "$output" == *'accepted token through environment'* ]]
[[ "$output" != *'private-test-token'* ]]

if output="$(PATH="$MOCK_BIN:$PATH" MOCK_GH_AUTH_STATUS=1 bash "$ROOT_DIR/scripts/mcp/github.sh" 2>&1)"; then
  echo 'expected unauthenticated GitHub CLI to fail' >&2
  exit 1
fi
[[ "$output" == *'gh auth login'* ]]
[[ "$output" != *'private-test-token'* ]]
printf 'GitHub MCP auth checks passed\n'

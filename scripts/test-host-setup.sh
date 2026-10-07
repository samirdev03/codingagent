#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d "$ROOT_DIR/.host-setup-test.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT

MOCK_BIN="$TEMP_DIR/bin"
mkdir -p "$MOCK_BIN"
cat >"$MOCK_BIN/docker" <<'MOCK'
#!/usr/bin/env sh
if [ "$1" = compose ] && [ "$2" = config ]; then
  exit 0
fi
case "$*" in
  *"ps --services --filter status=running"*)
    printf 'obsidian-mcp\nplaywright\n'
    exit 0
    ;;
esac
exit 0
MOCK
cat >"$MOCK_BIN/codex" <<'MOCK'
#!/usr/bin/env sh
printf 'codex mock 1.0\n'
MOCK
cat >"$MOCK_BIN/gh" <<'MOCK'
#!/usr/bin/env sh
exit 0
MOCK
chmod +x "$MOCK_BIN/docker" "$MOCK_BIN/codex" "$MOCK_BIN/gh"

assert_failure() {
  local expected="$1"
  shift
  local output
  if output="$(env "$@" bash "$ROOT_DIR/scripts/remote-doctor.sh" 2>&1)"; then
    printf 'Expected doctor failure containing: %s\n' "$expected" >&2
    exit 1
  fi
  if [[ "$output" != *"$expected"* ]]; then
    printf 'Expected %q in doctor output, got:\n%s\n' "$expected" "$output" >&2
    exit 1
  fi
}

COMMON_ENV=(
  "PATH=$MOCK_BIN:$PATH"
  "CODEX_PROJECT_DIR=$ROOT_DIR"
  "COMPOSE_FILE=$ROOT_DIR/compose.yaml"
  "OBSIDIAN_VAULT_DIR=$ROOT_DIR/obsidian-vault"
  "DOCKER_BIN=$MOCK_BIN/docker"
  "CODEX_BIN=$MOCK_BIN/codex"
  "GITHUB_PERSONAL_ACCESS_TOKEN=must-not-be-printed"
)

assert_failure "Codex CLI not found" "${COMMON_ENV[@]/CODEX_BIN=*/CODEX_BIN=$TEMP_DIR/missing-codex}"
assert_failure "Docker Compose not found" "${COMMON_ENV[@]/DOCKER_BIN=*/DOCKER_BIN=$TEMP_DIR/missing-docker}"
assert_failure "Obsidian vault is missing" "${COMMON_ENV[@]/OBSIDIAN_VAULT_DIR=*/OBSIDIAN_VAULT_DIR=$TEMP_DIR/missing-vault}"

cat >"$TEMP_DIR/insecure-compose.yaml" <<'YAML'
services:
  obsidian-mcp:
    volumes:
      - ./obsidian-vault:/vault
  playwright:
    ports:
      - "0.0.0.0:8931:8931"
YAML
assert_failure "must be bound to 127.0.0.1" \
  "${COMMON_ENV[@]/COMPOSE_FILE=*/COMPOSE_FILE=$TEMP_DIR/insecure-compose.yaml}"

cat >"$TEMP_DIR/read-only-compose.yaml" <<'YAML'
services:
  obsidian-mcp:
    volumes:
      - ./obsidian-vault:/vault:ro
  playwright:
    ports:
      - "127.0.0.1:8931:8931"
YAML
assert_failure "Obsidian vault mount must be writable" \
  "${COMMON_ENV[@]/COMPOSE_FILE=*/COMPOSE_FILE=$TEMP_DIR/read-only-compose.yaml}"

output="$(env "${COMMON_ENV[@]}" bash "$ROOT_DIR/scripts/remote-doctor.sh")"
[[ "$output" == *'GitHub CLI authentication: available'* ]]
[[ "$output" == *'Playwright and Obsidian MCP services: running'* ]]
[[ "$output" != *'must-not-be-printed'* ]]

printf 'Host setup checks passed\n'

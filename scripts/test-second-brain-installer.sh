#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

SOURCE="$TEMP_DIR/source"
mkdir -p "$SOURCE/scripts" "$SOURCE/dist/agent-skills/skills/obsidian-core" "$SOURCE/dist/agent-skills/skills/obsidian-save"
git -C "$SOURCE" init -q
git -C "$SOURCE" config user.email test@example.invalid
git -C "$SOURCE" config user.name Test
echo 'source' > "$SOURCE/README.md"
echo 'MIT' > "$SOURCE/LICENSE"
cat > "$SOURCE/scripts/build.sh" <<'BUILD'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${FAKE_BUILD_OUTPUT:-yes}" == yes ]]; then
  mkdir -p "$(dirname "$0")/../dist/agent-skills/skills/obsidian-core" "$(dirname "$0")/../dist/agent-skills/skills/obsidian-save"
  printf '%s\n' '---' 'name: obsidian-core' 'description: core test skill' '---' > "$(dirname "$0")/../dist/agent-skills/skills/obsidian-core/SKILL.md"
  printf '%s\n' '---' 'name: obsidian-save' 'description: save test skill' '---' > "$(dirname "$0")/../dist/agent-skills/skills/obsidian-save/SKILL.md"
fi
BUILD
chmod +x "$SOURCE/scripts/build.sh"
git -C "$SOURCE" add .
git -C "$SOURCE" commit -qm fixture
REVISION="$(git -C "$SOURCE" rev-parse HEAD)"
DEST="$TEMP_DIR/destination"
mkdir -p "$DEST/.agents/skills/my-custom-skill"
echo custom > "$DEST/.agents/skills/my-custom-skill/SKILL.md"

SECOND_BRAIN_SOURCE_DIR="$SOURCE" SECOND_BRAIN_REVISION="$REVISION" SECOND_BRAIN_DEST_DIR="$DEST" bash "$ROOT_DIR/scripts/install-second-brain.sh" >/dev/null
[[ -f "$DEST/.agents/skills/obsidian-save/SKILL.md" ]]
[[ ! -e "$DEST/.agents/skills/obsidian-save/obsidian-save" ]]
[[ -f "$DEST/.agents/skills/obsidian-core/SKILL.md" ]]
[[ -f "$DEST/.agents/skills/my-custom-skill/SKILL.md" ]]
echo stale > "$DEST/.agents/skills/obsidian-save/obsolete.txt"
SECOND_BRAIN_SOURCE_DIR="$SOURCE" SECOND_BRAIN_REVISION="$REVISION" SECOND_BRAIN_DEST_DIR="$DEST" bash "$ROOT_DIR/scripts/install-second-brain.sh" >/dev/null
[[ ! -f "$DEST/.agents/skills/obsidian-save/obsolete.txt" ]]
[[ -f "$DEST/.agents/skills/my-custom-skill/SKILL.md" ]]

if SECOND_BRAIN_SOURCE_DIR="$SOURCE" SECOND_BRAIN_REVISION=does-not-exist SECOND_BRAIN_DEST_DIR="$DEST" bash "$ROOT_DIR/scripts/install-second-brain.sh" >"$TEMP_DIR/invalid.out" 2>&1; then
  echo 'expected invalid revision to fail' >&2
  exit 1
fi
grep -q 'not a commit' "$TEMP_DIR/invalid.out"

if SECOND_BRAIN_SOURCE_DIR="$SOURCE" SECOND_BRAIN_REVISION="$REVISION" SECOND_BRAIN_DEST_DIR="$DEST" FAKE_BUILD_OUTPUT=no bash "$ROOT_DIR/scripts/install-second-brain.sh" >"$TEMP_DIR/missing.out" 2>&1; then
  echo 'expected missing build output to fail' >&2
  exit 1
fi
grep -q 'build output is missing' "$TEMP_DIR/missing.out"
printf 'Second Brain installer checks passed\n'

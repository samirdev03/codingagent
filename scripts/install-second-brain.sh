#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_REVISION="87fe5437c44fffafb5188566d458891651536d4e"
REVISION="${SECOND_BRAIN_REVISION:-$DEFAULT_REVISION}"
SOURCE_URL="${SECOND_BRAIN_SOURCE_URL:-https://github.com/eugeniughelbur/obsidian-second-brain.git}"
DEST_DIR="${SECOND_BRAIN_DEST_DIR:-$PROJECT_DIR}"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

if [[ -n "${SECOND_BRAIN_SOURCE_DIR:-}" ]]; then
  SOURCE_DIR="$SECOND_BRAIN_SOURCE_DIR"
  [[ -d "$SOURCE_DIR/.git" ]] || fail "source directory is not a Git checkout: $SOURCE_DIR"
  git -C "$SOURCE_DIR" cat-file -e "$REVISION^{commit}" 2>/dev/null || fail "revision is not a commit: $REVISION"
  git -C "$SOURCE_DIR" archive "$REVISION" | tar -x -C "$TEMP_DIR"
else
  git clone --quiet --no-checkout "$SOURCE_URL" "$TEMP_DIR/source-repo"
  git -C "$TEMP_DIR/source-repo" fetch --quiet --depth 1 origin "$REVISION" || fail "could not fetch pinned revision: $REVISION"
  git -C "$TEMP_DIR/source-repo" checkout --quiet --detach FETCH_HEAD
  git -C "$TEMP_DIR/source-repo" archive HEAD | tar -x -C "$TEMP_DIR"
fi

SOURCE_ROOT="$TEMP_DIR"
[[ -x "$SOURCE_ROOT/scripts/build.sh" ]] || fail "pinned source is missing scripts/build.sh"
bash "$SOURCE_ROOT/scripts/build.sh" --platform agent-skills
SKILLS_DIR="$SOURCE_ROOT/dist/agent-skills/skills"
[[ -d "$SKILLS_DIR" ]] || fail "build output is missing: $SKILLS_DIR"
find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -name SKILL.md -print -quit | grep -q . || fail "build output is missing skill files"

# The upstream generator can emit trailing whitespace; normalize its text files
# so the vendored build passes the repository's whitespace checks.
python3 - "$SKILLS_DIR" <<'PY'
from pathlib import Path
import sys

for path in Path(sys.argv[1]).rglob("*"):
    if not path.is_file():
        continue
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue
    normalized = "\n".join(line.rstrip() for line in text.splitlines()).rstrip("\n") + "\n"
    path.write_text(normalized, encoding="utf-8")
PY

SKILLS_DEST="$DEST_DIR/.agents/skills"
PACKAGE_META="$DEST_DIR/third_party/obsidian-second-brain"
MANIFEST="$PACKAGE_META/installed-skills.txt"
mkdir -p "$SKILLS_DEST" "$PACKAGE_META"

# Replace only skill directories recorded by the previous package install.
# Unrelated local skills in .agents/skills remain untouched.
if [[ -f "$MANIFEST" ]]; then
  while IFS= read -r name; do
    [[ "$name" =~ ^[A-Za-z0-9_-]+$ ]] || fail "invalid skill name in install manifest: $name"
    rm -rf "$SKILLS_DEST/$name"
  done < "$MANIFEST"
fi

: > "$MANIFEST"
for skill_dir in "$SKILLS_DIR"/*/; do
  [[ -d "$skill_dir" ]] || continue
  basename "$skill_dir" >> "$MANIFEST"
done
sort -o "$MANIFEST" "$MANIFEST"
while IFS= read -r name; do
  [[ "$name" =~ ^[A-Za-z0-9_-]+$ ]] || fail "invalid skill directory name: $name"
  mkdir -p "$SKILLS_DEST/$name"
  cp -R "$SKILLS_DIR/$name/." "$SKILLS_DEST/$name/"
done < "$MANIFEST"
cp "$SOURCE_ROOT/LICENSE" "$PACKAGE_META/LICENSE"
printf 'Installed obsidian-second-brain Agent Skills at revision %s\n' "$REVISION"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT_DIR" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
skills_root = root / ".agents/skills"
skills = sorted(p for p in skills_root.iterdir() if p.is_dir())
if len(skills) < 40:
    raise SystemExit(f"Expected the upstream Agent Skills build, found only {len(skills)} skill directories")

for skill in skills:
    skill_file = skill / "SKILL.md"
    if not skill_file.is_file():
        raise SystemExit(f"Missing SKILL.md: {skill_file.relative_to(root)}")
    text = skill_file.read_text(encoding="utf-8")
    frontmatter = re.match(r"\A---\n(.*?)\n---\n", text, flags=re.DOTALL)
    if not frontmatter:
        raise SystemExit(f"Invalid or missing YAML frontmatter: {skill_file.relative_to(root)}")
    name = re.search(r"^name:\s*([A-Za-z0-9_-]+)\s*$", frontmatter.group(1), re.MULTILINE)
    description = re.search(r"^description:\s*.+$", frontmatter.group(1), re.MULTILINE)
    if not name or name.group(1) != skill.name or not description:
        raise SystemExit(f"Invalid Agent Skills metadata: {skill_file.relative_to(root)}")
    for path in re.findall(r"`(\.agents/skills/obsidian-core/[^`]+)`", text):
        candidate = root / path.rstrip(".,:;)")
        if not candidate.exists():
            raise SystemExit(f"Broken skill path in {skill_file.relative_to(root)}: {path}")

notice = root / "third_party/obsidian-second-brain/NOTICE.md"
license_file = root / "third_party/obsidian-second-brain/LICENSE"
if not notice.is_file() or not license_file.is_file() or "MIT" not in license_file.read_text(encoding="utf-8"):
    raise SystemExit("Missing MIT attribution or license for the vendored package")
print(f"Second Brain validation passed: {len(skills)} Agent Skills, metadata and local paths valid")
PY

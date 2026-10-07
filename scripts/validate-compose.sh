#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${1:-$ROOT_DIR/compose.yaml}"
PROJECT_ROOT="${2:-$ROOT_DIR}"

python3 - "$COMPOSE_FILE" "$PROJECT_ROOT" <<'PY'
from pathlib import Path
import re
import subprocess
import sys

compose_path, project_root = Path(sys.argv[1]), Path(sys.argv[2])
compose = compose_path.read_text(encoding="utf-8")

required = ("playwright", "obsidian-mcp")
for service in required:
    if not re.search(rf"^  {re.escape(service)}:\s*$", compose, re.MULTILINE):
        raise SystemExit(f"Missing required Compose service: {service}")

vault_mount = re.search(r"^\s+-\s+['\"]?\./obsidian-vault:/vault(?::([^'\"\s]+))?['\"]?\s*$", compose, re.MULTILINE)
if not vault_mount:
    raise SystemExit("Obsidian vault must be mounted persistently at /vault")
if vault_mount.group(1) and "ro" in vault_mount.group(1).split(","):
    raise SystemExit("Obsidian vault mount must be writable")

for line_number, line in enumerate(compose.splitlines(), start=1):
    port = re.match(r"^\s+-\s+['\"]?([^:]+):(\d+):(\d+)", line)
    if port and port.group(1) != "127.0.0.1":
        raise SystemExit(f"Published port must be bound to 127.0.0.1 (compose.yaml:{line_number})")
    if re.match(r"^\s+-\s+['\"]?\d+:(\d+)(?:['\"])?$", line):
        raise SystemExit(f"Published port must bind explicitly to loopback (compose.yaml:{line_number})")

for path in (".env", "obsidian-vault/Private note.md"):
    result = subprocess.run(
        ["git", "check-ignore", "--no-index", "-q", path],
        cwd=project_root,
        check=False,
    )
    if result.returncode != 0:
        raise SystemExit(f"Sensitive path is not ignored by .gitignore: {path}")

print("Compose safety checks passed")
PY

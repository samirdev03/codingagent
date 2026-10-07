#!/usr/bin/env bash
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  printf 'GitHub CLI is required. Install gh and authenticate with: gh auth login --hostname github.com --git-protocol https --web\n' >&2
  exit 1
fi

if ! gh auth status --hostname github.com >/dev/null 2>&1; then
  printf 'GitHub is not authenticated on this host. Run: gh auth login --hostname github.com --git-protocol https --web\n' >&2
  exit 1
fi

GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token --hostname github.com)"
if [[ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ]]; then
  printf 'GitHub CLI returned no authentication token. Run gh auth login again.\n' >&2
  exit 1
fi
export GITHUB_PERSONAL_ACCESS_TOKEN

exec docker run --interactive --rm --env GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server:1.14.0

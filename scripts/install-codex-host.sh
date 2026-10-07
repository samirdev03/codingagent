#!/usr/bin/env bash
set -euo pipefail

if ! command -v npm >/dev/null 2>&1; then
  printf 'Install Node.js 22 or newer (including npm), then rerun this script.\n' >&2
  exit 1
fi

CODEX_NPM_PREFIX="$HOME/.local"
PROFILE_LINE='export PATH="$HOME/.local/bin:$PATH"'
mkdir -p "$CODEX_NPM_PREFIX/bin"
npm config set prefix "$CODEX_NPM_PREFIX"
npm install --global @openai/codex@latest

for profile in "$HOME/.profile" "$HOME/.bashrc" "$HOME/.bash_profile"; do
  touch "$profile"
  if ! grep -Fq "$PROFILE_LINE" "$profile"; then
    printf '\n# Codex CLI for SSH remote workspaces\n%s\n' "$PROFILE_LINE" >>"$profile"
  fi
done

export PATH="$CODEX_NPM_PREFIX/bin:$PATH"
command -v codex >/dev/null 2>&1 || {
  printf 'Codex was installed but is not on PATH: %s/bin\n' "$CODEX_NPM_PREFIX" >&2
  exit 1
}

printf 'Installed Codex CLI: %s\n' "$(codex --version)"
printf 'Next: authenticate Codex with your ChatGPT account using codex login.\n'
printf 'Install GitHub CLI (gh) from https://cli.github.com/ if needed, then run: gh auth login --hostname github.com --git-protocol https --web\n'
printf 'Then add this server as an SSH connection in the Codex desktop app.\n'

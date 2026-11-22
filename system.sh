#!/usr/bin/env bash
# System-level setup. Needs root: run as `sudo ~/dotfiles/system.sh`.
# Idempotent: safe to re-run.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi
TARGET_USER="${SUDO_USER:?run via sudo from your normal user, not as root directly}"
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> apt packages"
apt-get update -y
grep -vE '^\s*(#|$)' "$DOTFILES/packages/apt.txt" | xargs apt-get install -y

echo "==> gh (official GitHub apt repo)"
if [[ ! -f /etc/apt/sources.list.d/github-cli.list ]]; then
  mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
  chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list
  apt-get update -y
fi
apt-get install -y gh

echo "==> default shell -> zsh for $TARGET_USER"
ZSH_PATH="$(command -v zsh)"
if [[ "$(getent passwd "$TARGET_USER" | cut -d: -f7)" != "$ZSH_PATH" ]]; then
  chsh -s "$ZSH_PATH" "$TARGET_USER"
fi

echo "==> system.sh done"

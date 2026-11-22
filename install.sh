#!/usr/bin/env bash
# User-level setup. No sudo. Run after system.sh: `~/dotfiles/install.sh`.
# Idempotent: safe to re-run. Existing files it replaces are moved to ~/.dotfiles-backup/<timestamp>/.
set -eo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
NVM_VERSION="v0.40.3"
NODE_MAJOR="24"

if [[ $EUID -eq 0 ]]; then
  echo "Do not run install.sh as root." >&2
  exit 1
fi
for cmd in git curl zsh tmux; do
  command -v "$cmd" >/dev/null || { echo "Missing $cmd. Run: sudo $DOTFILES/system.sh" >&2; exit 1; }
done

backup() {
  mkdir -p "$BACKUP/$(dirname "$1")"
  mv "$HOME/$1" "$BACKUP/$1"
  echo "    backed up ~/$1 -> $BACKUP/$1"
}

echo "==> oh-my-zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "==> nvm + node $NODE_MAJOR"
export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  # PROFILE=/dev/null: don't let the installer edit rc files; .zshrc already loads nvm.
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | PROFILE=/dev/null bash
fi
. "$NVM_DIR/nvm.sh"
# Only when missing: re-running must not move the default to a node without your globals.
nvm ls "$NODE_MAJOR" >/dev/null 2>&1 || nvm install "$NODE_MAJOR"
nvm alias default >/dev/null 2>&1 || nvm alias default "$NODE_MAJOR"
nvm use default >/dev/null

echo "==> pnpm (via corepack)"
corepack enable pnpm

echo "==> link dotfiles"
cd "$DOTFILES/home"
find . -type f ! -path './.claude/settings.json' | sed 's|^\./||' | while read -r rel; do
  src="$DOTFILES/home/$rel"; dst="$HOME/$rel"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then continue; fi
  [[ -e "$dst" || -L "$dst" ]] && backup "$rel"
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "    linked ~/$rel"
done
cd - >/dev/null

# Merged, not symlinked: Claude Code rewrites this file itself and would clobber a symlink.
# Repo keys win; keys only on this machine (autoMode, statusLine, ...) are kept.
echo "==> Claude Code settings.json (merged)"
rel=".claude/settings.json"
mkdir -p "$HOME/.claude"
[[ -e "$HOME/$rel" ]] || echo '{}' > "$HOME/$rel"
merged="$(node -e '
  const fs = require("fs");
  const repo = JSON.parse(fs.readFileSync(process.argv[1]));
  const live = JSON.parse(fs.readFileSync(process.argv[2]));
  process.stdout.write(JSON.stringify({ ...live, ...repo }, null, 2) + "\n");
' "$DOTFILES/home/$rel" "$HOME/$rel")"
if [[ "$merged" != "$(cat "$HOME/$rel")" ]]; then
  mkdir -p "$BACKUP/.claude" && cp "$HOME/$rel" "$BACKUP/$rel"
  echo "    backed up ~/$rel -> $BACKUP/$rel"
  printf '%s' "$merged" > "$HOME/$rel"
  echo "    merged repo settings into ~/$rel"
fi

echo "==> git identity (~/.gitconfig.local)"
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
  if gh auth status >/dev/null 2>&1; then
    gh api user --jq '"[user]\n\tname = \(.name // .login)\n\temail = \(.id)+\(.login)@users.noreply.github.com"' \
      > "$HOME/.gitconfig.local"
    echo "    wrote ~/.gitconfig.local with your GitHub noreply email (edit it to use another email)"
  else
    echo "    SKIPPED: gh is not logged in. Run 'gh auth login', then re-run install.sh." >&2
  fi
fi

echo "==> tmux plugins (TPM)"
TPM="$HOME/.config/tmux/plugins/tpm"
[[ -d "$TPM" ]] || git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM"
"$TPM/bin/install_plugins"

echo "==> install.sh done. Now run: $DOTFILES/verify.sh"

#!/usr/bin/env bash
# Checks the environment matches the dotfiles. Exit code = number of failures.
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fail=0
ok()  { echo "  ok    $1"; }
bad() { echo "  FAIL  $1"; fail=$((fail+1)); }
check() { if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }

export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.local/bin:$HOME/.local/share/pnpm:$PATH"

echo "commands"
for c in zsh tmux git gh node npm pnpm claude; do check "$c" "command -v $c"; done

echo "versions"
check "node is v24.x" '[[ "$(node -v)" == v24.* ]]'
check "default shell is zsh" '[[ "$(getent passwd "$USER" | cut -d: -f7)" == */zsh ]]'

echo "auth"
check "gh logged in" "gh auth status"
check "git identity set" "git config user.email"

echo "dotfiles"
cd "$DOTFILES/home"
while read -r rel; do
  check "~/$rel -> repo" "[[ \"\$(readlink \"$HOME/$rel\")\" == \"$DOTFILES/home/$rel\" ]]"
done < <(find . -type f ! -path './.claude/settings.json' | sed 's|^\./||')
check "~/.claude/settings.json has repo keys" "node -e '
  const fs = require(\"fs\");
  const repo = JSON.parse(fs.readFileSync(process.argv[1]));
  const live = JSON.parse(fs.readFileSync(process.argv[2]));
  const bad = Object.keys(repo).filter(k => JSON.stringify(repo[k]) !== JSON.stringify(live[k]));
  process.exit(bad.length ? 1 : 0);
' '$DOTFILES/home/.claude/settings.json' '$HOME/.claude/settings.json'"

echo "plugins"
check "oh-my-zsh" "[[ -d $HOME/.oh-my-zsh ]]"
check "tmux catppuccin plugin" "[[ -d $HOME/.config/tmux/plugins/tmux ]]"
check "zsh starts cleanly" '[[ -z "$(zsh -i -c exit 2>&1 >/dev/null)" ]]'

echo
if [[ $fail -eq 0 ]]; then echo "All checks passed."; else echo "$fail check(s) failed."; fi
exit $fail

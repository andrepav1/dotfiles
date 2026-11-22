# dotfiles

Minimal WSL (Ubuntu) dev environment: zsh + oh-my-zsh, git, tmux (catppuccin), nvm/node 24, pnpm, gh, Claude Code.

## New laptop

In a fresh WSL Ubuntu terminal:

```sh
# 1. Get access to this private repo (Ubuntu's gh is old, but fine for bootstrapping)
sudo apt-get update && sudo apt-get install -y git gh
gh auth login            # GitHub.com -> HTTPS -> yes to git credentials -> browser
gh repo clone andrepav1/dotfiles ~/dotfiles

# 2. System part (needs your password)
sudo ~/dotfiles/system.sh

# 3. Claude Code, then let it do the rest
curl -fsSL https://claude.ai/install.sh | bash
cd ~/dotfiles && ~/.local/bin/claude
```

Then tell Claude:

> Set up my environment from this repo. Follow CLAUDE.md until verify.sh passes.

Or skip the agent and run `~/dotfiles/install.sh && ~/dotfiles/verify.sh` yourself.

Afterwards, open a new terminal (zsh is now your default shell).

## Not in this repo, on purpose
Git identity (`~/.gitconfig.local`; install.sh creates it with your GitHub noreply email), secrets (SSH keys, npm token, CLI credentials), shell history, Claude Code custom instructions (`~/.claude/CLAUDE.md`), session state and memory, project-specific Claude hooks and settings. See the "Manual steps" section in `CLAUDE.md`.

## Changing config
Files in `home/` are symlinked, so editing `~/.zshrc` edits the repo. Commit from `~/dotfiles`.
Exception: `~/.claude/settings.json` is merged, not linked. The repo holds the portable keys, and machine-only keys (`autoMode`, `statusLine`) stay local. To change a portable key, edit `home/.claude/settings.json` and re-run `install.sh`.

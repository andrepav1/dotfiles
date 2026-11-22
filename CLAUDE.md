# Dotfiles: agent setup instructions

You are setting up the user's WSL (Ubuntu) dev environment on a fresh machine from this repo.
Goal: `./verify.sh` exits 0.

## Layout
- `home/` mirrors `$HOME`. Every file is symlinked into place, except `home/.claude/settings.json`, which is merged into the existing file: repo keys win and machine-only keys stay. (Claude Code rewrites that file and would break a symlink.)
- `system.sh`: needs sudo (apt packages, gh, default shell). **You cannot run it.** You can't enter the sudo password, and sudo credentials don't carry over between your shell calls.
- `install.sh`: no sudo (oh-my-zsh, nvm + node 24, pnpm, symlinks, tmux plugins, git identity). You run this one.
- `verify.sh`: checks everything. Exit code = number of failures.
- `packages/apt.txt`: the apt package list.

## Procedure
1. Run `./verify.sh` to see the current state.
2. If `zsh`, `tmux` or `gh` is missing, or the default shell isn't zsh: stop and ask the user to run
   `! sudo ~/dotfiles/system.sh` (or to run it in a separate terminal if the password prompt doesn't work in Claude Code). Wait for confirmation.
3. Run `./install.sh`. It's idempotent, so re-run it after fixing anything.
4. Run `./verify.sh`. Fix failures and repeat until it passes.
5. Tell the user what's left that only they can do (see below), then tell them to open a new terminal so zsh loads.

## Rules
- Never delete user files. `install.sh` moves anything it replaces into `~/.dotfiles-backup/<timestamp>/`, so keep it that way.
- Don't add tools, aliases or config that aren't in this repo. This repo is deliberately minimal: config only, with no Claude skills, subagents, plugins or project references.
- If you change a script to fix a real bug, keep it idempotent and tell the user, so they can commit the fix.
- Don't commit or push unless the user asks.

## Manual steps (user only, not in this repo on purpose)
- SSH keys: not needed for GitHub, which uses HTTPS through gh. If something needs SSH, create a new key on this machine (`ssh-keygen -t ed25519`) and add it with `gh ssh-key add ~/.ssh/id_ed25519.pub`. Don't copy private keys between machines.
- npm token: only needed to publish packages. Run `npm login`.
- Logins for any other CLIs.
- Docker: use Docker Desktop on Windows with WSL integration turned on. Nothing to install in WSL.

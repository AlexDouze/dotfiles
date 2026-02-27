# Dotfiles

Automated macOS setup using **Homebrew** for packages and **chezmoi** for dotfile management.

## What's Included

- **Shell** — Zsh + Oh My Zsh + Starship prompt
- **Git** — multi-profile (work/personal), GPG commit signing
- **Kubernetes** — k9s with plugins, skins, aliases, and hotkeys
- **Editor** — VS Code settings and extensions
- **Terminal utilities** — bat, ripgrep, fzf, and more
- **AI tooling** — Claude Code + Bifrost MCP gateway
- **GPG/SSH** — gpg-agent configuration
- **Brewfile** — ~100 formulae, ~50 casks

## Scripts

| Script | Description |
|---------|-------------|
| `setup` | Bootstrap a fresh machine: installs Homebrew, bundles packages, applies chezmoi, installs Oh My Zsh, updates macOS, and enables Touch ID sudo |
| `save` | Snapshots current state: dumps Brewfile, re-adds chezmoi changes, and optionally commits + pushes |
| `cleanup` | Lists Homebrew packages not in Brewfile and optionally uninstalls them |

## Installation

```sh
git clone <repo-url> ~/.dotfiles
cd ~/.dotfiles
./setup
```

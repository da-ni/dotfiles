# Omarchy Dotfiles

Personal dotfiles for a unified Omarchy setup across devices.

This repo uses a hybrid approach:

1. Own selected files directly via GNU Stow (`bash`, `hypr`, `waybar`, `scripts`, `zellij`, `omarchy`, `ghostty`).
2. Extend Omarchy-managed Hypr config by appending a managed `source` block to `~/.config/hypr/hyprland.conf`.

This keeps Omarchy update-friendly while still allowing deep customization.

## Docs

Reference notes live in `docs/` for setup tasks we may need again.

- `docs/custom-webapp-icons.md`: Add icons for custom Chromium web apps in Waybar/Hyprland.
- `docs/terminal-ide.md`: Terminal IDE workspace (`ws`) with Zellij + Helix + OpenCode.
- `docs/waybar-weather.md`: Weather module behavior and troubleshooting.

## What this repo manages

### Stowed files

- `~/.bashrc`
- `~/.config/hypr/hypridle.conf`
- `~/.config/hypr/hyprsunset.conf`
- `~/.config/hypr/custom/autostart.conf`
- `~/.config/hypr/custom/bindings.conf`
- `~/.config/hypr/custom/input.conf`
- `~/.config/hypr/custom/looknfeel.conf`
- `~/.config/hypr/custom/monitors.conf`
- `~/.config/waybar/config.jsonc`
- `~/.config/waybar/style.css`
- `~/.config/waybar/modules/*.jsonc`
- `~/.config/waybar/cava.sh`
- `~/.config/waybar/net_speed.sh`
- `~/.config/waybar/waybar-gpu.sh`
- `~/.config/ghostty/config`
- `~/.local/bin/toggle-mirror.sh`
- `~/.local/bin/ws`
- `~/.local/bin/ws-add-project`
- `~/.local/bin/ws-help`
- `~/.local/bin/omarchy-zellij-theme-set`
- `~/.config/zellij/ws-config.kdl`
- `~/.config/zellij/layouts/home-stack.kdl`
- `~/.config/zellij/layouts/studio.kdl`
- `~/.config/zellij/layouts/project-stack.kdl`
- `~/.config/omarchy/themed/zellij.kdl.tpl`

### Omarchy hook injection target

`bootstrap.sh` ensures exactly one managed block exists in:

- `~/.config/hypr/hyprland.conf`
- `~/.config/omarchy/hooks/theme-set`

Managed block:

```ini
# >>> dotfiles-managed custom hooks >>>
source = ~/.config/hypr/custom/*
# <<< dotfiles-managed custom hooks <<<
```

```bash
# >>> dotfiles-managed omarchy-zellij-theme >>>
if command -v omarchy-zellij-theme-set >/dev/null 2>&1; then
  omarchy-zellij-theme-set "$@"
fi
# <<< dotfiles-managed omarchy-zellij-theme <<<
```

Before adding, `bootstrap.sh` removes any previous managed block so repeated runs stay idempotent.

If `~/.config/hypr/hyprland.conf` is missing, bootstrap exits with guidance to restore it via Omarchy (`Update > Config`).

## Prerequisites

Required:

- Omarchy
- `stow`
- `python3`
- `zellij`
- `helix`

Optional/runtime tools used by some configured modules/scripts:

- `hyprctl`, `jq`, `notify-send` (`toggle-mirror.sh`)
- `flock` (optional lock for concurrent toggle protection)
- `cava`, `playerctl` (Waybar spectrum module)
- `curl`, `jq` (weather module via Open-Meteo)
- `nvidia-smi` (GPU module; degrades gracefully if missing)
- `bc`, `ip` (network speed module)
- `opencode` (AI pane in terminal workspace)
- `zoxide`, `fzf` (project picker)
- `lazygit` (`ws git` and `Alt-w` floating git UI)
- `yazi` (optional folder picker mode for `ws-add-project --yazi`)

## Installation and usage

From repo root:

```bash
./bootstrap.sh --dry-run
./bootstrap.sh --apply
```

### Modes

- `--apply` (default): stow packages, ensure script execute bits, then apply managed hook blocks
- `--dry-run`: preview stow changes and print hook block action
- `--install`: back up conflicting target files to `~/.dotfiles-backup-<timestamp>/`, then apply
- `--check`: stow conflict check only (exit code `2` on conflict)
- `--uninstall`: unstow managed files and remove managed hook blocks

## Updating

When you change files in this repo, rerun:

```bash
./bootstrap.sh --apply
```

That reapplies symlinks, refreshes the managed hook block, and re-applies script permissions.

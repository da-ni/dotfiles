# Omarchy Dotfiles

Personal dotfiles for a unified Omarchy setup across devices.

This repo uses a hybrid approach:

1. Own selected files directly via GNU Stow (`bash`, `hypr`, `waybar`, `scripts`).
2. Extend Omarchy-managed Hypr config by appending a managed `source` block to `~/.config/hypr/hyprland.conf`.

This keeps Omarchy update-friendly while still allowing deep customization.

## Docs

Reference notes live in `docs/` for setup tasks we may need again.

- `docs/custom-webapp-icons.md`: Add icons for custom Chromium web apps in Waybar/Hyprland.

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
- `~/.local/bin/toggle-mirror.sh`

### Omarchy hook injection target

`bootstrap.sh` ensures exactly one managed block exists in:

- `~/.config/hypr/hyprland.conf`

Managed block:

```ini
# >>> dotfiles-managed custom hooks >>>
source = ~/.config/hypr/custom/*
# <<< dotfiles-managed custom hooks <<<
```

Before adding, `bootstrap.sh` removes any previous managed block so repeated runs stay idempotent.

If `~/.config/hypr/hyprland.conf` is missing, bootstrap exits with guidance to restore it via Omarchy (`Update > Config`).

## Prerequisites

Required:

- Omarchy
- `stow`
- `python3`

Optional/runtime tools used by some configured modules/scripts:

- `hyprctl`, `jq`, `notify-send` (`toggle-mirror.sh`)
- `flock` (optional lock for concurrent toggle protection)
- `cava`, `playerctl` (Waybar spectrum module)
- `wttrbar`, `curl` (weather module)
- `nvidia-smi` (GPU module; degrades gracefully if missing)
- `bc`, `ip` (network speed module)

## Installation and usage

From repo root:

```bash
./bootstrap.sh --dry-run
./bootstrap.sh --apply
```

### Modes

- `--apply` (default): stow packages, ensure script execute bits, then apply Hypr hook block
- `--dry-run`: preview stow changes and print hook block action
- `--install`: back up conflicting target files to `~/.dotfiles-backup-<timestamp>/`, then apply
- `--check`: stow conflict check only (exit code `2` on conflict)
- `--uninstall`: unstow managed files and remove managed hook block from `hyprland.conf`

## Updating

When you change files in this repo, rerun:

```bash
./bootstrap.sh --apply
```

That reapplies symlinks, refreshes the managed hook block, and re-applies script permissions.

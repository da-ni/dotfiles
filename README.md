# Omarchy Dotfiles

Personal dotfiles for an Omarchy setup.

This repo uses a hybrid approach:

1. Own selected files directly via GNU Stow (`bash`, `hypr`, `waybar`, `ghostty`).
2. Extend Omarchy-managed Hypr config by appending a managed `source` block to `~/.config/hypr/hyprland.conf`.

This keeps Omarchy update-friendly while still allowing local customization.

## Docs

Reference notes live in `docs/` for setup tasks we may need again.

- `docs/custom-webapp-icons.md`: Add icons for custom Chromium web apps in Waybar/Hyprland.

## What this repo manages

### Stowed files

- `~/.bashrc`
- `~/.config/hypr/hyprsunset.conf`
- `~/.config/hypr/custom/autostart.conf`
- `~/.config/hypr/custom/bindings.conf`
- `~/.config/hypr/custom/input.conf`
- `~/.config/waybar/config.jsonc`
- `~/.config/waybar/style.css`
- `~/.config/waybar/cava.sh`
- `~/.config/waybar/mpris.sh`
- `~/.config/ghostty/config`

### Omarchy hook injection target

`bootstrap.sh` ensures exactly one managed block exists in `~/.config/hypr/hyprland.conf`:

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

Optional/runtime tools used by some Waybar modules:

- `cava`, `playerctl` (Waybar MPRIS + spectrum modules)

## Installation and usage

From repo root:

```bash
./bootstrap.sh --dry-run
./bootstrap.sh --apply
```

### Modes

- `--apply` (default): stow packages, ensure script execute bits, then apply managed hook block
- `--dry-run`: preview stow changes and print hook block action
- `--install`: back up conflicting target files to `~/.dotfiles-backup-<timestamp>/`, then apply
- `--check`: stow conflict check only (exit code `2` on conflict)
- `--uninstall`: unstow managed files and remove managed hook block

## Updating

When you change files in this repo, rerun:

```bash
./bootstrap.sh --apply
```

That reapplies symlinks, refreshes the managed hook block, and re-applies script permissions.

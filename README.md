# Omarchy Dotfiles

Personal dotfiles for a unified Omarchy setup across devices.

This repo follows a hybrid approach:

1. Own selected files directly via GNU Stow (bash, waybar, Hypr custom files, scripts).
2. Extend Omarchy-managed Hypr files by appending managed `source` hook blocks, instead of replacing Omarchy defaults.

This keeps Omarchy update-friendly while still allowing deep customization.

## What This Repo Manages

### Stowed files

- `~/.bashrc`
- `~/.config/hypr/hypridle.conf`
- `~/.config/hypr/hyprsunset.conf`
- `~/.config/hypr/custom/*.conf`
- `~/.config/waybar/*`
- `~/.local/bin/toggle-mirror.sh`

### Omarchy hook injection targets

`bootstrap.sh` ensures a managed block exists in:

- `~/.config/hypr/autostart.conf`
- `~/.config/hypr/bindings.conf`
- `~/.config/hypr/input.conf`
- `~/.config/hypr/looknfeel.conf`
- `~/.config/hypr/monitors.conf`

Each block sources your corresponding custom file in `~/.config/hypr/custom/`.

## Prerequisites

- Omarchy
- `stow` (GNU Stow)

Optional/runtime tools used by configured components:

## Installation and Usage

From repo root:

```bash
./bootstrap.sh --dry-run
```

### Modes

- `--apply` (default): preview, then stow, then apply hook updates
- `--dry-run`: preview only
- `--install`: back up conflicting files, then apply
- `--check`: list stow conflicts only (exit code `2` if conflicts exist)
- `--uninstall`: unstow managed files and remove managed hook blocks

## How the Hook Strategy Works

Omarchy continues owning its base files (for safer updates), while this repo appends a managed section like:

```ini
# >>> dotfiles-managed custom hooks >>>
source = ~/.config/hypr/custom/<name>.conf
# <<< dotfiles-managed custom hooks <<<
```

Before adding, `bootstrap.sh` removes any previous managed block, so repeated runs stay idempotent.

If target Omarchy files are missing, bootstrap exits with guidance to restore them via Omarchy (`Update > Config`).

## Updating

When you change files in this repo, rerun:

```bash
./bootstrap.sh --apply
```

That reapplies symlinks and refreshes managed hook blocks safely.

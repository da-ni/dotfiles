# Omarchy Dotfiles (GNU Stow + Source Hooks)

Personal dotfiles for a custom Omarchy setup.

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

## Repository Layout

```text
dotfiles/
├── bootstrap.sh
├── bash/
│   └── .bashrc
├── hypr/
│   └── .config/hypr/
│       ├── hypridle.conf
│       ├── hyprsunset.conf
│       └── custom/
│           ├── autostart.conf
│           ├── bindings.conf
│           ├── input.conf
│           ├── looknfeel.conf
│           └── monitors.conf
├── waybar/
│   └── .config/waybar/
│       ├── config.jsonc
│       └── style.css
└── scripts/
    └── .local/bin/
        └── toggle-mirror.sh
```

## Prerequisites

- Linux + Omarchy installed
- `stow` (GNU Stow)
- `bash`, `python3`, `findutils`, `coreutils` (standard on most distros)

Optional/runtime tools used by configured components:

- `jq`, `hyprctl`, `notify-send` (for display mirror toggle script)
- `brightnessctl` (used by `hypridle.conf` commands)

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

Examples:

```bash
./bootstrap.sh --check
./bootstrap.sh --install
./bootstrap.sh --apply
./bootstrap.sh --uninstall
```

## How the Hook Strategy Works

Omarchy continues owning its base files (for safer updates), while this repo appends a managed section like:

```ini
# >>> dotfiles-managed custom hooks >>>
source = ~/.config/hypr/custom/<name>.conf
# <<< dotfiles-managed custom hooks <<<
```

Before adding, `bootstrap.sh` removes any previous managed block, so repeated runs stay idempotent.

If target Omarchy files are missing, bootstrap exits with guidance to restore them via Omarchy (`Update > Config`).

## Included Customizations

- Bash
  - Sources Omarchy default bash rc first, then adds personal aliases and PATH adjustments.
- Hypr custom overrides
  - `custom/autostart.conf`: starts `hyprsunset`
  - `custom/bindings.conf`: webapp launch bindings + display mirror toggle key
  - `custom/input.conf`: keyboard layout/options and touchpad tuning
  - `custom/looknfeel.conf`: visual/layout override area
  - `custom/monitors.conf`: monitor scaling/preferences
- Waybar
  - Custom bar modules/layout in `config.jsonc`
  - Styling in `style.css`, importing Omarchy theme variables
- Script
  - `toggle-mirror.sh`: toggles external monitors between extended and mirrored modes

## Troubleshooting

- "GNU stow is required but not installed."
  - Install `stow` and rerun.
- Conflicts reported
  - Run `./bootstrap.sh --check` to inspect.
  - Use `./bootstrap.sh --install` to auto-back up conflicts to `~/.dotfiles-backup-<timestamp>`.
- Hook target file missing
  - Restore Omarchy defaults via Omarchy menu (`Update > Config`), then rerun bootstrap.
- Display toggle keybind does not work
  - Ensure `~/.local/bin/toggle-mirror.sh` is executable and dependencies (`jq`, `hyprctl`, `notify-send`) are available.

## Updating

When you change files in this repo, rerun:

```bash
./bootstrap.sh --apply
```

That reapplies symlinks and refreshes managed hook blocks safely.

# Omarchy Quattro Dotfiles

Personal, update-friendly configuration for Omarchy 4 using GNU Stow.

Omarchy owns the desktop defaults. This repository keeps only personal overrides and utilities.

## Managed configuration

- `~/.bashrc`
- `~/.config/hypr/bindings.lua`
- `~/.config/hypr/input.lua`
- `~/.config/hypr/autostart.lua`
- `~/.config/hypr/hyprsunset.conf`
- `~/.config/ghostty/config`
- `~/.local/bin/omarchy-work-vpn`
- `~/.local/share/applications/*.desktop`
- `~/.config/omarchy/themes/retro-82/helix.toml`

The Omarchy shell, bar, notifications, and stock Hyprland entry point remain package-managed.

## Prerequisites

Required:

- Omarchy 4
- GNU Stow

Optional runtime dependencies:

- `openconnect`, `secret-tool`, `zenity` for the Work VPN launcher
- `voxtype` for the Menu-key dictation binding

## Usage

```bash
./bootstrap.sh --dry-run
./bootstrap.sh --check
./bootstrap.sh --apply
```

Modes:

- `--apply`: restow managed packages
- `--dry-run`: preview changes
- `--install`: back up conflicting targets, then apply
- `--check`: detect Stow conflicts without changing files
- `--uninstall`: remove managed symlinks

After Hyprland changes, validate with:

```bash
hyprctl reload
hyprctl configerrors
```

## Work VPN

The launcher is installed as `~/.local/bin/omarchy-work-vpn` with a desktop entry. Its configuration and keyring password intentionally stay outside this repository.

One-time setup:

```bash
yay -S openconnect
omarchy-work-vpn setup
$EDITOR ~/.config/work-vpn/config
```

Use `omarchy-work-vpn command` to preview the OpenConnect command without exposing secrets.

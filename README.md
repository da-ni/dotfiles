# Omarchy Quattro Dotfiles

Personal, update-friendly configuration for Omarchy 4 using GNU Stow.

Omarchy owns the desktop defaults. This repository keeps only personal overrides and utilities.

## Managed configuration

- `~/.bashrc`
- `~/.config/hypr/bindings.lua`
- `~/.config/hypr/input.lua`
- `~/.config/hypr/autostart.lua`
- `~/.config/hypr/hyprsunset.conf`
- `~/.config/omarchy/plugins/dn.work-vpn`
- `~/.local/bin/omarchy-work-vpn`

The Omarchy shell, bar layout, notifications, terminals, themes, and stock Hyprland entry point remain package-managed. Only the Work VPN plugin source is tracked.

## Prerequisites

Required:

- Omarchy 4
- GNU Stow

Optional runtime dependencies:

- `openconnect`, `secret-tool`, `zenity` for the Work VPN launcher
- `voxtype` for the Menu-key dictation binding

The Work VPN additionally uses the root-owned helper and scoped sudoers rule
documented in `docs/work-vpn.md`; system files are installed explicitly and
are not managed by Stow.

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

The launcher is installed as `~/.local/bin/omarchy-work-vpn` with a Quattro
shell widget. Its configuration and keyring password
intentionally stay outside this repository. The widget placement remains a
machine-local Quattro setting rather than tracking `shell.json`.

One-time setup:

```bash
yay -S openconnect
omarchy-work-vpn setup
$EDITOR ~/.config/work-vpn/config
omarchy plugin enable dn.work-vpn --section right --before omarchy.network
```

Use `omarchy-work-vpn command` to preview the OpenConnect command without exposing secrets.

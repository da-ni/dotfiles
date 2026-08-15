# Omarchy Quattro Dotfiles

Personal, update-friendly configuration for Omarchy 4 using GNU Stow.

Omarchy owns the desktop defaults. This repository keeps only personal overrides and utilities.

## Managed configuration

- `~/.bashrc`
- `~/.config/herdr/config.toml`
- `~/.config/hypr/bindings.lua`
- `~/.config/hypr/input.lua`
- `~/.config/hypr/autostart.lua`
- `~/.config/hypr/hyprsunset.conf`
- Netflix launcher and icon under `~/.local/share/{applications,icons}`
- `~/.config/omarchy/plugins/dn.work-vpn`
- `~/.local/bin/omarchy-work-vpn`

The Herdr configuration is generated from Omarchy's currently installed default plus
`herdr/config.patch`, so new upstream bindings remain inherited. The Omarchy shell,
bar layout, notifications, terminals, themes, and stock Hyprland entry point remain
package-managed. Only the Work VPN plugin source is tracked.

## Prerequisites

Required:

- Omarchy 4
- GNU Stow
- GNU patch

Optional runtime dependencies:

- `openconnect`, `secret-tool`, `zenity` for Work VPN
- `voxtype` for the Menu-key dictation binding

Work VPN also uses the tracked root helper and disconnect-only sudoers rule.
They are installed explicitly because Stow does not manage system paths.

## Usage

```bash
./bootstrap.sh --dry-run
./bootstrap.sh --check
./bootstrap.sh --doctor
./bootstrap.sh --apply
```

Modes:

- `--apply`: restow managed packages
- `--dry-run`: preview changes
- `--install`: back up conflicting targets, then apply
- `--check`: detect Stow conflicts without changing files
- `--doctor`: validate the live Stow links, Omarchy configuration, VPN integration, and Netflix launcher
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

One-time setup, from the repository root:

```bash
yay -S openconnect
sudo install -Dm755 system/usr/local/libexec/omarchy-work-vpn-privileged /usr/local/libexec/omarchy-work-vpn-privileged
sudo install -Dm440 system/etc/sudoers.d/omarchy-work-vpn /etc/sudoers.d/omarchy-work-vpn
omarchy-work-vpn setup
$EDITOR ~/.config/work-vpn/config
omarchy plugin enable dn.work-vpn --section right --before omarchy.network
```

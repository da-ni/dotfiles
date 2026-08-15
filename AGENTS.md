# Dotfiles Agent Guide

This repository keeps a deliberately small set of personal Omarchy Quattro
overrides. Omarchy owns the defaults; this repository should only contain
configuration that is genuinely personal or machine-specific.

## Instruction Precedence

1. User task request
2. `AGENTS.md` (this file)
3. Existing repository conventions

## Managed Sources

- `bash/.bashrc`: minimal Bash entry point that loads Omarchy defaults
- `hypr/.config/hypr/bindings.lua`: personal application keybindings
- `hypr/.config/hypr/input.lua`: personal input settings
- `hypr/.config/hypr/autostart.lua`: starts the scheduled night-light service
- `hypr/.config/hypr/hyprsunset.conf`: personal night-light schedule
- `applications/.local/share/`: searchable Netflix launcher and icon
- `scripts/.local/bin/omarchy-work-vpn`: unprivileged VPN controller
- `work-vpn-shell/`: Quattro shell plugin source
- `system/`: explicitly installed privileged VPN helper and sudoers rule

The Bash, Hyprland, applications, and scripts packages are managed with GNU Stow. The VPN
plugin is copied by `bootstrap.sh` because Quattro plugin discovery does not
support the Stow directory-folding layout. Files under `system/` are not
installed automatically.

## Working Rules

- Edit repository sources, then run `./bootstrap.sh --apply`.
- Do not edit generated targets in `$HOME` directly.
- Keep machine-private VPN configuration and credentials out of Git.
- Do not add overrides for behavior that current Omarchy already provides.
- Preserve unrelated local changes and avoid destructive Git operations.

## Commands

```bash
./bootstrap.sh --dry-run
./bootstrap.sh --check
./bootstrap.sh --apply
./bootstrap.sh --uninstall
```

After Hyprland changes, verify with:

```bash
hyprctl reload
hyprctl configerrors
```

After plugin changes, validate the source with:

```bash
omarchy plugin validate work-vpn-shell/.config/omarchy/plugins/dn.work-vpn
```

The shell normally hot-reloads copied plugin changes. Use
`omarchy restart shell` only if hot reload fails.

## Work VPN

The tracked system helper and sudoers rule must be installed explicitly using
the commands in `README.md`. Connecting uses the graphical Polkit prompt;
disconnecting is the only passwordless privileged action.

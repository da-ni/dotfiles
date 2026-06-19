# Omarchy Dotfiles

Personal dotfiles for an Omarchy setup.

This repo uses a hybrid approach:

1. Own selected files directly via GNU Stow (`bash`, `hypr`, `waybar`, `ghostty`, `voxtype`).
2. Extend Omarchy-managed Hypr config by appending a managed `source` block to `~/.config/hypr/hyprland.conf`.

This keeps Omarchy update-friendly while still allowing local customization.

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
- `~/.config/voxtype/config.toml`
- `~/.local/bin/omarchy-work-vpn`
- `~/.local/bin/hide`
- `~/.local/bin/hide-toggle`
- `~/.local/bin/hide-focus`
- `~/.local/bin/hide-init`
- `~/.config/hide/tmux.conf`
- `~/.local/share/applications/*.desktop`
- `~/.local/share/applications/icons/*.png`
- `~/.config/systemd/user/chatterbox-tts.service`
- `~/.config/omarchy/themes/retro-82/helix.toml`

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
- `openconnect`, `secret-tool`, `zenity` (Work VPN launcher)

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

## Work VPN

The Work VPN launcher is managed as `~/.local/bin/omarchy-work-vpn` and appears in Waybar as a VPN icon next to networking. Left click toggles the VPN in a floating terminal; right click opens the local config.

One-time setup:

```bash
yay -S openconnect
omarchy-work-vpn setup
$EDITOR ~/.config/work-vpn/config
```

The config file and keyring password are intentionally outside this repository. The launcher supports an OpenConnect auth group, AnyConnect-style user agent, and `--no-external-auth` defaults. It backgrounds OpenConnect after authentication and runs `resolvectl dnsovertls tun0 no` from the OpenConnect connect hook. Use `omarchy-work-vpn command` to preview the exact OpenConnect argv without secrets.

## hide

`hide` is a minimal Helix IDE built on tmux: a fixed three-pane layout (Helix editor, Codex agent sidebar, toggleable bottom terminal) running on a dedicated tmux socket. Launch it from a terminal or `Super + Alt + Return`:

```bash
hide [dir]   # dir defaults to $PWD, resolved to the git root if inside a repo
```

Keybinds (no prefix): `Ctrl+Space` toggle agent, `Alt+Space` toggle terminal, `Ctrl+Y` focus editor/agent, `Alt+Y` focus editor/terminal, `Alt+hjkl` pane navigation, `Ctrl+Alt+Q` kill the session. The toggles hide panes to a true zero footprint (break/join, processes kept alive). Config lives in `~/.config/hide/tmux.conf`.

It replaced a Yazelix (Zellij) setup that proved too rigid to bend into a simple fixed-pane layout.

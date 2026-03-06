# dotfiles (Omarchy overlay-only)

This repo is set up to stow **Omarchy-safe overlays only**.

Instead of stowing files directly into `~/.config/hypr`, `~/.config/waybar`, etc., it stows overlay files into Omarchy's overlay path:

- `~/.config/omarchy/overlays/...`
- `~/.local/bin/*` (overlay helper scripts)

## Layout

```text
overlays/
├── .config/omarchy/overlays/
│   ├── bash/bashrc.overlay
│   ├── hypr/
│   │   ├── 10-custom-apps.overlay.conf
│   │   ├── 20-rebinds.overlay.conf
│   │   ├── 30-input.overlay.conf
│   │   ├── 40-monitors.overlay.conf
│   │   ├── 50-idle.overlay.conf
│   │   └── 60-rules.overlay.conf
│   └── waybar/*.overlay.{jsonc,css}
└── .local/bin/
```

## Overlay semantics

These files are **not guaranteed to behave like whole-file replacements**.

Omarchy may source defaults and user config together, and Hyprland evaluates the resulting combined config according to directive type.

In practice:

- binds are additive unless explicitly removed
- window rules are additive and order-sensitive
- scalar settings usually behave like later overrides
- changing an existing Omarchy keybind requires `unbind` before redefining it

That is why this repo separates Hypr overlays by intent:

- `10-custom-apps.overlay.conf` for brand-new binds
- `20-rebinds.overlay.conf` for `unbind` + replacement binds
- `30-input.overlay.conf` for scalar input settings
- `40-monitors.overlay.conf` for monitor/env config
- `50-idle.overlay.conf` for idle policy
- `60-rules.overlay.conf` for window rules

## Bootstrap usage

```bash
./bootstrap.sh [--profile home|work|server] [--dry-run|--apply|--force|--check|--uninstall|--report]
```

### Modes

- `--apply` (default): preview + apply stow symlinks
- `--dry-run`: preview stow operations only
- `--check`: list conflicts only
- `--force`: back up conflicts, then apply
- `--uninstall`: remove symlinks created by this repo
- `--report`: diff repo overlay files against local Omarchy overlays under `~/.config/omarchy`

### Requirements

- `stow` is required for stow modes (`apply`, `dry-run`, `check`, `force`, `uninstall`)
- `--report` does **not** require `stow`, but it requires local Omarchy overlays (default path: `~/.config/omarchy`, using `overlays/` under it)

## Examples

```bash
# Preview stow changes
./bootstrap.sh --dry-run

# Apply overlays
./bootstrap.sh --apply

# Compare repo overlays to local Omarchy overlays
./bootstrap.sh --report
```

## Migration checklist

```bash
# 1) Preview changes
./bootstrap.sh --dry-run

# 2) Apply
./bootstrap.sh --apply

# 3) Reload Hyprland
hyprctl reload
```

Then verify:

- remapped keys trigger exactly one action
- Waybar loads without module errors
- `~/.local/bin/toggle-mirror.sh` exists and is executable
- `~/.local/bin/vpn-status.sh` exists if the VPN Waybar module is enabled
- idle behavior still matches expectations

## Notes

- File names are intentionally overlay-specific (`*.overlay.*`) to avoid collisions with base Omarchy file names in this repo.
- The mirror toggle script is installed as `~/.local/bin/toggle-mirror.sh` and referenced by Hypr bindings via that name.
- If you change an Omarchy default bind, do it in `20-rebinds.overlay.conf` with `unbind` first.

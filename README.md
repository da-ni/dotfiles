# dotfiles (Omarchy overlay-only)

This repo is set up to stow **Omarchy-safe overlays only**.

Instead of stowing files directly into `~/.config/hypr`, `~/.config/waybar`, etc., it stows overlay files into Omarchy's overlay path:

- `~/.config/omarchy/overlays/...`
- `~/.local/bin/* (overlay helper scripts)`

## Layout

```text
overlays/
├── .config/omarchy/overlays/
│   ├── bash/bashrc.overlay
│   ├── hypr/*.overlay.conf
│   └── waybar/*.overlay.{jsonc,css}
└── .local/bin/toggle-mirror.sh
```

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
- `--report`: diff repo overlay files against Omarchy defaults at `$OMARCHY_PATH/default`

### Requirements

- `stow` is required for stow modes (`apply`, `dry-run`, `check`, `force`, `uninstall`)
- `--report` does **not** require `stow`, but it requires a local Omarchy tree (default path: `~/.local/share/omarchy`)

## Examples

```bash
# Preview stow changes
./bootstrap.sh --dry-run

# Apply overlays
./bootstrap.sh --apply

# Compare repo overlays to local Omarchy defaults
./bootstrap.sh --report

# Compare against a custom Omarchy checkout
OMARCHY_PATH=/path/to/omarchy ./bootstrap.sh --report
```

## Notes

- File names are intentionally overlay-specific (`*.overlay.*`) to avoid collisions with base Omarchy file names in this repo.
- The mirror toggle script is installed as `~/.local/bin/toggle-mirror.sh` and referenced by Hypr bindings via that name.

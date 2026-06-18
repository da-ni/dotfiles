# Yazelix

Yazelix is installed through its upstream Nix flake and launched through a small local helper:

```bash
omarchy-yazelix install
omarchy-yazelix launch
omarchy-yazelix update
omarchy-yazelix-serpl
```

The default package is `github:luccahuguet/yazelix#yazelix`, which uses Yazelix's packaged Ghostty runtime. Override it for one command with `YAZELIX_FLAKE_REF`, for example:

```bash
YAZELIX_FLAKE_REF=github:luccahuguet/yazelix#yazelix_foot omarchy-yazelix install
```

If Nix is missing, install it the Omarchy/Arch way:

```bash
omarchy pkg add nix
sudo systemctl enable --now nix-daemon.service
```

Then open a fresh shell and rerun `omarchy-yazelix install`.

User-edited Yazelix settings live outside this repo at `~/.config/yazelix/settings.jsonc`. Runtime-generated state lives under `~/.local/share/yazelix`.

## Theme Sync

Yazelix follows the active Omarchy theme through:

```bash
omarchy-yazelix-theme-sync
```

The sync runs automatically after `omarchy theme set ...` through `~/.config/omarchy/hooks/theme-set.d/yazelix`.

It writes managed blocks or files under `~/.config/yazelix/`:

- `settings.jsonc`: sets `appearance.mode`, `zellij.theme`, `yazi.theme`, and the managed custom popup entry
- `terminal_ghostty.conf`: copies the Omarchy Ghostty palette plus native Ghostty font, cursor, and padding settings
- `zellij.kdl`: defines a Zellij theme named `omarchy`
- `yazi/flavors/omarchy.yazi/flavor.toml`: generates a Yazi flavor from Omarchy `colors.toml`
- `helix/themes/omarchy.toml` and `helix/config.toml`: use the Omarchy Helix theme in Yazelix-managed Helix
- `~/.config/yazelix_cursors/settings.jsonc`: disables Yazelix cursor trails, movement effects, mode-change effects, glow, and Kitty cursor fallback

It also patches generated Yazelix runtime files under `~/.local/share/yazelix/configs/` after refresh so hardcoded Yazelix status-bar colors are mapped back to the active Omarchy palette and generated Helix statusline/cursor-shape overrides are removed.

The sync deliberately does not own user-facing Yazelix config-menu settings such as the widget tray and tab label mode.

Restart or relaunch Yazelix after changing Omarchy themes so generated runtime files pick up the new settings.

## Helix Tools

The Yazelix-managed Helix config uses the `Space q` submenu pattern from Guillermo Aguirre's Helix/Zellij IDE guide:

- `Space q q`: open Yazi in a floating Zellij pane and open selected files in the current Helix view
- `Space q v`: open Yazi in a floating Zellij pane and open selected files in vertical splits
- `Space q s`: open Yazi in a floating Zellij pane and open selected files in horizontal splits
- `Space q r`: open [Serpl](https://github.com/yassinebridi/serpl) in a floating Zellij pane, rooted at the current Yazelix workspace

`omarchy-yazelix-serpl` installs `nixpkgs#serpl` into the default Nix profile on first use and warns if `ripgrep` is missing.

After changing this integration, run `omarchy-yazelix-theme-sync` or change the Omarchy theme once so Yazelix settings and the managed Helix sidecar are refreshed.

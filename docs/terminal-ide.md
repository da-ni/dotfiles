# Terminal IDE Workspace

This setup creates a single command workspace built around Zellij + Helix + OpenCode.

## Start workspace

```bash
ws
```

`ws` uses a deterministic `studio` session name. If no clients are attached, it recreates `studio` from the canonical layout before attaching.

The workspace uses a bottom `tab-bar` only for a cleaner, low-chrome UI.

On attach, `ws` ensures fixed tabs (`Home`, `dotfiles`, `Vault`) exist.

## Layout switching

Workspace tabs start in a stacked base layout (`terminal`, `helix`, `opencode`).

An alternate swap layout named `SPLIT` is available:

- left: `helix` top + `terminal` bottom
- right (~1/3): `opencode` full height

Switch between `BASE` and `SPLIT` with:

```bash
Alt-[
Alt-]
```

## Default tabs

- `Home`: `terminal` only
- `dotfiles`: workspace layout rooted at `~/Documents/dotfiles` (helix focused)
- `Vault`: workspace layout rooted at `~/Documents/Vaults/work/obsidian-vault` (helix focused)

Each fixed tab opens with a pinned working directory (`$HOME`, `~/Documents/dotfiles`, `~/Documents/Vaults/work/obsidian-vault`).

## Add a project tab

From any pane in `ws`, run:

```bash
ws add
```

The picker looks under `~/Documents`, prefers `zoxide + fzf`, and falls back to manual input.

Optional yazi picker mode:

```bash
ws add --yazi
```

Prefer recent zoxide projects first:

```bash
ws add --recent
```

Each new project tab starts in the stacked base layout with these panes:

- `terminal`
- `helix` (expanded by default)
- `opencode` (starts suspended; press Enter in that pane to launch)

## Lazygit (floating)

From any pane in `ws`, run:

```bash
ws git
```

This opens lazygit in a floating pane tied to the current tab directory.

Fast key: `Alt-w`.

## Yazi file manager

From any pane in `ws`, run:

```bash
ws yazi
```

This opens yazi in a floating pane tied to the current tab directory.

Optional explicit floating mode (same behavior):

```bash
ws yazi --float
```

Fast key: `Alt-q` (floating).

## Useful built-in zellij keys

- `Alt h/j/k/l`: move focus between panes
- `Alt [` / `Alt ]`: previous/next swap layout (`BASE` / `SPLIT`)
- `Alt q`: open floating yazi
- `Alt w`: open floating lazygit
- `Ctrl n`: enter/exit resize mode
- `h/j/k/l`, `+/-`: resize focused pane while in resize mode
- `F12`: open workspace help popup (`ws-help`)
- `Alt n`: new pane
- `Ctrl d`: detach from session
- `Ctrl q`: quit zellij

Workspace command shortcuts:

- `ws add`: add project tab
- `ws git`: open floating lazygit
- `ws yazi`: open floating yazi
- `ws doctor`: validate workspace dependencies and paths
- `ws reset`: delete `studio` and return to shell
- `ws restart`: delete and recreate `studio` immediately

## Notes

- `yazi` is optional. If not installed, `ws add` still works via `fzf` or manual path.
- Project selection is intentionally scoped to `~/Documents` for now.
- Omarchy theme changes auto-sync into Zellij via `omarchy-zellij-theme-set` hook integration.
- Floating tool panes show contextual titles like `yazi:<dir>` and `lazygit:<dir>`.

If fixed tabs ever disappear, run:

```bash
ws restart
```

## FAQ

- `opencode` panes intentionally show `Press ENTER to run...` until launched. This keeps idle memory lower.
- If another pane unexpectedly shows `Press ENTER to run...`, that pane command exited. `ws` rebuilds fixed tabs when recreating a fresh `studio` session.

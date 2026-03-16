# Terminal IDE Workspace

This setup creates a single command workspace built around Zellij + Helix + OpenCode.

## Start workspace

```bash
ws
```

`ws` uses a deterministic `studio` session name. If no clients are attached, it recreates `studio` from the canonical layout before attaching.

The workspace uses a bottom `tab-bar` only for a cleaner, low-chrome UI.

On attach, `ws` ensures fixed tabs (`Home`, `dotfiles`, `Vault`) exist.

## Default tabs

- `Home`: stacked `terminal`, `opencode` (press Enter to launch), `helix` (terminal focused by default)
- `dotfiles`: stack rooted at `~/Documents/dotfiles` (helix focused)
- `Vault`: stack rooted at `~/Documents/Vaults/work/obsidian-vault` (helix focused)

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

Each new project tab uses a stacked layout with:

- `terminal`
- `opencode` (starts suspended; press Enter in that pane to launch)
- `helix` (expanded by default)

## Lazygit (floating)

From any pane in `ws`, run:

```bash
ws git
```

This opens lazygit in a floating pane tied to the current tab directory.

Fast key: `F2`.

## Yazi file manager

From any pane in `ws`, run:

```bash
ws yazi
```

This opens yazi in a right-side pane and closes it when you quit yazi.

Optional floating mode:

```bash
ws yazi --float
```

Fast key: `F1`.

## Useful built-in zellij keys

- `Alt h/j/k/l`: move focus between panes
- `Alt [` / `Alt ]`: previous/next tab (matches tab-bar hint)
- `Alt q/w`: previous/next tab
- `F1`: open yazi side pane
- `F2`: open floating lazygit
- `F12`: open workspace help popup (`ws-help`)
- `Ctrl o` then `w`: session manager
- `Ctrl o` then `c`: configuration/help screen
- `Ctrl p` then `w`: toggle floating panes
- `Alt n`: new pane
- `Ctrl t` then `h/l`: previous/next tab
- `Ctrl d`: detach from session
- `Ctrl q`: quit zellij

Workspace command shortcuts:

- `ws add`: add project tab
- `ws git`: open floating lazygit
- `ws yazi`: open yazi side pane
- `ws reset`: delete `studio` and return to shell
- `ws restart`: delete and recreate `studio` immediately

## Notes

- `yazi` is optional. If not installed, `ws add` still works via `fzf` or manual path.
- Project selection is intentionally scoped to `~/Documents` for now.
- Omarchy theme changes auto-sync into Zellij via `omarchy-zellij-theme-set` hook integration.

If fixed tabs ever disappear, run:

```bash
ws restart
```

## FAQ

- `opencode` panes intentionally show `Press ENTER to run...` until launched. This keeps idle memory lower.
- If another pane unexpectedly shows `Press ENTER to run...`, that pane command exited. `ws` rebuilds fixed tabs when recreating a fresh `studio` session.

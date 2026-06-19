# hide — Helix IDE on tmux

**Version 1.1.2**

A minimal, owned terminal IDE. No plugins, no framework. Just tmux, Helix, and a handful of
small scripts that wire in a file picker, search, git, an AI agent sidebar, and project switching.
Everything runs on a dedicated tmux socket (`-L hide`) so it never collides with other tmux.

## Layout

```
┌─ editor (Helix) ───────────┬─ agent (Codex/Claude/…) ─┐
│                            │                          │
│                            │                          │
├────────────────────────────┴──────────────────────────┤
│ terminal (hidden by default, toggle to reveal)        │
└────────────────────────────────────────────────────────┘
```

Panes are tagged with a `@role` user-option (editor / agent / terminal) so scripts find them by
role, not by guessing what program is running. Toggling a pane breaks it to an off-screen holding
window (the process keeps running) and joins it back on demand: zero footprint when hidden.

## Install

Stowed from this dotfiles repo:

```
stow -d ~/Repositories/dotfiles -t ~ -R hide
```

That symlinks the `hide-*` scripts into `~/.local/bin` (must be on `$PATH`) and the config into
`~/.config/hide`. Launch with `hide` (see Usage). A desktop binding (Super+Alt+Return) runs it.

## Usage

```
hide <dir>      open that dir (resolved to its git root if inside a repo)
hide  (in repo) open the current repo
hide  (bare)    project picker: attach an open project, or open a frecent (zoxide) dir
```

## Keybinds

Prefix-less. The cheatsheet is also live in-IDE on `Ctrl+Alt+K` (`hide-keys` is the source of truth).

| Key | Action |
| --- | --- |
| Ctrl+Space | toggle agent pane |
| Alt+Space | toggle terminal pane |
| Ctrl+Y / Alt+Y | focus agent / terminal |
| Alt+H/J/K/L | move between panes |
| Ctrl+Alt+G | lazygit |
| Ctrl+Alt+O / Ctrl+Alt+V | open file (picker) / in vertical split |
| Ctrl+Alt+F | project search |
| Ctrl+Alt+R | project search & replace |
| Ctrl+Alt+T | scratch shell (toggle) |
| Ctrl+Alt+E | re-run last terminal command |
| Ctrl+Alt+W | switch / open project |
| Ctrl+Alt+A | switch agent (Codex / Claude / opencode) |
| Ctrl+Alt+K | keybind overview |
| Ctrl+Alt+Q | close hide session |

Helix splits use Helix's own `Ctrl+W` then `H/J/K/L`. hide never rebinds Helix's keymap (its power
tools live in the `Ctrl+Alt` namespace, which Helix leaves free).

## Dependencies

Required: `tmux` (3.2+ for pane-border-indicators; 3.6 tested), `helix`, `fzf`, `ripgrep`, `bash`.

Per-feature: `lazygit` (git), `yazi` (file picker), `serpl` (search & replace), `zoxide` (project
picker), `bat` (search preview). At least one agent: `codex`, `claude`, or `opencode`.

Splash (optional): `chafa` + `figlet` render the big cloud-face logo + wordmark on launch. Absent,
the splash falls back to a simple centred logo. Disable entirely with `HIDE_SPLASH_SECS=0`.

## Files

- `~/.local/bin/hide` — launcher: resolves the target, builds the 3-pane layout, attaches.
- `~/.local/bin/hide-*` — one small script per feature (toggle, focus, pick, switch, open, search,
  replace, bridge, agent, scratch, rerun, tabs, keys, init). Each is self-contained.
- `~/.config/hide/tmux.conf` — keybinds, pane borders, status bar. Loaded per launch.
- `~/.config/hide/yazi/` — picker-only yazi config (previews disabled so graphics never crash a popup).
- `~/.config/hide/IDEAS.md` — internal parked-feature list (not release docs).

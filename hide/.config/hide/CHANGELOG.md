# Changelog

## 1.1.1

- Project picker (`Ctrl+Alt+W`): `Ctrl-X` closes the selected open project and refreshes the list in place, so you can close any open project without switching to it first. The current session is protected (use `Ctrl+Alt+Q` for that).

## 1.1

- Project-wide search and replace via serpl (`Ctrl+Alt+R`), reloads Helix after.
- Project tabs: status-bar strip plus a switcher popup (`Ctrl+Alt+W`), zoxide-aware (open projects and frecent dirs, attach or launch).
- Bare launch uses the same project picker (retired the yazi workspace browser).
- Agent switcher menu (`Ctrl+Alt+A`): Codex, Claude Code, or opencode.
- Scratch shell popup (`Ctrl+Alt+T`), persistent, toggle.
- Re-run last terminal command (`Ctrl+Alt+E`).
- Keybind cheatsheet (`Ctrl+Alt+K`).
- Active-pane highlight via `pane-border-indicators both` (colour plus arrows).
- Cloud-face logo and spaced `h i d e` wordmark in the status bar.
- Registered as an omarchy TUI app with the cloud-face launcher icon.
- Launch splash with the logo, golden-ratio duration (1.618s), tunable via `HIDE_SPLASH_SECS`.
- Code-quality pass: removed dead logging, added README, applied an independent audit (session-name collision guard, init-guard ordering, colon-safe path split).

## 1.0

- Three-pane layout (editor, agent, terminal) on a dedicated tmux socket.
- Zero-footprint pane toggles and focus (`Ctrl`/`Alt` + `Space`, `Ctrl`/`Alt` + `Y`).
- Heavy pane borders; clean session teardown (`Ctrl+Alt+Q`).
- Workspace picker on bare launch.
- lazygit popup (`Ctrl+Alt+G`); file picker (`Ctrl+Alt+O` / `Ctrl+Alt+V`); project search (`Ctrl+Alt+F`).

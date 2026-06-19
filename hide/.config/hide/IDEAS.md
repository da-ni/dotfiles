# hide — parked ideas & extended feature list

Things worth doing later, harvested while building. Not committed to; a holding pen.
**hide v1.0 is done (2026-06-19).** This list is the v2 candidate pool.

## Candidate features — v1.0 idea scout (ranked, with fit verdict)
Filtered through hide's ethos: minimal, owned, no plugins. Most of what yazelix/zellij
setups ship is either bloat or something hide already does. The ones that survived:

1. ~~Scratch terminal popup~~ — **DONE** (`Ctrl+Alt+T`). See Done list.
2. ~~Reveal current file in the picker~~ — **SKIPPED 2026-06-19.** Feasibility wall confirmed:
   Helix exposes its current file nowhere tmux can read; the only route is scraping the editor
   pane's rendered statusline (breaks across splits/prompts/truncation). Not worth a fragile hack.
3. ~~zoxide-aware unified switcher~~ — **DONE** (`Ctrl+Alt+W`). See Done list.
4. ~~Command re-runner~~ — **DONE** (`Ctrl+Alt+E`). Kept to "re-run last" (`!!`), no task config.
5. ~~Seamless Helix↔tmux navigation~~ — **SKIPPED 2026-06-19.** Same wall as #2: vim-tmux-navigator
   needs the editor to report its edge-split state to the multiplexer, which Helix (no plugin/IPC)
   can't. A non-aware version would swallow keys at the edge instead of crossing to tmux — strictly
   worse than the current clean split (Alt+hjkl = tmux panes, Ctrl+w = Helix splits).

Rejected as not-for-hide: launch benchmarking (yzx bench), pair-programming/session-sharing
(Daniel's solo), broad plugin systems, SSH parity (hide already works over SSH inherently).

## Parked (interesting, from the tmux-IDE community scout)
- **Project persistence across reboot.** Remember which projects were open and restore the set (tmux-resurrect-style, but scoped to the hide socket).
- **Prev/next project cycle keys.** `Ctrl+Alt+[` / `Ctrl+Alt+]` to step through the tab strip without opening the picker. Complements, doesn't replace, `Ctrl+Alt+W`.
- **Config UI popup.** A small in-IDE settings menu (yazelix has one): toggle agent, theme, layout ratios. The agent menu is the first slice of this.
- **Richer status widgets.** Git branch / dirty state, clock, etc. in the strip — only if it earns its space; the strip's job is project tabs first.

## Done
- Heavy pane borders; clean teardown (`Ctrl+Alt+Q`); Yazelix retired.
- Workspace picker on bare launch (yazi, Enter selects).
- lazygit popup (`Ctrl+Alt+G`).
- File picker (`Ctrl+Alt+O` open / `Ctrl+Alt+V` vsplit).
- Project-wide search (`Ctrl+Alt+F`, Enter / Ctrl+V).
- Project-wide search & replace via serpl (`Ctrl+Alt+R`, reloads Helix after).
- Project tabs: status-bar strip + switcher popup (`Ctrl+Alt+W`) — now a unified switcher: open projects (● switch) + zoxide frecent dirs (+ launch), deduped by @hide_root.
- Agent menu: switch the sidebar agent Codex / Claude Code / opencode (`Ctrl+Alt+A`, native display-menu).
- Command re-runner: re-run the last terminal command (`Ctrl+Alt+E`, `!!`), reveals the terminal if hidden, restores focus.
- Keybind cheatsheet: floating overview of every hide keybind (`Ctrl+Alt+K`, any key closes).
- Unified picker everywhere: bare `hide` launch now uses the same project picker (open projects + zoxide dirs) as `Ctrl+Alt+W`, via shared `hide-pick`. yazi-workspace retired.
- Active-pane highlight: `pane-border-indicators both` (colour + arrows). Inactive-dim tried and dropped (full-colour TUIs ignore window-style).
- Cloud-face logo (😶‍🌫️) + spaced `h i d e` wordmark in the status bar.
- omarchy launcher: registered as a TUI app (`TUI.tile`) with the cloud-face emoji rendered to a Noto PNG icon. Stowed `.desktop` + hicolor icon, so it's reproducible. Launch from Super+Space.
- omarchy theme-sync: confirmed already working (Daniel tested) — Helix follows omarchy's per-theme file; tmux chrome inherits terminal truecolor. No work needed.
- Scratch shell popup: persistent floating throwaway terminal (`Ctrl+Alt+T`, toggle; own `scratch` session, status off, excluded from tabs).

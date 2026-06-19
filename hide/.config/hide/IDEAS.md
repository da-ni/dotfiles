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
4. **Simple command/task re-runner** — `Ctrl+Alt+;` re-runs the last shell command (or a
   named `make`/test target) in the bottom terminal. *Verdict: useful but risks per-project
   task-config scope creep — keep it to "re-run last" if built.*
5. **Seamless Helix↔tmux navigation** — one keystroke crosses from a Helix edge-split into the
   adjacent tmux pane (vim-tmux-navigator idea). *Verdict: nice polish, higher complexity
   (must detect Helix is at its edge split). Lower priority.*

Rejected as not-for-hide: launch benchmarking (yzx bench), pair-programming/session-sharing
(Daniel's solo), broad plugin systems, SSH parity (hide already works over SSH inherently).

## Parked (interesting, from the tmux-IDE community scout)
- **Fold the bare-launch workspace picker into the unified switcher.** `Ctrl+Alt+W` now lists open projects + zoxide dirs (done). Still separate: the bare-`hide` launch uses the yazi filesystem browser. Could offer the zoxide list there too, with yazi as the "browse anywhere" fallback. Deferred — the yazi browser is the escape hatch for dirs zoxide doesn't know.
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
- omarchy theme-sync: confirmed already working (Daniel tested) — Helix follows omarchy's per-theme file; tmux chrome inherits terminal truecolor. No work needed.
- Scratch shell popup: persistent floating throwaway terminal (`Ctrl+Alt+T`, toggle; own `scratch` session, status off, excluded from tabs).

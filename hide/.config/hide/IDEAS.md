# hide — parked ideas & extended feature list

Things worth doing later, harvested while building. Not committed to; a holding pen.
**hide v1.0 is done (2026-06-19).** This list is the v2 candidate pool.

## Candidate features — v1.0 idea scout (ranked, with fit verdict)
Filtered through hide's ethos: minimal, owned, no plugins. Most of what yazelix/zellij
setups ship is either bloat or something hide already does. The ones that survived:

1. ~~Scratch terminal popup~~ — **DONE** (`Ctrl+Alt+T`). See Done list.
2. **Reveal current file in the picker** — open the yazi file picker focused on the CURRENT
   buffer's directory instead of project root. *Verdict: small, nice. Needs the editor pane's
   cwd / current file, which Helix doesn't expose easily over tmux — check feasibility first.*
   Ref: yazelix "reveal in sidebar".
3. **zoxide-aware unified switcher** *(already parked below)* — pick open project → switch,
   pick closed dir → launch. *Verdict: strong, folds two features into one.*
4. **Simple command/task re-runner** — `Ctrl+Alt+;` re-runs the last shell command (or a
   named `make`/test target) in the bottom terminal. *Verdict: useful but risks per-project
   task-config scope creep — keep it to "re-run last" if built.*
5. **Seamless Helix↔tmux navigation** — one keystroke crosses from a Helix edge-split into the
   adjacent tmux pane (vim-tmux-navigator idea). *Verdict: nice polish, higher complexity
   (must detect Helix is at its edge split). Lower priority.*

Rejected as not-for-hide: launch benchmarking (yzx bench), pair-programming/session-sharing
(Daniel's solo), broad plugin systems, SSH parity (hide already works over SSH inherently).

## Parked (interesting, from the tmux-IDE community scout)
- **zoxide-aware unified switcher (sesh's killer feature).** One picker that lists open hide projects AND frecent/known project dirs: pick an open one → switch; pick a closed dir → launch hide there. Would fold the bare-launch workspace picker and `Ctrl+Alt+W` into a single list. Ref: joshmedeski/sesh, 27medkamal/tmux-session-wizard.
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
- Project tabs: status-bar strip + switcher popup (`Ctrl+Alt+W`).
- Agent menu: switch the sidebar agent Codex / Claude Code / opencode (`Ctrl+Alt+A`, native display-menu).
- omarchy theme-sync: confirmed already working (Daniel tested) — Helix follows omarchy's per-theme file; tmux chrome inherits terminal truecolor. No work needed.
- Scratch shell popup: persistent floating throwaway terminal (`Ctrl+Alt+T`, toggle; own `scratch` session, status off, excluded from tabs).

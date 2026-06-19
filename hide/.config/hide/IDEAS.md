# hide — parked ideas & extended feature list

Things worth doing later, harvested while building. Not committed to; a holding pen.

## Near-term roadmap (agreed direction)
- **Agent config menu** — popup to switch the sidebar agent (Codex / Claude Code / opencode) for the current project. Could share a "config UI popup" surface (see below).
- **hsplit key** — bridge already supports `hsplit`; just needs a non-conflicting bind (Alt+h is taken by pane-nav, so not Ctrl+Alt+H by reflex).
- **omarchy theme-sync** — keep tmux + Helix themes in step with the omarchy theme. Low priority; current native theme already looks solid.

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

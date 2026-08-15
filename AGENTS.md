# Dotfiles Agent Guide

This repository manages personal Omarchy dotfiles with GNU Stow plus a small managed hook injection.

## Instruction Precedence

1. User task request
2. `AGENTS.md` (this file)
3. Files listed in `opencode.json`
4. Existing repo conventions

When instructions conflict, follow the highest-priority item.

## Project Intent

- Keep Omarchy update-friendly while still allowing local customization.
- Edit stowed source files in this repo, then re-apply with `./bootstrap.sh --apply`.
- Avoid hand-editing generated or managed target files in `$HOME` unless explicitly required.

## Change Scope

- **Primary edit locations:** `bash/`, `hypr/`, `waybar/`, `ghostty/`, `docs/`
- **Injection targets only (do not treat as source):**
  - `~/.config/hypr/hyprland.conf`
- Do not remove or rename managed marker blocks used by `bootstrap.sh`.

## Fast Commands

- Re-apply all managed config: `./bootstrap.sh --apply`
- Check for stow conflicts only: `./bootstrap.sh --check`
- Preview changes without applying: `./bootstrap.sh --dry-run`
- Restart Waybar after Waybar edits: `omarchy-restart-waybar`

## Safe Edit Workflow

1. Change repo-managed source files only.
2. Run `./bootstrap.sh --check` when conflict risk exists.
3. Run `./bootstrap.sh --apply` after changes.
4. Verify only the subsystems touched by the change.

## Verification Matrix

- **General:** `./bootstrap.sh --apply` succeeds with no unexpected stow conflicts.
- **Hyprland:** files remain under `hypr/.config/hypr/custom/`; managed `source = ~/.config/hypr/custom/*` block exists when required.
- **Waybar:** restart with `omarchy-restart-waybar`; if needed, debug via `waybar -l debug`.

## Task Recipes

- **Edit Waybar (`waybar/`):** update config/style/script files in repo -> run `./bootstrap.sh --apply` -> run `omarchy-restart-waybar` -> use `waybar -l debug` if a module fails.
- **Edit Hypr (`hypr/`):** change files under `hypr/.config/hypr/custom/` or related stowed hypr files -> run `./bootstrap.sh --apply` -> confirm managed `source = ~/.config/hypr/custom/*` block still exists.
- **Edit docs only (`docs/`, `README.md`, `AGENTS.md`):** keep docs concise and command-accurate; no bootstrap run required unless commands/paths changed.

## Machine Assumptions

- Dotfiles root: `~/Repositories/dotfiles`

## Dependency and Fallback Expectations

- Optional tools may be absent; preserve existing graceful degradation.
- Common optional integrations: `cava`, `playerctl`.
- Do not replace fallback behavior with hard failures unless explicitly requested.

## Canonical References

- Repo overview and managed paths: `README.md`
- Bootstrap and managed-block logic: `bootstrap.sh`
- Additional operational notes: `docs/`

## Git Hygiene

- Keep edits focused; do not revert unrelated local changes.
- Do not commit secrets or machine-private credentials.
- Avoid destructive git operations unless explicitly requested.

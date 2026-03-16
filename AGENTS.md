# Dotfiles Agent Guide

This repository manages personal Omarchy dotfiles with GNU Stow plus a small set of managed hook injections.

## Instruction Precedence

1. User task request
2. `AGENTS.md` (this file)
3. Files listed in `opencode.json`
4. Existing repo conventions

When instructions conflict, follow the highest-priority item.

## Project Intent

- Keep Omarchy update-friendly while still allowing deep local customization.
- Edit stowed source files in this repo, then re-apply with `./bootstrap.sh --apply`.
- Avoid hand-editing generated or managed target files in `$HOME` unless explicitly required.

## Change Scope

- **Primary edit locations:** `bash/`, `hypr/`, `waybar/`, `scripts/`, `zellij/`, `omarchy/`, `docs/`
- **Injection targets only (do not treat as source):**
  - `~/.config/hypr/hyprland.conf`
  - `~/.config/omarchy/hooks/theme-set`
- Do not remove or rename managed marker blocks used by `bootstrap.sh`.

## Fast Commands

- Re-apply all managed config: `./bootstrap.sh --apply`
- Check for stow conflicts only: `./bootstrap.sh --check`
- Preview changes without applying: `./bootstrap.sh --dry-run`
- Restart Waybar after Waybar edits: `omarchy-restart-waybar`
- Rebuild terminal workspace session: `ws restart`

## Safe Edit Workflow

1. Change repo-managed source files only.
2. Run `./bootstrap.sh --check` when conflict risk exists.
3. Run `./bootstrap.sh --apply` after changes.
4. Verify only the subsystems touched by the change.

## Verification Matrix

- **General:** `./bootstrap.sh --apply` succeeds with no unexpected stow conflicts.
- **Hyprland:** files remain under `hypr/.config/hypr/custom/`; managed `source = ~/.config/hypr/custom/*` block exists when required.
- **Waybar:** restart with `omarchy-restart-waybar`; if needed, debug via `waybar -l debug`.
- **Scripts:** scripts execute under `bash`; preserve graceful fallbacks and `set -euo pipefail` where already present.
- **Zellij / ws:** validate `ws`, `ws add`, `ws git`, `ws yazi`; fixed tabs (`Home`, `dotfiles`, `Vault`) still restore.

## Task Recipes

- **Edit Waybar (`waybar/`):** update module/style/script files in repo -> run `./bootstrap.sh --apply` -> run `omarchy-restart-waybar` -> use `waybar -l debug` if a module fails.
- **Edit Hypr (`hypr/`):** change files under `hypr/.config/hypr/custom/` or related stowed hypr files -> run `./bootstrap.sh --apply` -> confirm managed `source = ~/.config/hypr/custom/*` block still exists.
- **Edit workspace scripts (`scripts/.local/bin/ws*`):** keep `bash` + `set -euo pipefail` conventions -> run `./bootstrap.sh --apply` -> validate `ws`, `ws add`, `ws git`, `ws yazi`, `ws restart`.
- **Add/rename scripts (`scripts/.local/bin/`):** keep executable bits -> run `./bootstrap.sh --apply` -> verify command resolves from shell and has fallback behavior when optional tools are missing.
- **Edit Zellij/layout/theme files (`zellij/`, `omarchy/`):** run `./bootstrap.sh --apply` -> run `ws restart` -> confirm fixed tabs restore and theme hook behavior remains intact.
- **Edit docs only (`docs/`, `README.md`, `AGENTS.md`):** keep docs concise and command-accurate; no bootstrap run required unless commands/paths changed.

## Machine Assumptions

- Dotfiles root: `~/Documents/dotfiles`
- Vault tab path: `~/Documents/Vaults/work/obsidian-vault`
- `ws add` project scope: `~/Documents`

## Dependency and Fallback Expectations

- Optional tools may be absent; preserve existing graceful degradation.
- Common optional integrations: `opencode`, `lazygit`, `yazi`, `nvidia-smi`, `cava`, `playerctl`, `zoxide`, `fzf`, `jq`, `curl`, `bc`.
- Do not replace fallback behavior with hard failures unless explicitly requested.

## Canonical References

- Repo overview and managed paths: `README.md`
- Bootstrap and managed-block logic: `bootstrap.sh`
- Terminal workspace behavior: `docs/terminal-ide.md`
- Additional operational notes: `docs/`

## Git Hygiene

- Keep edits focused; do not revert unrelated local changes.
- Do not commit secrets or machine-private credentials.
- Avoid destructive git operations unless explicitly requested.

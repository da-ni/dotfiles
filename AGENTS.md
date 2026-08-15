# Dotfiles Agent Guide

This repository manages personal Omarchy Quattro overrides with GNU Stow.

## Instruction precedence

1. User task request
2. `AGENTS.md`
3. Files listed in `opencode.json`
4. Existing repository conventions

## Project intent

- Let Omarchy own and update desktop defaults.
- Keep only personal overrides, themes, launchers, and application entries here.
- Edit repository sources, then re-apply with `./bootstrap.sh --apply`.
- Do not edit `/usr/share/omarchy/`; reading it for reference is encouraged.

## Primary edit locations

- `bash/`
- `hypr/.config/hypr/`
- `ghostty/`
- `applications/`
- `scripts/`
- `omarchy/`
- `docs/`

## Quattro boundaries

- Hyprland overrides use Lua files such as `bindings.lua`, `input.lua`, and `autostart.lua`.
- Do not restore legacy `.conf` source injection or `~/.config/hypr/custom/`.
- Omarchy shell replaces Waybar; shell customization belongs in `~/.config/omarchy/shell.json` or plugins.
- Keep machine-private credentials and service-specific state outside the repository.

## Safe workflow

1. Change repository-managed source files only.
2. Run `./bootstrap.sh --check` when conflict risk exists.
3. Run `./bootstrap.sh --apply` after changes.
4. Verify only affected subsystems.

## Verification

- General: `bash -n bootstrap.sh` and `./bootstrap.sh --check`
- Hyprland: `hyprctl reload` followed by `hyprctl configerrors`
- Omarchy shell: configuration and plugins should hot-reload; use `omarchy restart shell` if needed
- Ghostty: `omarchy restart terminal`

## Canonical references

- Managed paths and usage: `README.md`
- Stow and backup behavior: `bootstrap.sh`
- Operational notes: `docs/`

## Git hygiene

- Keep edits focused and preserve unrelated local changes.
- Never commit secrets or machine-private credentials.
- Avoid destructive Git operations unless explicitly requested.

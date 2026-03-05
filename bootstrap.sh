#!/usr/bin/env bash
set -euo pipefail

PROFILE="home"
MODE="apply"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
OVERLAY_PACKAGE="overlays"
OMARCHY_PATH="${OMARCHY_PATH:-$HOME/.local/share/omarchy}"

err()  { printf 'Error: %s\n' "$*" >&2; }
info() { printf '[*] %s\n' "$*"; }

usage() {
  cat <<'USAGE'
Usage: bootstrap.sh [--profile home|work|server] [--dry-run|--apply|--force|--check|--uninstall|--report]

Stows only Omarchy-safe overlay files into:
  ~/.config/omarchy/overlays
  ~/.local/bin/omarchy-*

Profiles:
  home/work/server : currently all install the same overlay package

Modes:
  --apply     Create/update symlinks in $HOME (default)
  --dry-run   Preview operations (no changes)
  --force     Backup conflicting targets, then apply
  --check     List conflicts only (no changes)
  --uninstall Remove symlinks previously created by this repo
  --report    Diff local overlays against local Omarchy default files
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)   PROFILE="${2:-}"; shift 2 ;;
    --dry-run)   MODE="dry-run"; shift ;;
    --apply)     MODE="apply"; shift ;;
    --force)     MODE="force"; shift ;;
    --check)     MODE="check"; shift ;;
    --uninstall) MODE="uninstall"; shift ;;
    --report)    MODE="report"; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) err "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

case "$PROFILE" in
  home|work|server) PACKAGES=("$OVERLAY_PACKAGE") ;;
  *) err "Unknown profile: $PROFILE"; exit 1 ;;
esac

missing=()
for p in "${PACKAGES[@]}"; do [[ -d "$DOTFILES_DIR/$p" ]] || missing+=("$p"); done
((${#missing[@]})) && { err "Missing package dir(s): ${missing[*]}"; exit 1; }

require_stow() {
  command -v stow >/dev/null 2>&1 || {
    err "GNU stow is required but not installed."
    err "Install stow and rerun bootstrap."
    exit 1
  }
}

mkdir -p "$HOME/.local/bin" "$HOME/.config" "$HOME/.config/omarchy/overlays"

run_stow() { stow -v -d "$DOTFILES_DIR" -t "$HOME" "$@"; }

collect_targets() {
  local pkg pkgdir
  for pkg in "${PACKAGES[@]}"; do
    pkgdir="$DOTFILES_DIR/$pkg"
    [[ -d "$pkgdir" ]] || continue
    (
      cd "$pkgdir"
      find . \( -type f -o -type l \) -print0 \
      | while IFS= read -r -d '' rel; do
          rel="${rel#./}"
          printf '%s\0' "$HOME/$rel"
        done
    )
  done
}

collect_conflicts() {
  collect_targets \
  | sort -zu \
  | while IFS= read -r -d '' t; do
      [[ -z "$t" ]] && continue
      if [[ -e "$t" && ! -L "$t" ]]; then
        printf '%s\0' "$t"
        continue
      fi
      local parent="$t"
      while true; do
        parent="$(dirname -- "$parent")"
        [[ "$parent" = "/" || "$parent" = "$HOME" ]] && break
        if [[ -e "$parent" && ! -d "$parent" ]]; then
          printf '%s\0' "$t"
          break
        fi
      done
    done
}

backup_conflicts() {
  local backup="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M)"
  mkdir -p "$backup"

  local -a conflicts=()
  while IFS= read -r -d '' p; do conflicts+=("$p"); done < <(collect_conflicts)

  ((${#conflicts[@]}==0)) && { info "No conflicts."; return 0; }

  info "Backing up ${#conflicts[@]} path(s) to: $backup"
  local p rel dest
  for p in "${conflicts[@]}"; do
    rel="${p#"$HOME"/}"
    dest="$backup/$rel"
    mkdir -p "$(dirname "$dest")"
    mv "$p" "$dest"
    info "Moved: $p -> $dest"
  done
}

report_customizations() {
  local -a mapping=(
    "default/bash/rc|$DOTFILES_DIR/overlays/.config/omarchy/overlays/bash/bashrc.overlay"
    "default/hypr/input.conf|$DOTFILES_DIR/overlays/.config/omarchy/overlays/hypr/input.overlay.conf"
    "default/hypr/monitors.conf|$DOTFILES_DIR/overlays/.config/omarchy/overlays/hypr/monitors.overlay.conf"
    "default/hypr/bindings.conf|$DOTFILES_DIR/overlays/.config/omarchy/overlays/hypr/bindings.overlay.conf"
    "default/hypr/hypridle.conf|$DOTFILES_DIR/overlays/.config/omarchy/overlays/hypr/hypridle.overlay.conf"
    "default/waybar/config.jsonc|$DOTFILES_DIR/overlays/.config/omarchy/overlays/waybar/config.overlay.jsonc"
    "default/waybar/style.css|$DOTFILES_DIR/overlays/.config/omarchy/overlays/waybar/style.overlay.css"
  )

  if [[ ! -d "$OMARCHY_PATH/default" ]]; then
    err "Omarchy defaults not found at $OMARCHY_PATH/default"
    err "Install Omarchy locally (or set OMARCHY_PATH) and rerun with --report"
    exit 1
  fi

  local pair base overlay
  for pair in "${mapping[@]}"; do
    base="${pair%%|*}"
    overlay="${pair##*|}"
    printf '\n=== %s ===\n' "$base"

    if [[ ! -f "$overlay" ]]; then
      echo "Overlay missing: $overlay"
      continue
    fi

    if [[ ! -f "$OMARCHY_PATH/$base" ]]; then
      echo "Base file missing: $OMARCHY_PATH/$base"
      continue
    fi

    if diff -u "$OMARCHY_PATH/$base" "$overlay"; then
      echo "No custom changes."
    fi
  done
}

printf 'Profile : %s\n' "$PROFILE"
printf 'Mode    : %s\n' "$MODE"
printf 'Packages: %s\n\n' "${PACKAGES[*]}"

case "$MODE" in
  dry-run)
    require_stow
    info "Preview:"
    run_stow -n "${PACKAGES[@]}" || true
    ;;
  uninstall)
    require_stow
    run_stow -D "${PACKAGES[@]}"
    ;;
  check)
    require_stow
    mapfile -d '' -t _conf < <(collect_conflicts)
    if ((${#_conf[@]}==0)); then
      echo "No conflicts."
    else
      echo "Conflicts:"
      for p in "${_conf[@]}"; do printf '%s\n' "$p"; done
      exit 2
    fi
    ;;
  force)
    require_stow
    backup_conflicts
    info "Apply:"
    run_stow "${PACKAGES[@]}"
    ;;
  apply)
    require_stow
    info "Preview:"
    run_stow -n "${PACKAGES[@]}" || true
    info "Apply:"
    run_stow "${PACKAGES[@]}"
    ;;
  report)
    report_customizations
    ;;
  *) err "Invalid mode: $MODE"; exit 1 ;;
esac

echo
echo "Done."

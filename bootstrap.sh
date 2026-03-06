#!/usr/bin/env bash
set -euo pipefail

PROFILE="home"
MODE="apply"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
OVERLAY_PACKAGE="overlays"
OMARCHY_PATH="$HOME/.config/omarchy"

err()  { printf 'Error: %s\n' "$*" >&2; }
info() { printf '[*] %s\n' "$*"; }

usage() {
  cat <<'USAGE'
Usage: bootstrap.sh [--profile home|work|server] [--dry-run|--apply|--force|--check|--uninstall|--report]

Stows only Omarchy-safe overlay files into:
  ~/.config/omarchy/overlays
  ~/.local/bin/* (overlay helper scripts)
Profiles:
  home/work/server : currently all install the same overlay package

Modes:
  --apply     Create/update symlinks in $HOME (default)
  --dry-run   Preview operations (no changes)
  --force     Backup conflicting targets, then apply
  --check     List conflicts only (no changes)
  --uninstall Remove symlinks previously created by this repo
  --report    Diff local overlays against local Omarchy overlay files

Notes:
  * Overlay files are treated as deltas, not guaranteed whole-file replacements.
  * In Hyprland specifically, binds and rules are additive unless explicitly removed.
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

ensure_script_permissions() {
  local bindir="$DOTFILES_DIR/overlays/.local/bin"
  [[ -d "$bindir" ]] || return 0

  local script target
  while IFS= read -r -d '' script; do
    chmod +x "$script"
    target="$HOME/.local/bin/$(basename "$script")"
    [[ -e "$target" ]] && chmod +x "$target"
  done < <(find "$bindir" -maxdepth 1 -type f -print0)
}
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

cleanup_legacy_symlinks() {
  # Migration cleanup for pre-overlay dotfile layouts only.
  local -a legacy_targets=(
    "$HOME/.bashrc"
    "$HOME/.config/hypr/input.conf"
    "$HOME/.config/hypr/monitors.conf"
    "$HOME/.config/hypr/bindings.conf"
    "$HOME/.config/hypr/hypridle.conf"
    "$HOME/.config/waybar/config.jsonc"
    "$HOME/.config/waybar/style.css"
    "$HOME/.local/bin/toggle-mirror.sh"
  )

  local target link_target
  local removed=0
  for target in "${legacy_targets[@]}"; do
    [[ -L "$target" ]] || continue
    link_target="$(readlink "$target")"

    if [[ ! -e "$target" ]]; then
      rm -f -- "$target"
      info "Removed dangling legacy symlink: $target -> $link_target"
      ((removed+=1))
      continue
    fi

    if [[ "$link_target" == *"/bash/"* || "$link_target" == *"/hypr/"* || "$link_target" == *"/waybar/"* || "$link_target" == *"/bin/"* ]]; then
      rm -f -- "$target"
      info "Removed legacy symlink: $target -> $link_target"
      ((removed+=1))
    fi
  done

  ((removed==0)) && info "No legacy symlinks to remove."
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
    "bash/bashrc.overlay|$DOTFILES_DIR/overlays/.config/omarchy/overlays/bash/bashrc.overlay"
    "hypr/10-custom-apps.overlay.conf|$DOTFILES_DIR/overlays/.config/omarchy/overlays/hypr/10-custom-apps.overlay.conf"
    "hypr/20-rebinds.overlay.conf|$DOTFILES_DIR/overlays/.config/omarchy/overlays/hypr/20-rebinds.overlay.conf"
    "hypr/30-input.overlay.conf|$DOTFILES_DIR/overlays/.config/omarchy/overlays/hypr/30-input.overlay.conf"
    "hypr/40-monitors.overlay.conf|$DOTFILES_DIR/overlays/.config/omarchy/overlays/hypr/40-monitors.overlay.conf"
    "hypr/50-idle.overlay.conf|$DOTFILES_DIR/overlays/.config/omarchy/overlays/hypr/50-idle.overlay.conf"
    "hypr/60-rules.overlay.conf|$DOTFILES_DIR/overlays/.config/omarchy/overlays/hypr/60-rules.overlay.conf"
    "waybar/config.overlay.jsonc|$DOTFILES_DIR/overlays/.config/omarchy/overlays/waybar/config.overlay.jsonc"
    "waybar/style.overlay.css|$DOTFILES_DIR/overlays/.config/omarchy/overlays/waybar/style.overlay.css"
  )

  local omarchy_overlays_path="$OMARCHY_PATH"
  if [[ -d "$OMARCHY_PATH/overlays" ]]; then
    omarchy_overlays_path="$OMARCHY_PATH/overlays"
  fi

  if [[ ! -d "$omarchy_overlays_path" ]]; then
    err "Omarchy overlays not found at $omarchy_overlays_path"
    err "Ensure Omarchy is installed at ~/.config/omarchy (or ~/.config/omarchy/overlays), then rerun with --report"
    exit 1
  fi

  local local_overlay_count=0
  local pair base
  for pair in "${mapping[@]}"; do
    base="${pair%%|*}"
    if [[ -f "$omarchy_overlays_path/$base" ]]; then
      ((local_overlay_count+=1))
      break
    fi
  done

  if ((local_overlay_count==0)); then
    info "No Omarchy overlay files found at $omarchy_overlays_path"
    info "Fresh install detected (or overlays not generated yet)."
    info "Run ./bootstrap.sh --apply first, then rerun with --report."
    exit 0
  fi

  local overlay
  for pair in "${mapping[@]}"; do
    base="${pair%%|*}"
    overlay="${pair##*|}"
    printf '\n=== %s ===\n' "$base"

    if [[ ! -f "$overlay" ]]; then
      echo "Overlay missing: $overlay"
      continue
    fi

    if [[ ! -f "$omarchy_overlays_path/$base" ]]; then
      echo "Local file missing: $omarchy_overlays_path/$base"
      continue
    fi

    if diff -u "$omarchy_overlays_path/$base" "$overlay"; then
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
    cleanup_legacy_symlinks
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
    cleanup_legacy_symlinks
    info "Apply:"
    run_stow "${PACKAGES[@]}"
    ensure_script_permissions
    ;;
  apply)
    require_stow
    info "Preview:"
    run_stow -n "${PACKAGES[@]}" || true
    info "Apply:"
    run_stow "${PACKAGES[@]}"
    ensure_script_permissions
    ;;
  report)
    report_customizations
    ;;
  *) err "Invalid mode: $MODE"; exit 1 ;;
esac

echo
echo "Done."

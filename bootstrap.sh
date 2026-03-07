#!/usr/bin/env bash
set -euo pipefail

PROFILE="home"
MODE="apply"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
PACKAGE="omarchy"

err()  { printf 'Error: %s\n' "$*" >&2; }
info() { printf '[*] %s\n' "$*"; }

usage() {
  cat <<'USAGE'
Usage: bootstrap.sh [--profile home|work|server] [--dry-run|--apply|--force|--check|--uninstall]

Stows documented Omarchy user config files directly into:
  ~/.bashrc
  ~/.config/hypr/*
  ~/.config/waybar/*

Profiles:
  home/work/server : currently all install the same package

Modes:
  --apply     Create/update symlinks in $HOME (default)
  --dry-run   Preview operations (no changes)
  --force     Backup conflicting targets, then apply
  --check     List conflicts only (no changes)
  --uninstall Remove symlinks previously created by this repo
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
    -h|--help)   usage; exit 0 ;;
    *) err "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

case "$PROFILE" in
  home|work|server) PACKAGES=("$PACKAGE") ;;
  *) err "Unknown profile: $PROFILE"; exit 1 ;;
esac

missing=()
for p in "${PACKAGES[@]}"; do
  [[ -d "$DOTFILES_DIR/$p" ]] || missing+=("$p")
done
((${#missing[@]})) && { err "Missing package dir(s): ${missing[*]}"; exit 1; }

require_stow() {
  command -v stow >/dev/null 2>&1 || {
    err "GNU stow is required but not installed."
    exit 1
  }
}

mkdir -p "$HOME/.config/hypr" "$HOME/.config/waybar"

run_stow() {
  stow -v -d "$DOTFILES_DIR" -t "$HOME" "$@"
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
  *)
    err "Invalid mode: $MODE"
    exit 1
    ;;
esac

echo
echo "Done."
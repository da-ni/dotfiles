#!/usr/bin/env bash
set -euo pipefail

MODE="apply"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
PACKAGES=(bash hypr waybar)
HOOK_FILES=(autostart.conf bindings.conf input.conf looknfeel.conf monitors.conf)

err()  { printf 'Error: %s\n' "$*" >&2; }
info() { printf '[*] %s\n' "$*"; }

usage() {
  cat <<'USAGE'
Usage: bootstrap.sh [--dry-run|--apply|--check|--uninstall]

Stows:
  ~/.bashrc
  ~/.config/hypr/hypridle.conf
  ~/.config/hypr/hyprsunset.conf
  ~/.config/hypr/custom/*.conf
  ~/.config/waybar/*

Also ensures managed hook blocks exist in:
  ~/.config/hypr/autostart.conf
  ~/.config/hypr/bindings.conf
  ~/.config/hypr/input.conf
  ~/.config/hypr/looknfeel.conf
  ~/.config/hypr/monitors.conf

Modes:
  --apply     Restow packages and ensure hook blocks (default)
  --dry-run   Preview stow changes and hook updates only
  --check     Check whether stow would succeed
  --uninstall Remove stowed symlinks and managed hook blocks
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   MODE="dry-run"; shift ;;
    --apply)     MODE="apply"; shift ;;
    --check)     MODE="check"; shift ;;
    --uninstall) MODE="uninstall"; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) err "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

for p in "${PACKAGES[@]}"; do
  [[ -d "$DOTFILES_DIR/$p" ]] || {
    err "Missing package dir: $DOTFILES_DIR/$p"
    exit 1
  }
done

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "Required command not found: $1"
    exit 1
  }
}

run_stow() {
  stow -v -d "$DOTFILES_DIR" -t "$HOME" "$@"
}

ensure_dirs() {
  mkdir -p \
    "$HOME/.config/hypr" \
    "$HOME/.config/hypr/custom" \
    "$HOME/.config/waybar"
}

hook_block_for() {
  local target_name="$1"
  cat <<EOF
# >>> dotfiles-managed custom hooks >>>
source = ~/.config/hypr/custom/$target_name
# <<< dotfiles-managed custom hooks <<<
EOF
}

remove_hook_block_from_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  python3 - "$file" <<'PY'
import pathlib, re, sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()

new = re.sub(
    r'\n?# >>> dotfiles-managed custom hooks >>>\n.*?# <<< dotfiles-managed custom hooks <<<\n?',
    '\n',
    text,
    flags=re.S,
)

new = re.sub(r'\n{3,}', '\n\n', new).rstrip() + '\n'

if new != text:
    path.write_text(new)
PY
}

ensure_hook_block_in_file() {
  local file="$1"
  local block="$2"

  if [[ ! -f "$file" ]]; then
    err "Expected Omarchy file does not exist: $file"
    err "Restore it first via Omarchy menu: Update > Config"
    exit 1
  fi

  remove_hook_block_from_file "$file"
  {
    printf '\n'
    printf '%s\n' "$block"
  } >> "$file"

  info "Ensured managed hook block in $file"
}

preview_hook_action() {
  local file="$1"
  local block="$2"

  if [[ ! -f "$file" ]]; then
    printf '[dry-run] missing target for hook block: %s\n' "$file"
    return
  fi

  if grep -Fq '# >>> dotfiles-managed custom hooks >>>' "$file"; then
    printf '[dry-run] would refresh managed hook block in %s\n' "$file"
  else
    printf '[dry-run] would append managed hook block to %s\n' "$file"
  fi

  printf '%s\n' "$block"
}

ensure_hooks() {
  local name file
  for name in "${HOOK_FILES[@]}"; do
    file="$HOME/.config/hypr/$name"
    ensure_hook_block_in_file "$file" "$(hook_block_for "$name")"
  done
}

preview_hooks() {
  local name file
  for name in "${HOOK_FILES[@]}"; do
    file="$HOME/.config/hypr/$name"
    preview_hook_action "$file" "$(hook_block_for "$name")"
  done
}

remove_hooks() {
  local name
  for name in "${HOOK_FILES[@]}"; do
    remove_hook_block_from_file "$HOME/.config/hypr/$name"
  done
  info "Removed managed hook blocks from Omarchy Hypr files"
}

printf 'Mode    : %s\n' "$MODE"
printf 'Packages: %s\n\n' "${PACKAGES[*]}"

require_cmd stow
require_cmd python3

case "$MODE" in
  dry-run)
    ensure_dirs
    info "Preview stow:"
    run_stow -n -R "${PACKAGES[@]}"
    info "Preview hook updates:"
    preview_hooks
    ;;
  check)
    if run_stow -n -R "${PACKAGES[@]}" >/dev/null; then
      echo "Stow check passed."
    else
      err "Stow check failed."
      exit 2
    fi
    ;;
  apply)
    ensure_dirs
    info "Apply stow:"
    run_stow -R "${PACKAGES[@]}"
    info "Apply hook updates:"
    ensure_hooks
    ;;
  uninstall)
    info "Remove stow symlinks:"
    run_stow -D "${PACKAGES[@]}"
    info "Remove hook updates:"
    remove_hooks
    ;;
  *)
    err "Invalid mode: $MODE"
    exit 1
    ;;
esac

echo
echo "Done."

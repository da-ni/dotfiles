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
Usage: bootstrap.sh [--dry-run|--apply|--install|--check|--uninstall]

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
  --apply     Restow packages and ensure hook blocks
  --dry-run   Preview stow changes and hook updates only
  --install   One-time setup: back up conflicting target files, then apply
  --check     Check whether stow would succeed
  --uninstall Remove stowed symlinks and managed hook blocks
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   MODE="dry-run"; shift ;;
    --apply)     MODE="apply"; shift ;;
    --install)   MODE="install"; shift ;;
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

collect_package_files() {
  local pkg pkgdir
  for pkg in "${PACKAGES[@]}"; do
    pkgdir="$DOTFILES_DIR/$pkg"
    (
      cd "$pkgdir"
      find . \( -type f -o -type l \) -print0
    )
  done
}

target_for_relpath() {
  local rel="$1"
  printf '%s/%s\n' "$HOME" "${rel#./}"
}

source_for_relpath() {
  local pkg="$1"
  local rel="$2"
  printf '%s/%s/%s\n' "$DOTFILES_DIR" "$pkg" "${rel#./}"
}

backup_conflicting_targets() {
  local backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
  local moved=0

  while IFS= read -r -d '' rel; do
    local owner_pkg=""
    local pkg
    for pkg in "${PACKAGES[@]}"; do
      if [[ -e "$DOTFILES_DIR/$pkg/${rel#./}" || -L "$DOTFILES_DIR/$pkg/${rel#./}" ]]; then
        owner_pkg="$pkg"
        break
      fi
    done
    [[ -n "$owner_pkg" ]] || continue

    local target source resolved=""
    target="$(target_for_relpath "$rel")"
    source="$(source_for_relpath "$owner_pkg" "$rel")"

    [[ -e "$target" || -L "$target" ]] || continue

    if [[ -L "$target" ]]; then
      resolved="$(readlink -f -- "$target" || true)"
      if [[ "$resolved" == "$(readlink -f -- "$source")" ]]; then
        continue
      fi
    fi

    if (( moved == 0 )); then
      mkdir -p "$backup_dir"
      info "Backing up conflicting files to $backup_dir"
    fi

    mkdir -p "$backup_dir/$(dirname "${rel#./}")"
    mv -- "$target" "$backup_dir/${rel#./}"
    info "Moved: $target -> $backup_dir/${rel#./}"
    moved=1
  done < <(collect_package_files | sort -zu)

  if (( moved == 0 )); then
    info "No conflicting target files to back up."
  fi
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
  local name
  for name in "${HOOK_FILES[@]}"; do
    ensure_hook_block_in_file "$HOME/.config/hypr/$name" "$(hook_block_for "$name")"
  done
}

preview_hooks() {
  local name
  for name in "${HOOK_FILES[@]}"; do
    preview_hook_action "$HOME/.config/hypr/$name" "$(hook_block_for "$name")"
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
  install)
    ensure_dirs
    info "Backing up conflicting target files:"
    backup_conflicting_targets
    info "Apply stow:"
    run_stow -R "${PACKAGES[@]}"
    info "Apply hook updates:"
    ensure_hooks
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

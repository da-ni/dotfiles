#!/usr/bin/env bash
set -euo pipefail

MODE="apply"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
PACKAGES=(bash hypr waybar)

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
  --apply     Preview + apply stow + hook updates (default)
  --dry-run   Preview only
  --install   Backup conflicting files, then apply
  --check     List stow conflicts only
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

require_stow() {
  command -v stow >/dev/null 2>&1 || {
    err "GNU stow is required but not installed."
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

collect_targets() {
  local pkg pkgdir
  for pkg in "${PACKAGES[@]}"; do
    pkgdir="$DOTFILES_DIR/$pkg"
    [[ -d "$pkgdir" ]] || continue
    (
      cd "$pkgdir"
      find . \( -type f -o -type l \) -print0 |
      while IFS= read -r -d '' rel; do
        rel="${rel#./}"
        printf '%s\0' "$HOME/$rel"
      done
    )
  done
}

collect_conflicts() {
  collect_targets |
  sort -zu |
  while IFS= read -r -d '' target; do
    [[ -z "$target" ]] && continue

    if [[ -e "$target" && ! -L "$target" ]]; then
      printf '%s\0' "$target"
      continue
    fi

    local parent="$target"
    while true; do
      parent="$(dirname -- "$parent")"
      [[ "$parent" = "/" || "$parent" = "$HOME" ]] && break
      if [[ -e "$parent" && ! -d "$parent" ]]; then
        printf '%s\0' "$target"
        break
      fi
    done
  done
}

backup_conflicts() {
  local backup="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup"

  local -a conflicts=()
  while IFS= read -r -d '' p; do
    conflicts+=("$p")
  done < <(collect_conflicts)

  ((${#conflicts[@]} == 0)) && {
    info "No stow conflicts."
    return 0
  }

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

hook_block_for() {
  local target_name="$1"
  case "$target_name" in
    autostart.conf)
      cat <<'EOF'
# >>> dotfiles-managed custom hooks >>>
source = ~/.config/hypr/custom/autostart.conf
# <<< dotfiles-managed custom hooks <<<
EOF
      ;;
    bindings.conf)
      cat <<'EOF'
# >>> dotfiles-managed custom hooks >>>
source = ~/.config/hypr/custom/bindings.conf
# <<< dotfiles-managed custom hooks <<<
EOF
      ;;
    input.conf)
      cat <<'EOF'
# >>> dotfiles-managed custom hooks >>>
source = ~/.config/hypr/custom/input.conf
# <<< dotfiles-managed custom hooks <<<
EOF
      ;;
    looknfeel.conf)
      cat <<'EOF'
# >>> dotfiles-managed custom hooks >>>
source = ~/.config/hypr/custom/looknfeel.conf
# <<< dotfiles-managed custom hooks <<<
EOF
      ;;
    monitors.conf)
      cat <<'EOF'
# >>> dotfiles-managed custom hooks >>>
source = ~/.config/hypr/custom/monitors.conf
# <<< dotfiles-managed custom hooks <<<
EOF
      ;;
    *)
      return 1
      ;;
  esac
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
    flags=re.S
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
  ensure_hook_block_in_file "$HOME/.config/hypr/autostart.conf" "$(hook_block_for autostart.conf)"
  ensure_hook_block_in_file "$HOME/.config/hypr/bindings.conf" "$(hook_block_for bindings.conf)"
  ensure_hook_block_in_file "$HOME/.config/hypr/input.conf" "$(hook_block_for input.conf)"
  ensure_hook_block_in_file "$HOME/.config/hypr/looknfeel.conf" "$(hook_block_for looknfeel.conf)"
  ensure_hook_block_in_file "$HOME/.config/hypr/monitors.conf" "$(hook_block_for monitors.conf)"
}

preview_hooks() {
  preview_hook_action "$HOME/.config/hypr/autostart.conf" "$(hook_block_for autostart.conf)"
  preview_hook_action "$HOME/.config/hypr/bindings.conf" "$(hook_block_for bindings.conf)"
  preview_hook_action "$HOME/.config/hypr/input.conf" "$(hook_block_for input.conf)"
  preview_hook_action "$HOME/.config/hypr/looknfeel.conf" "$(hook_block_for looknfeel.conf)"
  preview_hook_action "$HOME/.config/hypr/monitors.conf" "$(hook_block_for monitors.conf)"
}

remove_hooks() {
  remove_hook_block_from_file "$HOME/.config/hypr/autostart.conf"
  remove_hook_block_from_file "$HOME/.config/hypr/bindings.conf"
  remove_hook_block_from_file "$HOME/.config/hypr/input.conf"
  remove_hook_block_from_file "$HOME/.config/hypr/looknfeel.conf"
  remove_hook_block_from_file "$HOME/.config/hypr/monitors.conf"
  info "Removed managed hook blocks from Omarchy Hypr files"
}

printf 'Mode    : %s\n' "$MODE"
printf 'Packages: %s\n\n' "${PACKAGES[*]}"

case "$MODE" in
  dry-run)
    require_stow
    ensure_dirs
    info "Preview stow:"
    run_stow -n "${PACKAGES[@]}" || true
    info "Preview hook updates:"
    preview_hooks
    ;;
  check)
    require_stow
    mapfile -d '' -t conflicts < <(collect_conflicts)
    if ((${#conflicts[@]} == 0)); then
      echo "No stow conflicts."
    else
      echo "Conflicts:"
      for p in "${conflicts[@]}"; do
        printf '%s\n' "$p"
      done
      exit 2
    fi
    ;;
  install)
    require_stow
    ensure_dirs
    backup_conflicts
    info "Apply stow:"
    run_stow "${PACKAGES[@]}"
    info "Apply hook updates:"
    ensure_hooks
    ;;
  apply)
    require_stow
    ensure_dirs
    info "Preview stow:"
    run_stow -n "${PACKAGES[@]}" || true
    info "Apply stow:"
    run_stow "${PACKAGES[@]}"
    info "Apply hook updates:"
    ensure_hooks
    ;;
  uninstall)
    require_stow
    run_stow -D "${PACKAGES[@]}"
    remove_hooks
    ;;
  *)
    err "Invalid mode: $MODE"
    exit 1
    ;;
esac

echo
echo "Done."
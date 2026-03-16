#!/usr/bin/env bash
set -euo pipefail

MODE="apply"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
PACKAGES=(bash hypr waybar scripts zellij omarchy ghostty)

HYPR_ROOT_CONF="$HOME/.config/hypr/hyprland.conf"
OMARCHY_THEME_SET_HOOK="$HOME/.config/omarchy/hooks/theme-set"

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
  ~/.config/waybar/config.jsonc
  ~/.config/waybar/style.css
  ~/.config/waybar/modules/*
  ~/.config/waybar/*.sh
  ~/.config/ghostty/config
  ~/.local/bin/*
  ~/.config/zellij/layouts/*.kdl
  ~/.config/omarchy/themed/zellij.kdl.tpl

Also ensures managed hook blocks exist in:
  ~/.config/hypr/hyprland.conf
  ~/.config/omarchy/hooks/theme-set

Managed hook block:
  source = ~/.config/hypr/custom/*
  omarchy-zellij-theme-set "$@"

Modes:
  --apply     Restow packages and ensure hook block
  --dry-run   Preview stow changes and hook update only
  --install   One-time setup: back up conflicting target files, then apply
  --check     Check whether stow would succeed
  --uninstall Remove stowed symlinks and managed hook block
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
    "$HOME/.config/waybar" \
    "$HOME/.local/bin" \
    "$HOME/.config/omarchy/themed" \
    "$HOME/.config/omarchy/hooks"
}

ensure_script_permissions() {
  local bindir="$DOTFILES_DIR/scripts/.local/bin"
  [[ -d "$bindir" ]] || return 0

  local script target
  while IFS= read -r -d '' script; do
    chmod +x "$script"
    target="$HOME/.local/bin/$(basename "$script")"
    [[ -e "$target" ]] && chmod +x "$target"
  done < <(find "$bindir" -maxdepth 1 -type f -print0)
}

ensure_waybar_script_permissions() {
  local waybar_dir="$DOTFILES_DIR/waybar/.config/waybar"
  [[ -d "$waybar_dir" ]] || return 0

  local script target
  while IFS= read -r -d '' script; do
    chmod +x "$script"
    target="$HOME/.config/waybar/$(basename "$script")"
    [[ -e "$target" ]] && chmod +x "$target"
  done < <(find "$waybar_dir" -maxdepth 1 -type f -name '*.sh' -print0)
}

remove_matching_absolute_symlinks() {
  local pkg pkgdir rel source target source_resolved target_resolved link_target

  for pkg in "${PACKAGES[@]}"; do
    pkgdir="$DOTFILES_DIR/$pkg"
    while IFS= read -r -d '' rel; do
      source="$pkgdir/${rel#./}"
      target="$HOME/${rel#./}"

      [[ -L "$target" ]] || continue
      link_target="$(readlink -- "$target" || true)"
      [[ "$link_target" = /* ]] || continue

      source_resolved="$(readlink -f -- "$source" || true)"
      target_resolved="$(readlink -f -- "$target" || true)"

      if [[ -n "$source_resolved" && "$source_resolved" == "$target_resolved" ]]; then
        rm -f -- "$target"
        info "Removed absolute symlink to let stow manage: $target"
      fi
    done < <(
      cd "$pkgdir"
      find . \( -type f -o -type l \) -print0
    )
  done
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

hook_block() {
  cat <<'EOF'
# >>> dotfiles-managed custom hooks >>>
source = ~/.config/hypr/custom/*
# <<< dotfiles-managed custom hooks <<<
EOF
}

omarchy_hook_block() {
  cat <<'EOF'
# >>> dotfiles-managed omarchy-zellij-theme >>>
if command -v omarchy-zellij-theme-set >/dev/null 2>&1; then
  omarchy-zellij-theme-set "$@"
fi
# <<< dotfiles-managed omarchy-zellij-theme <<<
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

remove_omarchy_hook_block_from_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  python3 - "$file" <<'PY'
import pathlib, re, sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()

new = re.sub(
    r'\n?# >>> dotfiles-managed omarchy-zellij-theme >>>\n.*?# <<< dotfiles-managed omarchy-zellij-theme <<<\n?',
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

ensure_omarchy_theme_hook_file() {
  if [[ ! -f "$OMARCHY_THEME_SET_HOOK" ]]; then
    {
      printf '#!/usr/bin/env bash\n'
      printf 'set -euo pipefail\n'
      printf '\n'
    } > "$OMARCHY_THEME_SET_HOOK"
    chmod +x "$OMARCHY_THEME_SET_HOOK"
    info "Created Omarchy theme-set hook file at $OMARCHY_THEME_SET_HOOK"
  fi
}

ensure_omarchy_hook_block_in_file() {
  local file="$1"
  local block="$2"

  if [[ ! -f "$file" ]]; then
    err "Expected Omarchy hook file does not exist: $file"
    exit 1
  fi

  remove_omarchy_hook_block_from_file "$file"
  {
    printf '\n'
    printf '%s\n' "$block"
  } >> "$file"

  info "Ensured managed Omarchy hook block in $file"
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
  ensure_hook_block_in_file "$HYPR_ROOT_CONF" "$(hook_block)"
  ensure_omarchy_theme_hook_file
  ensure_omarchy_hook_block_in_file "$OMARCHY_THEME_SET_HOOK" "$(omarchy_hook_block)"
}

preview_hooks() {
  preview_hook_action "$HYPR_ROOT_CONF" "$(hook_block)"
  preview_hook_action "$OMARCHY_THEME_SET_HOOK" "$(omarchy_hook_block)"
}

remove_hooks() {
  remove_hook_block_from_file "$HYPR_ROOT_CONF"
  info "Removed managed hook block from $HYPR_ROOT_CONF"
  remove_omarchy_hook_block_from_file "$OMARCHY_THEME_SET_HOOK"
  info "Removed managed hook block from $OMARCHY_THEME_SET_HOOK"
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
    info "Preview hook update:"
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
    remove_matching_absolute_symlinks
    info "Backing up conflicting target files:"
    backup_conflicting_targets
    info "Apply stow:"
    run_stow -R "${PACKAGES[@]}"
    ensure_script_permissions
    ensure_waybar_script_permissions
    info "Apply hook update:"
    ensure_hooks
    ;;
  apply)
    ensure_dirs
    remove_matching_absolute_symlinks
    info "Apply stow:"
    run_stow -R "${PACKAGES[@]}"
    ensure_script_permissions
    ensure_waybar_script_permissions
    info "Apply hook update:"
    ensure_hooks
    ;;
  uninstall)
    info "Remove stow symlinks:"
    run_stow -D "${PACKAGES[@]}"
    info "Remove hook update:"
    remove_hooks
    ;;
  *)
    err "Invalid mode: $MODE"
    exit 1
    ;;
esac

echo
echo "Done."

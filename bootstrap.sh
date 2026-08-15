#!/usr/bin/env bash
set -euo pipefail

MODE="apply"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
PACKAGES=(bash hypr scripts)
WORK_VPN_PLUGIN_SOURCE="$DOTFILES_DIR/work-vpn-shell/.config/omarchy/plugins/dn.work-vpn"
WORK_VPN_PLUGIN_TARGET="$HOME/.config/omarchy/plugins/dn.work-vpn"

err()  { printf 'Error: %s\n' "$*" >&2; }
info() { printf '[*] %s\n' "$*"; }

usage() {
  cat <<'USAGE'
Usage: bootstrap.sh [--dry-run|--apply|--install|--check|--uninstall]

Stows the Quattro-compatible personal configuration:
  ~/.bashrc
  ~/.config/hypr/{bindings,input,autostart}.lua
  ~/.config/hypr/hyprsunset.conf
  ~/.config/omarchy/plugins/dn.work-vpn
  ~/.local/bin/*

Modes:
  --apply     Restow packages
  --dry-run   Preview stow changes
  --install   Back up conflicting targets, then apply
  --check     Check whether stow would succeed
  --uninstall Unstow managed files
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

for package in "${PACKAGES[@]}"; do
  [[ -d "$DOTFILES_DIR/$package" ]] || {
    err "Missing package dir: $DOTFILES_DIR/$package"
    exit 1
  }
done

command -v stow >/dev/null 2>&1 || {
  err "Required command not found: stow"
  exit 1
}

run_stow() {
  stow -v -d "$DOTFILES_DIR" -t "$HOME" "$@"
}

ensure_dirs() {
  mkdir -p \
    "$HOME/.config/hypr" \
    "$HOME/.config/omarchy/plugins" \
    "$HOME/.local/bin"
}

ensure_executable_files() {
  local dir file target
  for dir in "$DOTFILES_DIR/scripts/.local/bin"; do
    [[ -d "$dir" ]] || continue
    while IFS= read -r -d '' file; do
      chmod +x "$file"
      target="$HOME/.local/bin/$(basename "$file")"
      [[ -e "$target" ]] && chmod +x "$target"
    done < <(find "$dir" -maxdepth 1 -type f -print0)
  done
}

sync_work_vpn_plugin() {
  if [[ -L "$WORK_VPN_PLUGIN_TARGET" ]]; then
    unlink "$WORK_VPN_PLUGIN_TARGET"
  fi
  mkdir -p "$WORK_VPN_PLUGIN_TARGET"
  rm -f \
    "$WORK_VPN_PLUGIN_TARGET/Panel.qml" \
    "$WORK_VPN_PLUGIN_TARGET/WorkVpnPanel.qml"
  install -m644 \
    "$WORK_VPN_PLUGIN_SOURCE/manifest.json" \
    "$WORK_VPN_PLUGIN_SOURCE/BarWidget.qml" \
    "$WORK_VPN_PLUGIN_TARGET/"
}

collect_package_files() {
  local package
  for package in "${PACKAGES[@]}"; do
    (
      cd "$DOTFILES_DIR/$package"
      find . \( -type f -o -type l \) -print0
    )
  done
}

owner_for_relpath() {
  local rel="$1" package
  for package in "${PACKAGES[@]}"; do
    if [[ -e "$DOTFILES_DIR/$package/${rel#./}" || -L "$DOTFILES_DIR/$package/${rel#./}" ]]; then
      printf '%s\n' "$package"
      return 0
    fi
  done
  return 1
}

backup_conflicting_targets() {
  local backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
  local rel package source target resolved moved=0

  while IFS= read -r -d '' rel; do
    package="$(owner_for_relpath "$rel")" || continue
    source="$DOTFILES_DIR/$package/${rel#./}"
    target="$HOME/${rel#./}"
    [[ -e "$target" || -L "$target" ]] || continue

    if [[ -L "$target" ]]; then
      resolved="$(readlink -f -- "$target" || true)"
      [[ "$resolved" == "$(readlink -f -- "$source")" ]] && continue
    fi

    if (( moved == 0 )); then
      mkdir -p "$backup_dir"
      info "Backing up conflicting files to $backup_dir"
    fi
    mkdir -p "$backup_dir/$(dirname "${rel#./}")"
    mv -- "$target" "$backup_dir/${rel#./}"
    info "Moved: $target"
    moved=1
  done < <(collect_package_files | sort -zu)

  (( moved == 1 )) || info "No conflicting target files to back up"
}

printf 'Mode    : %s\n' "$MODE"
printf 'Packages: %s\n\n' "${PACKAGES[*]}"

case "$MODE" in
  dry-run)
    run_stow -n -R "${PACKAGES[@]}"
    info "Would sync Work VPN plugin to $WORK_VPN_PLUGIN_TARGET"
    ;;
  check)
    if run_stow -n -R "${PACKAGES[@]}" >/dev/null; then
      echo "Stow check passed."
    else
      err "Stow check failed."
      exit 2
    fi
    omarchy plugin validate "$WORK_VPN_PLUGIN_SOURCE"
    ;;
  install)
    ensure_dirs
    backup_conflicting_targets
    run_stow -R "${PACKAGES[@]}"
    ensure_executable_files
    sync_work_vpn_plugin
    ;;
  apply)
    ensure_dirs
    run_stow -R "${PACKAGES[@]}"
    ensure_executable_files
    sync_work_vpn_plugin
    ;;
  uninstall)
    run_stow -D "${PACKAGES[@]}"
    ;;
esac

echo
echo "Done."

#!/usr/bin/env bash
set -euo pipefail

MODE="apply"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
PACKAGES=(bash hypr applications scripts)
WORK_VPN_PLUGIN_SOURCE="$DOTFILES_DIR/work-vpn-shell/.config/omarchy/plugins/dn.work-vpn"
WORK_VPN_PLUGIN_TARGET="$HOME/.config/omarchy/plugins/dn.work-vpn"

err()  { printf 'Error: %s\n' "$*" >&2; }
info() { printf '[*] %s\n' "$*"; }

usage() {
  cat <<'USAGE'
Usage: bootstrap.sh [--dry-run|--apply|--install|--check|--doctor|--uninstall]

Stows the Quattro-compatible personal configuration:
  ~/.bashrc
  ~/.config/hypr/{bindings,input,autostart}.lua
  ~/.config/hypr/hyprsunset.conf
  ~/.local/share/applications/Netflix.desktop
  ~/.config/omarchy/plugins/dn.work-vpn
  ~/.local/bin/*

Modes:
  --apply     Restow packages
  --dry-run   Preview stow changes
  --install   Back up conflicting targets, then apply
  --check     Check whether stow would succeed
  --doctor    Diagnose the live managed configuration without changing it
  --uninstall Unstow managed files
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   MODE="dry-run"; shift ;;
    --apply)     MODE="apply"; shift ;;
    --install)   MODE="install"; shift ;;
    --check)     MODE="check"; shift ;;
    --doctor)    MODE="doctor"; shift ;;
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

[[ $MODE == "doctor" ]] || command -v stow >/dev/null 2>&1 || {
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
    "$HOME/.local/share/applications" \
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

remove_work_vpn_plugin() {
  if [[ -e "$WORK_VPN_PLUGIN_TARGET" || -L "$WORK_VPN_PLUGIN_TARGET" ]]; then
    rm -rf -- "$WORK_VPN_PLUGIN_TARGET"
  fi
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

DOCTOR_PASSES=0
DOCTOR_WARNINGS=0
DOCTOR_FAILURES=0

doctor_pass() {
  printf 'PASS  %s\n' "$1"
  ((DOCTOR_PASSES += 1))
}

doctor_warn() {
  printf 'WARN  %s\n' "$1"
  ((DOCTOR_WARNINGS += 1))
}

doctor_fail() {
  printf 'FAIL  %s\n' "$1"
  ((DOCTOR_FAILURES += 1))
}

doctor_command() {
  local command="$1" importance="${2:-required}"
  if command -v "$command" >/dev/null 2>&1; then
    doctor_pass "$command is available"
  elif [[ $importance == "optional" ]]; then
    doctor_warn "$command is unavailable"
  else
    doctor_fail "$command is unavailable"
  fi
}

doctor_stow_links() {
  local rel package source target source_resolved target_resolved issues=0

  while IFS= read -r -d '' rel; do
    package="$(owner_for_relpath "$rel")" || continue
    source="$DOTFILES_DIR/$package/${rel#./}"
    target="$HOME/${rel#./}"

    if [[ ! -e $target && ! -L $target ]]; then
      doctor_fail "Missing managed target: $target"
      ((issues += 1))
      continue
    fi

    source_resolved="$(readlink -f -- "$source" || true)"
    target_resolved="$(readlink -f -- "$target" || true)"
    if [[ $source_resolved != "$target_resolved" ]]; then
      doctor_fail "Managed target does not resolve to its source: $target"
      ((issues += 1))
    fi
  done < <(collect_package_files | sort -zu)

  ((issues > 0)) || doctor_pass "All Stow-managed targets resolve to repository sources"
}

doctor_work_vpn_plugin() {
  local file issues=0

  if omarchy plugin validate "$WORK_VPN_PLUGIN_SOURCE" >/dev/null 2>&1; then
    doctor_pass "Work VPN plugin source validates"
  else
    doctor_fail "Work VPN plugin source is invalid"
  fi

  for file in manifest.json BarWidget.qml; do
    if [[ ! -f $WORK_VPN_PLUGIN_TARGET/$file ]]; then
      doctor_fail "Missing copied Work VPN plugin file: $file"
      ((issues += 1))
    elif ! cmp -s "$WORK_VPN_PLUGIN_SOURCE/$file" "$WORK_VPN_PLUGIN_TARGET/$file"; then
      doctor_fail "Copied Work VPN plugin file is stale: $file"
      ((issues += 1))
    fi
  done
  ((issues > 0)) || doctor_pass "Installed Work VPN plugin matches its source"
}

doctor_work_vpn_system() {
  local helper_source="$DOTFILES_DIR/system/usr/local/libexec/omarchy-work-vpn-privileged"
  local helper_target="/usr/local/libexec/omarchy-work-vpn-privileged"
  local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/work-vpn/config"
  local config_mode

  if [[ ! -x $helper_target ]]; then
    doctor_fail "Privileged Work VPN helper is not installed"
  elif cmp -s "$helper_source" "$helper_target"; then
    doctor_pass "Privileged Work VPN helper matches its tracked source"
  else
    doctor_fail "Privileged Work VPN helper differs from its tracked source"
  fi

  if sudo -n -l "$helper_target" disconnect >/dev/null 2>&1; then
    doctor_pass "Work VPN disconnect is authorized without a password"
  else
    doctor_fail "Work VPN disconnect sudo rule is missing or unavailable"
  fi

  if [[ ! -f $config_file ]]; then
    doctor_fail "Machine-private Work VPN config is missing"
  else
    config_mode="$(stat -c '%a' "$config_file" 2>/dev/null || true)"
    if [[ $config_mode == "600" ]]; then
      doctor_pass "Machine-private Work VPN config has mode 600"
    else
      doctor_fail "Machine-private Work VPN config mode is ${config_mode:-unknown}, expected 600"
    fi

    if grep -Eq '^[[:space:]]*VPN_SERVER="?[^"[:space:]]+"?[[:space:]]*$' "$config_file" &&
       ! grep -Eq '^[[:space:]]*VPN_SERVER="?vpn\.example\.com"?[[:space:]]*$' "$config_file" &&
       grep -Eq '^[[:space:]]*VPN_USERNAME="?[^"[:space:]]+"?[[:space:]]*$' "$config_file" &&
       ! grep -Eq '^[[:space:]]*VPN_USERNAME="?your\.username"?[[:space:]]*$' "$config_file"; then
      doctor_pass "Work VPN server and username are configured"
    else
      doctor_fail "Work VPN server or username is not configured"
    fi
  fi
}

doctor_desktop_entry() {
  local desktop_file="$DOTFILES_DIR/applications/.local/share/applications/Netflix.desktop"
  local icon_file="$HOME/.local/share/icons/hicolor/64x64/apps/netflix.png"

  if command -v desktop-file-validate >/dev/null 2>&1; then
    if desktop-file-validate "$desktop_file" >/dev/null 2>&1; then
      doctor_pass "Netflix desktop entry validates"
    else
      doctor_fail "Netflix desktop entry is invalid"
    fi
  else
    doctor_warn "desktop-file-validate is unavailable"
  fi

  if [[ -s $icon_file ]]; then
    doctor_pass "Netflix launcher icon is installed"
  else
    doctor_fail "Netflix launcher icon is missing"
  fi
}

doctor_hyprland() {
  local errors
  if ! command -v hyprctl >/dev/null 2>&1; then
    doctor_fail "hyprctl is unavailable"
    return
  fi

  if errors="$(hyprctl configerrors 2>/dev/null)"; then
    if [[ -z $errors ]]; then
      doctor_pass "Hyprland reports no configuration errors"
    else
      doctor_fail "Hyprland reports configuration errors"
      printf '%s\n' "$errors" | sed 's/^/      /'
    fi
  else
    doctor_warn "Hyprland is not reachable from this session"
  fi
}

run_doctor() {
  printf 'Core tools\n'
  doctor_command stow
  doctor_command omarchy
  doctor_command openconnect
  doctor_command secret-tool optional
  doctor_command zenity optional

  printf '\nRepository and Stow\n'
  if command -v stow >/dev/null 2>&1 && run_stow -n -R "${PACKAGES[@]}" >/dev/null 2>&1; then
    doctor_pass "Stow restow simulation succeeds"
  else
    doctor_fail "Stow restow simulation fails"
  fi
  doctor_stow_links

  printf '\nOmarchy\n'
  doctor_hyprland
  doctor_work_vpn_plugin

  printf '\nWork VPN\n'
  doctor_work_vpn_system

  printf '\nApplications\n'
  doctor_desktop_entry

  printf '\nSummary: %d passed, %d warnings, %d failed\n' \
    "$DOCTOR_PASSES" "$DOCTOR_WARNINGS" "$DOCTOR_FAILURES"

  ((DOCTOR_FAILURES == 0))
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
  doctor)
    run_doctor
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
    remove_work_vpn_plugin
    ;;
esac

echo
echo "Done."

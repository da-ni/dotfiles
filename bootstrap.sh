#!/usr/bin/env bash
set -euo pipefail

PROFILE="home"
MODE="apply"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"

err()  { printf 'Error: %s\n' "$*" >&2; }
info() { printf '[*] %s\n' "$*"; }

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--profile home|work|server] [--dry-run|--apply|--uninstall]

Profiles select which package dirs (subfolders of the repo) to stow:
  home   : scripts bash hypr waybar git
  work   : scripts bash hypr waybar git
  server : scripts bash git

Modes:
  --apply     Create/update symlinks in $HOME (default)
  --dry-run   Preview operations (no changes)
  --uninstall Remove symlinks previously created by this repo
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)   PROFILE="${2:-}"; shift 2 ;;
    --dry-run)   MODE="dry-run"; shift ;;
    --apply)     MODE="apply"; shift ;;
    --uninstall) MODE="uninstall"; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) err "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

command -v pacman >/dev/null 2>&1 || {
  err "This bootstrap is intended for Arch (pacman not found)."
  exit 1
}

case "$PROFILE" in
  home)   PACKAGES=(bash bin hypr usr-local waybar ) ;;
  work)   PACKAGES=(bash bin hypr openconnect usr-local waybar) ;;
  server) PACKAGES=(bash) ;;
  *) err "Unknown profile: $PROFILE (expected: home|work|server)"; exit 1 ;;
esac

missing=()
for p in "${PACKAGES[@]}"; do
  [[ -d "$DOTFILES_DIR/$p" ]] || missing+=("$p")
done
if ((${#missing[@]})); then
  err "Package dir(s) not found in repo: ${missing[*]}"
  exit 1
fi

if ! command -v stow >/dev/null 2>&1; then
  info "Installing stow ..."
  sudo pacman -S --needed --noconfirm stow
fi
if ! command -v hx >/dev/null 2>&1; then
  info "Installing Helix ..."
  sudo pacman -S --needed --noconfirm helix
fi

mkdir -p "$HOME/.local/bin" "$HOME/.config"

run_stow() { stow -v -d "$DOTFILES_DIR" -t "$HOME" "$@"; }

printf 'Profile : %s\n' "$PROFILE"
printf 'Mode    : %s\n' "$MODE"
printf 'Packages: %s\n\n' "${PACKAGES[*]}"

case "$MODE" in
  dry-run)
    info "Preview:"
    run_stow -n "${PACKAGES[@]}" || true
    ;;
  uninstall)
    run_stow -D "${PACKAGES[@]}"
    ;;
  apply)
    info "Preview:"
    run_stow -n "${PACKAGES[@]}" || true
    info "Apply:"
    run_stow "${PACKAGES[@]}"
    ;;
  *) err "Invalid mode: $MODE"; exit 1 ;;
esac

echo
echo "Done."
echo "Tip: keep per-host overrides untracked, e.g.:"
echo "  ~/.bashrc.local (sourced from ~/.bashrc)"
echo "  ~/.config/hypr/local.conf (source from hyprland.conf)"

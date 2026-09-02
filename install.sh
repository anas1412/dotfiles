#!/usr/bin/env bash
# Set up this machine from the repo.
#   ./install.sh              symlink all config packages
#   ./install.sh fish kitty   symlink only those
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

command -v stow >/dev/null || { echo "stow is not installed:  sudo pacman -S stow"; exit 1; }

PACKAGES=(fish kitty alacritty fastfetch opencode)
[ $# -gt 0 ] && PACKAGES=("$@")

for p in "${PACKAGES[@]}"; do
  [ -d "$p" ] || { echo "skip $p (not in repo)"; continue; }
  stow -v -R -t "$HOME" "$p" && echo "linked $p"
done

echo
echo "Config symlinked. Not applied automatically:"
echo "  ./bin/restore-kde        KDE theme + Plasma settings (then log out)"
echo "  packages/*.txt           see README for reinstalling packages"

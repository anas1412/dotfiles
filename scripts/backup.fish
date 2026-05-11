#!/usr/bin/env fish

set -l ROOT "$HOME/dotfiles"
set -l LOG "$ROOT/backup.log"

set -l CFG "$ROOT/config"
set -l PKG "$ROOT/packages"

function log
    echo "["(date '+%Y-%m-%d %H:%M:%S')"] $argv" | tee -a $LOG
end

log "=== BACKUP START ==="

# clean snapshot
rm -rf $CFG/kde $CFG/fish $CFG/alacritty $CFG/kitty $CFG/ghostty $CFG/opencode
mkdir -p $CFG/kde $CFG/fish $CFG/alacritty $CFG/kitty $CFG/ghostty $CFG/opencode $PKG

# packages
log "Exporting native packages..."
pacman -Qqen > $PKG/pacman-native.txt

log "Exporting AUR packages..."
pacman -Qqem > $PKG/pacman-foreign.txt

# fish
log "Copying Fish config..."
cp -r ~/.config/fish $CFG/ 2>/dev/null

# KDE (selective safe files)
log "Copying KDE config..."
set files kdeglobals kwinrc plasmarc kglobalshortcutsrc dolphinrc konsolerc mimeapps.list

for f in $files
    if test -f ~/.config/$f
        cp ~/.config/$f $CFG/kde/
        log "Copied KDE: $f"
    end
end

# terminal configs
function safe_copy
    set src $argv[1]
    set dest $argv[2]
    set name $argv[3]

    if test -e $src
        cp -r $src $dest 2>/dev/null
        log "Copied $name"
    else
        log "WARN: missing $name"
    end
end

safe_copy ~/.config/alacritty $CFG/alacritty "alacritty"
safe_copy ~/.config/kitty $CFG/kitty "kitty"
safe_copy ~/.config/ghostty $CFG/ghostty "ghostty"

# opencode (selective — skip node_modules)
log "Copying Opencode config..."
set opencode_files opencode.json .gitignore package.json
for f in $opencode_files
    if test -f ~/.config/opencode/$f
        cp ~/.config/opencode/$f $CFG/opencode/
        log "Copied Opencode: $f"
    end
end

# style export
log "Exporting KDE style..."
fish $ROOT/scripts/kde_style.fish

log "=== BACKUP DONE ==="

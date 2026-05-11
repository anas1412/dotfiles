#!/usr/bin/env fish

set -l ROOT "$HOME/dotfiles"
set -l LOG "$ROOT/restore.log"

function log
    echo "["(date '+%Y-%m-%d %H:%M:%S')"] $argv" | tee -a $LOG
end

function fail
    log "ERROR: $argv"
    exit 1
end

log "=== RESTORE START ==="

# packages
if test -f $ROOT/packages/pacman-native.txt
    sudo pacman -S --needed - < $ROOT/packages/pacman-native.txt
else
    log "WARN: missing native package list"
end

if test -f $ROOT/packages/pacman-foreign.txt
    if type -q paru
        paru -S --needed - < $ROOT/packages/pacman-foreign.txt
    else
        log "WARN: paru missing"
    end
end

# configs base
cp -r $ROOT/config/fish/. ~/.config/fish/ 2>/dev/null
cp -r $ROOT/config/kde/. ~/.config/kde/ 2>/dev/null

# terminal restore helper
function restore_cfg
    set src $argv[1]
    set dest $argv[2]
    set name $argv[3]

    if test -d $src
        mkdir -p $dest/$name
        cp -r $src/. $dest/$name/ 2>/dev/null
        log "Restored $name"
    else
        log "WARN: missing $name config"
    end
end

restore_cfg $ROOT/config/alacritty ~/.config "alacritty"
restore_cfg $ROOT/config/kitty ~/.config "kitty"
restore_cfg $ROOT/config/ghostty ~/.config "ghostty"

# KDE style (safe parsed system from previous fix)
set STYLE_FILE "$ROOT/config/kde/style.env"

if test -f $STYLE_FILE
    set ICON_THEME ""
    set CURSOR_THEME ""
    set COLOR_SCHEME ""
    set FONT ""

    for line in (cat $STYLE_FILE)
        set parts (string split "=" $line)
        if test (count $parts) -lt 2
            continue
        end

        set key $parts[1]
        set value (string join "=" $parts[2..-1])

        switch $key
            case ICON_THEME
                set ICON_THEME $value
            case CURSOR_THEME
                set CURSOR_THEME $value
            case COLOR_SCHEME
                set COLOR_SCHEME $value
            case FONT
                set FONT $value
        end
    end

    if type -q kwriteconfig5
        kwriteconfig5 --file kdeglobals --group Icons --key Theme "$ICON_THEME"
        kwriteconfig5 --file kdeglobals --group Icons --key CursorTheme "$CURSOR_THEME"
        kwriteconfig5 --file kdeglobals --group General --key ColorScheme "$COLOR_SCHEME"
        kwriteconfig5 --file kdeglobals --group General --key font "$FONT"
    else
        log "WARN: KDE tools missing"
    end

    if type -q kbuildsycoca5
        kbuildsycoca5 >/dev/null 2>&1
    end
else
    log "WARN: style.env missing"
end

log "=== RESTORE DONE ==="

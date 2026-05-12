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

# ── Flag defaults ──────────────────────────────

set -l do_all 1
set -l do_packages 0
set -l do_configs 0
set -l do_themes 0

if set -q argv[1]
    set do_all 0
    for arg in $argv
        switch $arg
            case --all
                set do_all 1
            case --packages
                set do_packages 1
            case --configs
                set do_configs 1
            case --themes
                set do_themes 1
            case --help -h
                echo "Usage: fish scripts/restore.fish [options]"
                echo ""
                echo "Options:"
                echo "  --all        Restore everything (default)"
                echo "  --packages   Install packages only"
                echo "  --configs    Restore configs only (fish, KDE, terminals, fastfetch)"
                echo "  --themes     Restore themes only (archive + KDE style vars)"
                echo "  --help, -h   Show this help"
                echo ""
                echo "Without options, runs full restore."
                exit 0
            case '*'
                echo "Unknown option: $arg"
                echo "Use --help to see available options."
                exit 1
        end
    end
end

if test $do_all -eq 1
    set do_packages 1
    set do_configs 1
    set do_themes 1
end

log "=== RESTORE START ==="

# ── Packages ───────────────────────────────────

if test $do_packages -eq 1
    log "Installing native packages..."
    if test -f $ROOT/packages/pacman-native.txt
        sudo pacman -S --needed - < $ROOT/packages/pacman-native.txt
    else
        log "WARN: missing native package list"
    end

    log "Installing AUR packages..."
    if test -f $ROOT/packages/pacman-foreign.txt
        if type -q paru
            paru -S --needed - < $ROOT/packages/pacman-foreign.txt
        else
            log "WARN: paru missing, skipping AUR packages"
        end
    end
end

# ── Configs ────────────────────────────────────

if test $do_configs -eq 1
    log "Restoring fish config..."
    if test -d $ROOT/config/fish
        mkdir -p ~/.config/fish
        cp -r $ROOT/config/fish/. ~/.config/fish/ 2>/dev/null
        rm -f ~/.config/fish/fish_variables ~/.config/fish/fish_history 2>/dev/null
        log "  Restored fish config"
    else
        log "  WARN: missing fish config"
    end

    log "Restoring KDE configs..."
    if test -d $ROOT/config/kde
        cp -r $ROOT/config/kde/. ~/.config/kde/ 2>/dev/null
        log "  Restored KDE configs"
    else
        log "  WARN: missing KDE configs"
    end

    function restore_cfg
        set src $argv[1]
        set dest $argv[2]
        set name $argv[3]
        if test -d $src
            mkdir -p $dest/$name
            cp -r $src/. $dest/$name/ 2>/dev/null
            log "  Restored $name"
        else
            log "  WARN: missing $name config"
        end
    end

    restore_cfg $ROOT/config/alacritty ~/.config "alacritty"
    restore_cfg $ROOT/config/kitty ~/.config "kitty"
    restore_cfg $ROOT/config/ghostty ~/.config "ghostty"
    restore_cfg $ROOT/config/fastfetch ~/.config "fastfetch"
end

# ── Themes ─────────────────────────────────────

if test $do_themes -eq 1
    log "Restoring custom themes..."
    if test -f $ROOT/config/themes.tar.gz
        tar -xzf $ROOT/config/themes.tar.gz -C $ROOT/config/ 2>/dev/null
        and cp -r $ROOT/config/themes/. ~/.local/share/ 2>/dev/null
        and rm -rf $ROOT/config/themes
        and log "  Restored custom themes"
        or log "  WARN: failed to restore themes"
    else
        log "  WARN: missing themes archive (themes.tar.gz)"
    end

    log "Applying KDE style vars..."
    set STYLE_FILE "$ROOT/config/kde/style.env"

    set -l KWRITE ""
    if type -q kwriteconfig6
        set KWRITE kwriteconfig6
    else if type -q kwriteconfig5
        set KWRITE kwriteconfig5
    end

    set -l KBUILD ""
    if type -q kbuildsycoca6
        set KBUILD kbuildsycoca6
    else if type -q kbuildsycoca5
        set KBUILD kbuildsycoca5
    end

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
                case ICON_THEME;  set ICON_THEME $value
                case CURSOR_THEME; set CURSOR_THEME $value
                case COLOR_SCHEME; set COLOR_SCHEME $value
                case FONT;         set FONT $value
            end
        end

        if test -n "$KWRITE"
            log "  Writing theme values..."
            $KWRITE --file kdeglobals --group Icons --key Theme "$ICON_THEME"
            if test -n "$CURSOR_THEME"
                $KWRITE --file kcminputrc --group Mouse --key cursorTheme "$CURSOR_THEME"
                $KWRITE --file kdeglobals --group Icons --key CursorTheme "$CURSOR_THEME"
            end
            $KWRITE --file kdeglobals --group General --key ColorScheme "$COLOR_SCHEME"
            $KWRITE --file kdeglobals --group General --key font "$FONT"
        else
            log "  WARN: KDE config tools missing"
        end

        if test -n "$KBUILD"
            $KBUILD >/dev/null 2>&1
        end
    else
        log "  WARN: style.env missing"
    end
end

log "=== RESTORE DONE ==="

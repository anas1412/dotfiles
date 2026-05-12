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
rm -rf $CFG/kde $CFG/fish $CFG/alacritty $CFG/kitty $CFG/ghostty $CFG/themes $CFG/themes.tar.gz
mkdir -p $CFG/kde $CFG/fish $CFG/alacritty $CFG/kitty $CFG/ghostty $PKG

# packages
log "Exporting native packages..."
pacman -Qqen > $PKG/pacman-native.txt

log "Exporting AUR packages..."
pacman -Qqem > $PKG/pacman-foreign.txt

# clean previous theme deps (regenerated fresh each run)
rm -f $PKG/theme-deps.txt

# fish (exclude history/variables — don't want typing history in git)
log "Copying Fish config..."
rm -rf $CFG/fish
cp -r ~/.config/fish $CFG/fish
rm -f $CFG/fish/fish_variables $CFG/fish/fish_history 2>/dev/null
log "Copied Fish config"

# KDE (selective safe files — Plasma 6 compatible)
log "Copying KDE config..."
set files \
    kdeglobals kwinrc plasmarc \
    kglobalshortcutsrc dolphinrc konsolerc \
    mimeapps.list kcminputrc \
    kwinrulesrc khotkeysrc klipperrc

set copied 0
set missing 0
for f in $files
    if test -f ~/.config/$f
        cp ~/.config/$f $CFG/kde/
        set copied (math $copied + 1)
    else
        set missing (math $missing + 1)
    end
end
log "KDE: $copied copied, $missing missing (expected)"

# terminal configs
function safe_copy
    set src $argv[1]
    set dest $argv[2]
    set name $argv[3]

    if test -e $src
        set tmp "$dest.tmp"
        rm -rf $tmp
        if cp -r $src $tmp 2>/dev/null
            rm -rf $dest
            mv $tmp $dest
            log "Copied $name"
        else
            log "ERROR: failed to copy $name"
            rm -rf $tmp
        end
    else
        log "WARN: missing $name"
    end
end

safe_copy ~/.config/alacritty $CFG/alacritty "alacritty"
safe_copy ~/.config/kitty $CFG/kitty "kitty"
safe_copy ~/.config/ghostty $CFG/ghostty "ghostty"
safe_copy ~/.config/fastfetch $CFG/fastfetch "fastfetch"

# style export
log "Exporting KDE style..."
fish $ROOT/scripts/kde_style.fish

# custom themes (only what's actively in use, only if in ~/.local/share/)
log "Backing up active custom themes..."
set -l KREAD ""
if type -q kreadconfig6
    set KREAD kreadconfig6
else if type -q kreadconfig5
    set KREAD kreadconfig5
end

function backup_theme
    set -l src $argv[1]
    set -l dest_base $argv[2]
    set -l rel_path $argv[3]
    set -l label $argv[4]

    if test -e $src
        set dest "$dest_base/$rel_path"
        mkdir -p (dirname $dest)
        rm -rf $dest
        cp -r $src $dest 2>/dev/null
        and log "  Theme: $label"
        or log "  WARN: failed to copy $label"
    end
end

if test -n "$KREAD"
    # Color scheme
    set scheme ($KREAD --file kdeglobals --group General --key ColorScheme 2>/dev/null)
    if test -n "$scheme"
        backup_theme "$HOME/.local/share/color-schemes/$scheme.colors" "$CFG/themes" "color-schemes/$scheme.colors" "$scheme (color scheme)"
    end

    # Plasma theme
    set plasma ($KREAD --file plasmarc --group Theme --key name 2>/dev/null)
    if test -n "$plasma"
        backup_theme "$HOME/.local/share/plasma/desktoptheme/$plasma" "$CFG/themes" "plasma/desktoptheme/$plasma" "$plasma (plasma theme)"
    end

    # Window decoration
    set deco ($KREAD --file kwinrc --group "org.kde.kdecoration2" --key theme 2>/dev/null)
    if test -n "$deco"
        set deco_name (string split '__' $deco)[-1]
        backup_theme "$HOME/.local/share/aurorae/themes/$deco_name" "$CFG/themes" "aurorae/themes/$deco_name" "$deco_name (window decoration)"
    end

    # Icon theme
    set icons ($KREAD --file kdeglobals --group Icons --key Theme 2>/dev/null)
    if test -n "$icons"
        backup_theme "$HOME/.local/share/icons/$icons" "$CFG/themes" "icons/$icons" "$icons (icon theme)"
    end

    # Cursor theme
    set cursor ($KREAD --file kcminputrc --group Mouse --key cursorTheme 2>/dev/null)
    if test -z "$cursor"
        set cursor ($KREAD --file kdeglobals --group Icons --key CursorTheme 2>/dev/null)
    end
    if test -n "$cursor"
        backup_theme "$HOME/.local/share/icons/$cursor" "$CFG/themes" "icons/$cursor" "$cursor (cursor theme)"
    end

    # Splash screen
    set splash ($KREAD --file ksplashrc --group KSplash --key Theme 2>/dev/null)
    if test -n "$splash"
        backup_theme "$HOME/.local/share/plasma/look-and-feel/$splash" "$CFG/themes" "plasma/look-and-feel/$splash" "$splash (splash)"
    end
else
    log "  WARN: KDE config reader not available, skipping theme backup"
end

# theme package deps: detect which packages own active theme files in /usr/share/
# (cursors, icons, colors, etc. — so restore installs them automatically)
log "Detecting theme package dependencies..."
if test -n "$KREAD"
    set -l pkg_list $PKG/theme-deps.txt
    rm -f $pkg_list

    function check_theme_pkg
        set -l path $argv[1]
        set -l out $argv[2]
        if test -e $path
            set -l pkg (pacman -Qo $path 2>/dev/null | string replace -r '.* is owned by (\S+).*' '$1')
            if test -n "$pkg"
                echo "$pkg" >> $out
            end
        end
    end

    # Color scheme package
    set scheme ($KREAD --file kdeglobals --group General --key ColorScheme 2>/dev/null)
    if test -n "$scheme"
        check_theme_pkg "/usr/share/color-schemes/$scheme.colors" $pkg_list
        check_theme_pkg "/usr/share/plasma/color-schemes/$scheme.colors" $pkg_list
    end

    # Cursor theme package
    set cursor ($KREAD --file kcminputrc --group Mouse --key cursorTheme 2>/dev/null)
    if test -z "$cursor"
        set cursor ($KREAD --file kdeglobals --group Icons --key CursorTheme 2>/dev/null)
    end
    if test -n "$cursor"
        check_theme_pkg "/usr/share/icons/$cursor/cursor.theme" $pkg_list
        check_theme_pkg "/usr/share/icons/$cursor" $pkg_list
    end

    # Icon theme package
    set icons ($KREAD --file kdeglobals --group Icons --key Theme 2>/dev/null)
    if test -n "$icons"
        check_theme_pkg "/usr/share/icons/$icons/index.theme" $pkg_list
    end

    # Plasma theme package
    set plasma ($KREAD --file plasmarc --group Theme --key name 2>/dev/null)
    if test -n "$plasma"
        check_theme_pkg "/usr/share/plasma/desktoptheme/$plasma/metadata.desktop" $pkg_list
    end

    # Window decoration package
    set deco ($KREAD --file kwinrc --group "org.kde.kdecoration2" --key theme 2>/dev/null)
    if test -n "$deco"
        set deco_name (string split '__' $deco)[-1]
        check_theme_pkg "/usr/share/aurorae/themes/$deco_name/metadata.desktop" $pkg_list
    end

    # Deduplicate and clean
    if test -f $pkg_list
        sort -u -o $pkg_list $pkg_list
        set -l count (wc -l < $pkg_list | string trim)
        if test $count -gt 0
            log "  Theme packages detected: "(string join ', ' (cat $pkg_list))
        else
            rm $pkg_list
            log "  No theme-specific packages found"
        end
    else
        log "  No theme packages to track"
    end
else
    log "  WARN: KDE config reader not available, skipping theme package detection"
end

# compress themes into a single archive
if test -d $CFG/themes
    tar -czf $CFG/themes.tar.gz -C $CFG themes 2>/dev/null
    and rm -rf $CFG/themes
    and log "Compressed custom themes (themes.tar.gz)"
    or log "WARN: failed to compress themes"
end

# sanity check
log "Running sanity check..."
set -l expected_files \
    $PKG/pacman-native.txt \
    $CFG/kde/kdeglobals \
    $CFG/fish/config.fish

set all_ok 0
for f in $expected_files
    if test -f $f
        set all_ok (math $all_ok + 1)
    else
        log "ERROR: $f was not written by backup!"
    end
end

if test $all_ok -eq (count $expected_files)
    log "Sanity check: all $all_ok files verified"
else
    log "ERROR: sanity check failed — $all_ok of "(count $expected_files)" files present"
end

log "=== BACKUP DONE ==="

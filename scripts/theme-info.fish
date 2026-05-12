#!/usr/bin/env fish

set -l GREEN (set_color green)
set -l CYAN (set_color cyan)
set -l YELLOW (set_color yellow)
set -l MAGENTA (set_color magenta)
set -l BOLD (set_color -o)
set -l DIM (set_color -d)
set -l RESET (set_color normal)

# Pick the first available KDE config reader
set -g KDE_READ_TOOL ""
if type -q kreadconfig6
    set KDE_READ_TOOL kreadconfig6
else if type -q kreadconfig5
    set KDE_READ_TOOL kreadconfig5
end

function read_kde
    if test -z "$KDE_READ_TOOL"
        echo ""
        return
    end
    $KDE_READ_TOOL --file $argv[1] --group $argv[2] --key $argv[3] 2>/dev/null
end

function section
    echo ""
    echo "$BOLD$CYAN== $argv ==$RESET"
end

function item
    set -l val $argv[2]
    if test -z "$val"
        set val "$DIM(not set)$RESET"
    end
    printf "  %-22s %s %s\n" "$argv[1]" "➜" "$val"
end

function show_font
    set -l raw (read_kde $argv[1] $argv[2] $argv[3])
    if test -z "$raw"
        item $argv[4] ""
        return
    end
    set -l family (string split ',' $raw)[1]
    set -l size (string split ',' $raw)[2]
    if test -n "$size"
        set val "$family, $size"
    else
        set val "$family"
    end
    item $argv[4] "$val"
end

clear
echo "$BOLD$CYAN========================================$RESET"
echo "$BOLD$CYAN        CURRENT KDE THEME INFO$RESET"
echo "$BOLD$CYAN========================================$RESET"

if test -z "$KDE_READ_TOOL"
    echo ""
    echo "$YELLOW⚠ No KDE config tool found (kreadconfig5/6).$RESET"
    echo "$DIM  Theme info unavailable — install kde-cli-tools.$RESET"
    echo ""
    echo "$BOLD$CYAN========================================$RESET"
    exit 1
end

section "Plasma"
set plasma_style (read_kde plasmarc Theme name)
item "Plasma Style" "$plasma_style"

set plasma_theme (read_kde kdeglobals General ColorScheme)
item "Color Scheme" "$plasma_theme"

section "Window Decorations"
set decoration (read_kde kwinrc "org.kde.kdecoration2" theme)
item "Decoration Theme" "$decoration"

section "Icons & Cursors"
set icon_theme (read_kde kdeglobals Icons Theme)
item "Icon Theme" "$icon_theme"

# KDE Plasma 6 stores cursor in kcminputrc, Plasma 5 used kdeglobals
set cursor_theme (read_kde kcminputrc Mouse cursorTheme)
if test -z "$cursor_theme"
    set cursor_theme (read_kde kdeglobals Icons CursorTheme)
end
if test -z "$cursor_theme"
    set cursor_theme (read_kde kdeglobals "PlasmaCursor" CursorTheme)
end
item "Cursor Theme" "$cursor_theme"

section "Application Style"
set widget_style (read_kde kdeglobals KDE widgetStyle)
item "Widget Style" "$widget_style"

section "Fonts"
show_font kdeglobals "General" font     "General"
show_font kdeglobals "General" fixed    "Fixed Width"
show_font kdeglobals "General" menuFont "Menu"

section "GTK"
set gtk_theme ""
set gtk_icon ""
set gtk_font ""
if test -f ~/.config/gtk-3.0/settings.ini
    set gtk_theme (grep 'gtk-theme-name' ~/.config/gtk-3.0/settings.ini 2>/dev/null | string split '=' -f 2)
    set gtk_icon (grep 'gtk-icon-theme-name' ~/.config/gtk-3.0/settings.ini 2>/dev/null | string split '=' -f 2)
    set gtk_font (grep 'gtk-font-name' ~/.config/gtk-3.0/settings.ini 2>/dev/null | string split '=' -f 2)
end
item "GTK Theme" "$gtk_theme"
item "GTK Icons" "$gtk_icon"
item "GTK Font" "$gtk_font"

section "Splash Screen"
set splash_engine (read_kde ksplashrc KSplash Engine)
set splash_theme (read_kde ksplashrc KSplash Theme)
item "Engine" "$splash_engine"
item "Theme" "$splash_theme"

echo ""
echo "$BOLD$CYAN========================================$RESET"
echo ""

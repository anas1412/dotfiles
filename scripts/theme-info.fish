#!/usr/bin/env fish

set -l GREEN (set_color green)
set -l CYAN (set_color cyan)
set -l YELLOW (set_color yellow)
set -l MAGENTA (set_color magenta)
set -l BOLD (set_color -o)
set -l RESET (set_color normal)

function read_kde
    kreadconfig6 --file $argv[1] --group $argv[2] --key $argv[3] 2>/dev/null
end

function section
    echo ""
    echo "$BOLD$CYAN== $argv ==$RESET"
end

function item
    printf "  %-22s %s %s\n" "$argv[1]" "➜" "$argv[2]"
end

clear
echo "$BOLD$CYAN========================================$RESET"
echo "$BOLD$CYAN        CURRENT KDE THEME INFO$RESET"
echo "$BOLD$CYAN========================================$RESET"

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

set cursor_theme (read_kde kdeglobals Icons CursorTheme)
if test -z "$cursor_theme"
    set cursor_theme (read_kde kdeglobals "PlasmaCursor" CursorTheme)
end
item "Cursor Theme" "$cursor_theme"

section "Application Style"
set widget_style (read_kde kdeglobals KDE widgetStyle)
item "Widget Style" "$widget_style"

section "Fonts"
set general_font (read_kde kdeglobals General font | string split ',' -f 1,2 | string join '@')
item "General" "$general_font"

set fixed_font (read_kde kdeglobals General fixed | string split ',' -f 1,2 | string join '@')
item "Fixed Width" "$fixed_font"

set menu_font (read_kde kdeglobals General menuFont | string split ',' -f 1,2 | string join '@')
item "Menu" "$menu_font"

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

#!/usr/bin/env fish

set -l OUT "$HOME/dotfiles/config/kde/style.env"
mkdir -p (dirname $OUT)

function kde_read
    set -l args "--group" "$argv[1]" "--key" "$argv[2]"
    if test (count $argv) -ge 3
        set args "--file" "$argv[3]" $args
    end
    if type -q kreadconfig6
        kreadconfig6 $args 2>/dev/null
    else if type -q kreadconfig5
        kreadconfig5 $args 2>/dev/null
    else
        echo ""
    end
end

set icon (kde_read Icons Theme)
# KDE Plasma 6 moved cursor theme to kcminputrc (was kdeglobals in Plasma 5)
set cursor (kde_read Icons CursorTheme)
if test -z "$cursor"
    set cursor (kde_read Mouse cursorTheme kcminputrc)
end
set color (kde_read General ColorScheme)
set font (kde_read General font)

echo "ICON_THEME=$icon" > $OUT
echo "CURSOR_THEME=$cursor" >> $OUT
echo "COLOR_SCHEME=$color" >> $OUT
echo "FONT=$font" >> $OUT

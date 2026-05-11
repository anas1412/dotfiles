#!/usr/bin/env fish

set -l OUT "$HOME/dotfiles/config/kde/style.env"
mkdir -p (dirname $OUT)

function kde_read
    if type -q kreadconfig5
        kreadconfig5 --group $argv[1] --key $argv[2]
    else if type -q kreadconfig6
        kreadconfig6 --group $argv[1] --key $argv[2]
    else
        echo ""
    end
end

set icon (kde_read Icons Theme)
set cursor (kde_read Icons CursorTheme)
set color (kde_read General ColorScheme)
set font (kde_read General font)

echo "ICON_THEME=$icon" > $OUT
echo "CURSOR_THEME=$cursor" >> $OUT
echo "COLOR_SCHEME=$color" >> $OUT
echo "FONT=$font" >> $OUT

function mt5 --wraps='WINEPREFIX=~/.wine_mt5 wine "$HOME/.wine_mt5/drive_c/Program Files/MetaTrader 5/terminal64.exe"' --description 'alias mt5=WINEPREFIX=~/.wine_mt5 wine "$HOME/.wine_mt5/drive_c/Program Files/MetaTrader 5/terminal64.exe"'
    WINEPREFIX=~/.wine_mt5 wine "$HOME/.wine_mt5/drive_c/Program Files/MetaTrader 5/terminal64.exe" $argv
end

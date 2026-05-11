#!/usr/bin/env fish

function banner
    clear
    set_color -o cyan
    echo "                       _ _  _   _ ____"
    echo "  __ _ _ __   __ _ ___/ | || | / |___ \\"
    echo " / _\` | '_ \\ / _\` / __| | || |_| | __) |"
    echo "| (_| | | | | (_| \\__ \\ |__   _| |/ __/"
    echo " \\__,_|_| |_|\\__,_|___/_|  |_| |_|_____|"
    set_color -o white
    echo "          DOTFILES MANAGER"
    set_color normal
end

function run_backup
    fish scripts/backup.fish
end

function run_restore
    fish scripts/audit.fish
    if test $status -ne 0
        echo "Audit failed. Restore aborted."
        return 1
    end
    fish scripts/restore.fish
end

function run_audit
    fish scripts/audit.fish
end

function run_bluetooth_mic_fix
    fish scripts/bluetooth-mic-fix.fish
end

function run_maintenance
    fish scripts/maintenance.fish
end

function run_install_oac
    fish scripts/install-oac.fish
end

while true
    banner
    echo ""
    set choice (gum choose --header "" --cursor "▸ " --height 9 \
        "1) Backup dotfiles" \
        "2) Install or Restore dotfiles" \
        "3) Audit" \
        "4) Bluetooth Mic Fix" \
        "5) System Maintenance" \
        "6) Install OpenAgentsControl for opencode" \
        "0) Exit")

    switch "$choice"
        case "1) Backup dotfiles"
            run_backup
        case "2) Install or Restore dotfiles"
            run_restore
        case "3) Audit"
            run_audit
        case "4) Bluetooth Mic Fix"
            run_bluetooth_mic_fix
        case "5) System Maintenance"
            run_maintenance
        case "6) Install OpenAgentsControl for opencode"
            run_install_oac
        case "0) Exit"
            exit 0
    end

    echo ""
    while read -t 0 -l _ 2>/dev/null; end
    read -P "Press Enter to continue..."
end

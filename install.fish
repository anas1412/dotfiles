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
    echo ""
end

function menu
    banner
    echo ""
    echo "  1) Backup"
    echo "  2) Restore"
    echo "  3) Audit"
    echo "  4) Bluetooth Mic Fix"
    echo "  5) System Maintenance"
    echo "  6) Install OpenAgentsControl for opencode"
    echo "  0) Exit"
    echo ""
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
    menu
    read -P "Select option: " opt

    switch $opt
        case 1
            run_backup
            read -P "Done. Press Enter..."

        case 2
            run_restore
            read -P "Done. Press Enter..."

        case 3
            run_audit
            read -P "Done. Press Enter..."

        case 4
            run_bluetooth_mic_fix
            read -P "Done. Press Enter..."

        case 5
            run_maintenance
            read -P "Done. Press Enter..."

        case 6
            run_install_oac
            read -P "Done. Press Enter..."

        case 0
            exit 0

        case '*'
            echo "Invalid option"
            sleep 1
    end
end

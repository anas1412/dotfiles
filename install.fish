#!/usr/bin/env fish

function banner
    clear
    echo "DOTFILES MANAGER - ANAS1412"
    echo "=================================="
end

function menu
    banner
    echo "1) Backup"
    echo "2) Restore"
    echo "3) Audit"
    echo "4) Bluetooth Mic Fix"
    echo "5) Exit"
    echo "=================================="
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
            exit 0

        case '*'
            echo "Invalid option"
            sleep 1
    end
end

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

function await_enter
    echo ""
    while read -t 0 -l _ 2>/dev/null; end
    read -P "Press Enter to continue..."
end

# ── System submenu ──────────────────────────

function system_menu
    while true
        banner
        echo ""
        set choice (gum choose --header "" --cursor "▸ " --height 5 \
            "1) Backup dotfiles" \
            "2) Install or Restore dotfiles" \
            "3) Audit" \
            "0) Back to main menu")

        switch "$choice"
            case "1) Backup dotfiles"
                fish scripts/backup.fish
                await_enter
            case "2) Install or Restore dotfiles"
                fish scripts/audit.fish
                if test $status -ne 0
                    echo "Audit failed. Restore aborted."
                    await_enter
                    continue
                end
                fish scripts/restore.fish
                await_enter
            case "3) Audit"
                fish scripts/audit.fish
                await_enter
            case "0) Back to main menu"
                return
        end
    end
end

# ── Maintenance submenu ─────────────────────

function maintenance_menu
    while true
        banner
        echo ""
        set choice (gum choose --header "" --cursor "▸ " --height 9 \
            "1) Full maintenance" \
            "2) Update only" \
            "3) Clean cache only" \
            "4) Remove orphans only" \
            "5) Clean journal only" \
            "6) Manage snapshots only" \
            "7) Flatpak only" \
            "0) Back to main menu")

        switch "$choice"
            case "1) Full maintenance"
                fish scripts/maintenance.fish --all
                await_enter
            case "2) Update only"
                fish scripts/maintenance.fish --update
                await_enter
            case "3) Clean cache only"
                fish scripts/maintenance.fish --clean-cache
                await_enter
            case "4) Remove orphans only"
                fish scripts/maintenance.fish --orphans
                await_enter
            case "5) Clean journal only"
                fish scripts/maintenance.fish --journal
                await_enter
            case "6) Manage snapshots only"
                fish scripts/maintenance.fish --snapshots
                await_enter
            case "7) Flatpak only"
                fish scripts/maintenance.fish --flatpak
                await_enter
            case "0) Back to main menu"
                return
        end
    end
end

# ── Extras submenu ──────────────────────────

function extras_menu
    while true
        banner
        echo ""
        set choice (gum choose --header "" --cursor "▸ " --height 4 \
            "1) Install Opencode + OAC" \
            "2) Bluetooth Mic Fix" \
            "0) Back to main menu")

        switch "$choice"
            case "1) Install Opencode + OAC"
                fish scripts/install-opencode.fish
                await_enter
            case "2) Bluetooth Mic Fix"
                fish scripts/bluetooth-mic-fix.fish
                await_enter
            case "0) Back to main menu"
                return
        end
    end
end

# ── Main menu loop ──────────────────────────

while true
    banner
    echo ""
    set choice (gum choose --header "" --cursor "▸ " --height 8 \
        "1) System" \
        "2) Maintenance" \
        "3) Extras" \
        "4) Theme Info" \
        "5) System Info" \
        "0) Exit")

    switch "$choice"
        case "1) System"
            system_menu
        case "2) Maintenance"
            maintenance_menu
        case "3) Extras"
            extras_menu
        case "4) Theme Info"
            fish scripts/theme-info.fish
            await_enter
        case "5) System Info"
            fastfetch
            await_enter
        case "0) Exit"
            exit 0
    end
end

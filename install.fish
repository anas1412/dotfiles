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

function ensure_cron
    # Verify crontab is available, install cronie if missing (Arch only)
    if not type -q crontab
        echo "crontab not found – installing cronie..."
        # Install cronie via pacman (requires sudo)
        sudo pacman -Sy --needed cronie
        and echo "Enabling and starting cronie.service"
        and sudo systemctl enable --now cronie.service
        or begin
            echo "Failed to install cronie. Please install it manually and re‑run the installer."
            exit 1
        end
    end
    # Ensure the daemon is running
    if not systemctl is-active --quiet cronie.service
        sudo systemctl start cronie.service
    end
    echo "Cron is ready."
end

# ── Restore submenu ──────────────────────────

function restore_menu
    while true
        banner
        echo ""
        set choice (gum choose --header "" --cursor "▸ " --height 5 \
            "1) Full restore (packages + configs + themes)" \
            "2) Configs only (fish, KDE, terminals)" \
            "3) Themes only (archive + style)" \
            "0) Back to system menu")

        switch "$choice"
            case "1) Full restore (packages + configs + themes)"
                fish scripts/audit.fish
                if test $status -ne 0
                    echo "Audit failed. Restore aborted."
                    await_enter
                    continue
                end
                fish scripts/restore.fish --all
                await_enter
            case "2) Configs only (fish, KDE, terminals)"
                fish scripts/restore.fish --configs
                await_enter
            case "3) Themes only (archive + style)"
                fish scripts/restore.fish --themes
                await_enter
            case "0) Back to system menu"
                return
        end
    end
end

# ── System submenu ──────────────────────────

function system_menu
    while true
        banner
        echo ""
        set choice (gum choose --header "" --cursor "▸ " --height 6 \
            "1) Restore (full / configs / themes)" \
            "2) Backup dotfiles" \
            "3) Push backup to github" \
            "4) Audit" \
            "0) Back to main menu")

        switch "$choice"
            case "1) Restore (full / configs / themes)"
                restore_menu
            case "2) Backup dotfiles"
                fish scripts/backup.fish
                await_enter
            case "3) Push backup to github"
                git -C $HOME/dotfiles add -A
                and git -C $HOME/dotfiles diff --cached --quiet
                and echo "Nothing to push, up to date."
                    or git -C $HOME/dotfiles commit -m "manual backup $(date +%F)"
                    and git -C $HOME/dotfiles push
                await_enter
            case "4) Audit"
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

function install_cron_jobs
    # Verify and install cronie if missing
    ensure_cron

    # Fixed schedule: run daily at midnight
    set cron_time "0 0 * * *"

    # Backup command – run the dotfiles backup script with fish
    set exec_cmd "fish $HOME/dotfiles/scripts/backup.fish"

    # Backup current crontab (if any)
    set backup "$HOME/.dotfiles_cron_backup"
    crontab -l > $backup 2>/dev/null

    # Build the final cron line with logging
    set cron_line "$cron_time $exec_cmd >> $HOME/dotfiles-cron.log 2>&1"

    # Safely merge: get existing crontab, remove any older dotfiles backup job to avoid duplicates, and append the new one
    set -l existing_cron (crontab -l 2>/dev/null | grep -v "backup.fish")
    
    begin
        for line in $existing_cron
            echo $line
        end
        echo $cron_line
    end | crontab -

    echo "Installed cron job for dotfiles backup."
end

# ── Extras submenu ──────────────────────────

function extras_menu
    while true
        banner
        echo ""
        set choice (gum choose --header "" --cursor "▸ " --height 5 \
            "1) Install Opencode + OAC" \
            "2) Bluetooth Mic Fix" \
            "3) Install Auto Backup Timer" \
            "0) Back to main menu")

        switch "$choice"
            case "1) Install Opencode + OAC"
                fish scripts/install-opencode.fish
                await_enter
            case "2) Bluetooth Mic Fix"
                fish scripts/bluetooth-mic-fix.fish
                await_enter
            case "3) Install Auto Backup Timer"
                echo ""
                echo "Installing cron backup job..."
                install_cron_jobs
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

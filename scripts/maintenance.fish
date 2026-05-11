#!/usr/bin/env fish

set -l ROOT "$HOME/dotfiles"
set -l LOG "$ROOT/maintenance.log"
set -l GREEN (set_color green)
set -l YELLOW (set_color yellow)
set -l RED (set_color red)
set -l CYAN (set_color cyan)
set -l BOLD (set_color -o)
set -l RESET (set_color normal)

set -g updated 0
set -g cleaned 0
set -g orphans 0
set -g journal_cleaned 0
set -g snapshots_cleaned 0
set -g flatpak_updated 0

function log
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $argv" | tee -a $LOG
end

function section
    echo ""
    echo "$CYAN========================================$RESET"
    echo "$CYAN  $argv$RESET"
    echo "$CYAN========================================$RESET"
end

function prompt_confirm
    read -P "$YELLOW$argv [y/N]: $RESET" reply
    string match -qi 'y' "$reply"; and return 0; or return 1
end

function update_system
    section "System Update"

    log "Updating official repositories (pacman)..."
    sudo pacman -Syu
    if test $status -eq 0
        set updated 1
        log "Pacman update completed"
    else
        log "ERROR: Pacman update failed"
        return 1
    end

    if type -q paru
        log "Updating AUR packages (paru)..."
        paru -Syu --aur
        if test $status -eq 0
            log "AUR update completed"
        else
            log "WARN: AUR update had issues"
        end
    else
        log "WARN: paru not found, skipping AUR update"
    end
end

function clean_package_cache
    section "Package Cache Cleanup"

    if not type -q paccache
        log "WARN: paccache not found, skipping"
        return
    end

    log "Cleaning uninstalled package cache..."
    sudo paccache -ruk0; and set cleaned (math $cleaned + 1)

    log "Keeping last 2 versions of installed packages..."
    sudo paccache -rk2; and set cleaned (math $cleaned + 1)

    log "Removing unused sync databases..."
    sudo pacman -Sc --noconfirm 2>/dev/null
end

function remove_orphans
    section "Orphaned Packages"

    set -l orphan_list (pacman -Qtdq 2>/dev/null)
    if test -z "$orphan_list"
        echo "  No orphaned packages found."
        log "No orphans to remove"
        return
    end

    echo "  Orphaned packages found:"
    for pkg in $orphan_list
        echo "    - $pkg"
    end
    set orphans (count $orphan_list)

    if prompt_confirm "Remove $orphans orphaned package(s)?"
        sudo pacman -Rns --noconfirm $orphan_list
        log "Removed $orphans orphaned package(s)"
    else
        log "Orphan removal skipped"
    end
end

function clean_journal
    section "Journal Log Cleanup"

    if not type -q journalctl
        log "WARN: journalctl not found, skipping"
        return
    end

    set -l current_size (journalctl --disk-usage 2>/dev/null | string match -r '[\d.]+[KMGT]' | tail -1)
    echo "  Current journal size: $current_size"

    read -P "Keep logs up to how many days? [7]: " keep_days
    if test -z "$keep_days"
        set keep_days 7
    end

    sudo journalctl --vacuum-time="${keep_days}d"
    if test $status -eq 0
        set journal_cleaned 1
        log "Journal cleaned (kept $keep_days days)"
    else
        log "WARN: Journal cleanup failed"
    end
end

function manage_snapshots
    section "Snapper Snapshots"

    if not type -q snapper
        log "WARN: snapper not found, skipping"
        return
    end

    echo "  Available snapper configs:"
    snapper list-configs 2>/dev/null | string match -rv '^$'
    echo ""

    if not prompt_confirm "Clean up old snapshots?"
        log "Snapshot cleanup skipped"
        return
    end

    read -P "Keep how many recent snapshots per config? [5]: " keep_count
    if test -z "$keep_count"
        set keep_count 5
    end

    for cfg in (snapper list-configs 2>/dev/null | string match -r '^\S+' | string match -rv 'Config')
        if test -n "$cfg"
            log "Cleaning snapshots for config '$cfg'..."
            snapper -c "$cfg" delete (snapper -c "$cfg" list --columns number 2>/dev/null | tail -n +3 | head -n -$keep_count | string trim)
            set snapshots_cleaned (math $snapshots_cleaned + 1)
        end
    end
end

function flatpak_maintenance
    section "Flatpak Maintenance"

    if not type -q flatpak
        log "WARN: flatpak not found, skipping"
        return
    end

    log "Updating Flatpak applications..."
    flatpak update -y
    set flatpak_updated 1

    log "Removing unused Flatpak runtimes..."
    flatpak uninstall --unused -y
end

function show_summary
    section "Maintenance Summary"

    if test $updated -eq 1
        echo "  $GREEN✔$RESET System updated"
    else
        echo "  $YELLOW✗$RESET System update skipped/failed"
    end

    if test $cleaned -gt 0
        echo "  $GREEN✔$RESET Package cache cleaned"
    else
        echo "  $YELLOW✗$RESET Cache cleanup skipped/failed"
    end

    if test $orphans -gt 0
        echo "  $GREEN✔$RESET Removed $orphans orphan(s)"
    else if test $orphans -eq 0
        echo "  $GREEN✔$RESET No orphans to remove"
    end

    if test $journal_cleaned -eq 1
        echo "  $GREEN✔$RESET Journal cleaned"
    else
        echo "  $YELLOW✗$RESET Journal cleanup skipped/failed"
    end

    if test $snapshots_cleaned -gt 0
        echo "  $GREEN✔$RESET $snapshots_cleaned snapshot config(s) cleaned"
    else
        echo "  $YELLOW✗$RESET Snapshot cleanup skipped/failed"
    end

    if test $flatpak_updated -eq 1
        echo "  $GREEN✔$RESET Flatpak maintained"
    else
        echo "  $YELLOW✗$RESET Flatpak maintenance skipped"
    end

    echo ""
    log "Maintenance complete"
end

function interactive_menu
    clear
    echo "$BOLD$CYAN========================================$RESET"
    echo "$BOLD$CYAN  SYSTEM MAINTENANCE$RESET"
    echo "$BOLD$CYAN========================================$RESET"
    echo "  1) Full maintenance (all modules)"
    echo "  2) System update only"
    echo "  3) Clean package cache only"
    echo "  4) Remove orphaned packages only"
    echo "  5) Clean journal logs only"
    echo "  6) Manage snapper snapshots only"
    echo "  7) Flatpak maintenance only"
    echo "  8) Exit"
    echo "$CYAN========================================$RESET"
    read -P "Select option: " opt

    switch $opt
        case 1
            update_system
            clean_package_cache
            remove_orphans
            clean_journal
            manage_snapshots
            flatpak_maintenance
            show_summary
        case 2
            update_system
            show_summary
        case 3
            clean_package_cache
        case 4
            remove_orphans
        case 5
            clean_journal
        case 6
            manage_snapshots
        case 7
            flatpak_maintenance
        case 8
            exit 0
        case '*'
            echo "$RED Invalid option$RESET"
    end
end

log "=== MAINTENANCE START ==="

if count $argv > /dev/null
    for arg in $argv
        switch $arg
            case --all
                update_system
                clean_package_cache
                remove_orphans
                clean_journal
                manage_snapshots
                flatpak_maintenance
            case --update
                update_system
            case --clean-cache
                clean_package_cache
            case --orphans
                remove_orphans
            case --journal
                clean_journal
            case --snapshots
                manage_snapshots
            case --flatpak
                flatpak_maintenance
            case --help -h
                echo "Usage: fish scripts/maintenance.fish [options]"
                echo ""
                echo "Options:"
                echo "  --all           Run all maintenance modules"
                echo "  --update        System and AUR update"
                echo "  --clean-cache   Package cache cleanup"
                echo "  --orphans       Remove orphaned packages"
                echo "  --journal       Clean journal logs"
                echo "  --snapshots     Manage snapper snapshots"
                echo "  --flatpak       Flatpak maintenance"
                echo "  --help, -h      Show this help"
                echo ""
                echo "Without options, runs in interactive mode."
                exit 0
            case '*'
                echo "$RED Unknown option: $arg$RESET"
                echo "Use --help to see available options."
                exit 1
        end
    end
    show_summary
else
    interactive_menu
end

log "=== MAINTENANCE END ==="

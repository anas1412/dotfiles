#!/usr/bin/env fish

set -l ROOT "$HOME/dotfiles"

echo "=================================="
echo "        DOTFILES AUDIT"
echo "=================================="

set -l warn 0

function check_cmd
    set -l name $argv[1]
    set -l cmd $argv[2]

    eval $cmd >/dev/null 2>&1

    if test $status -eq 0
        echo "[OK]   $name"
    else
        echo "[WARN] $name"
        set warn (math $warn + 1)
    end
end

function check_file
    set -l file $argv[1]

    if test -f $file
        echo "[OK]   $file"
    else
        echo "[WARN] $file missing"
        set warn (math $warn + 1)
    end
end

function check_dir
    set -l dir $argv[1]

    if test -d $dir
        echo "[OK]   $dir"
    else
        echo "[WARN] $dir missing"
        set warn (math $warn + 1)
    end
end

echo ""
echo "== System =="

check_cmd "pacman" "type pacman"
check_cmd "fish" "type fish"
check_cmd "git" "type git"

check_cmd "kde config tool" "type kwriteconfig5; or type kreadconfig5; or type kreadconfig6"

echo ""
echo "== Dotfiles structure =="

check_dir "$ROOT"
check_dir "$ROOT/scripts"
check_dir "$ROOT/config"
check_dir "$ROOT/packages"
check_dir "$ROOT/config/opencode"

echo ""
echo "== Required files =="

check_file "$ROOT/packages/pacman.txt"
check_file "$ROOT/scripts/backup.fish"
check_file "$ROOT/scripts/restore.fish"
check_file "$ROOT/scripts/kde_style.fish"
check_file "$ROOT/config/kde/style.env"
check_file "$ROOT/config/opencode/opencode.json"
check_file "$ROOT/config/opencode/.gitignore"

echo ""
echo "== KDE runtime config =="

check_file "$HOME/.config/kdeglobals"
check_file "$HOME/.config/kwinrc"
check_file "$HOME/.config/plasmarc"

echo ""
echo "=================================="
echo "WARNINGS: $warn"
echo "=================================="

if test $warn -gt 0
    echo "RESULT: NOT SAFE TO RESTORE"
    exit 1
else
    echo "RESULT: SAFE TO RESTORE"
    exit 0
end

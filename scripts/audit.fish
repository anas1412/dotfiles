#!/usr/bin/env fish

set -g ROOT "$HOME/dotfiles"
set -g LOG "$ROOT/audit.log"
set -g CFG "$ROOT/config"
set -g PKG "$ROOT/packages"

set -l GREEN (set_color green)
set -l YELLOW (set_color yellow)
set -l RED (set_color red)
set -l CYAN (set_color cyan)
set -l BOLD (set_color -o)
set -l DIM (set_color -d)
set -l RESET (set_color normal)

# ── Globals ─────────────────────────────────────────

set -g total_passed 0
set -g total_warnings 0
set -g total_errors 0

# ── Helpers ─────────────────────────────────────────

function log
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $argv" | tee -a $LOG
end

function section
    set -l name $argv[1]
    echo ""
    echo "$BOLD$CYAN══ $name ═══════════════════════════════════════════════════════$RESET"
end

function result_line
    set -l label $argv[1]
    set -l result_status $argv[2]
    set -l detail $argv[3]

    set -l padded (string pad -w 50 -c " " -- $label)

    switch $result_status
        case PASS
            echo "  $padded  $GREEN✓ PASS$RESET"
            set -g total_passed (math $total_passed + 1)
        case WARN
            echo "  $padded  $YELLOW⚠ WARN$RESET  $detail"
            set -g total_warnings (math $total_warnings + 1)
        case ERROR
            echo "  $padded  $RED✗ ERROR$RESET  $detail"
            set -g total_errors (math $total_errors + 1)
        case SKIP
            echo "  $padded  $DIM– SKIP$RESET  $detail"
        case INFO
            echo "  $padded  $CYANℹ INFO$RESET  $detail"
    end
end

function check_cmd
    type -q $argv[1]
end

# ── Domain 1: Package List Integrity ─────────────

function domain_packages
    section "PACKAGE LISTS"

    set -l pkg_native "$PKG/pacman-native.txt"
    set -l pkg_foreign "$PKG/pacman-foreign.txt"
    set -l pkg_flatpak "$PKG/flatpak.txt"

    # -- File existence and non-empty --
    if test -f $pkg_native
        set -l count (wc -l < $pkg_native | string trim)
        if test $count -gt 0
            result_line "native packages ($count entries)" PASS
        else
            result_line "native packages" WARN "file is empty"
        end
    else
        result_line "native packages" ERROR "pacman-native.txt missing"
    end

    if test -f $pkg_foreign
        set -l count (wc -l < $pkg_foreign | string trim)
        if test $count -gt 0
            result_line "AUR packages ($count entries)" PASS
        else
            result_line "AUR packages" WARN "file is empty"
        end
    else
        result_line "AUR packages" WARN "pacman-foreign.txt missing"
    end

    if test -f $pkg_flatpak
        set -l count (wc -l < $pkg_flatpak | string trim)
        if test $count -gt 0
            result_line "Flatpak packages ($count entries)" PASS
        else
            result_line "Flatpak packages" INFO "flatpak.txt is empty (no Flatpaks tracked)"
        end
    else
        result_line "Flatpak packages" INFO "flatpak.txt missing (no Flatpaks tracked)"
    end

    # -- Duplicate check: native --
    if test -f $pkg_native
        set -l dups (sort $pkg_native | uniq -d)
        if test -z "$dups"
            result_line "native duplicates" PASS
        else
            result_line "native duplicates" ERROR "found: $(string join ', ' $dups)"
        end
    end

    # -- Duplicate check: AUR --
    if test -f $pkg_foreign
        set -l dups (sort $pkg_foreign | uniq -d)
        if test -z "$dups"
            result_line "AUR duplicates" PASS
        else
            result_line "AUR duplicates" ERROR "found: $(string join ', ' $dups)"
        end
    end

    # -- Cross-file overlap --
    if test -f $pkg_native && test -f $pkg_foreign
        set -l native_pkgs (sort $pkg_native | psub)
        set -l foreign_pkgs (sort $pkg_foreign | psub)
        set -l overlap (comm -12 $native_pkgs $foreign_pkgs 2>/dev/null)
        if test -z "$overlap"
            result_line "native/AUR overlap" PASS
        else
            result_line "native/AUR overlap" ERROR "in both lists: $(string join ', ' $overlap)"
        end
    end

    # -- Validate native packages in repos --
    if not check_cmd pacman
        result_line "package repo validation" SKIP "pacman not available"
    else if test -f $pkg_native
        # Build set of all available packages
        set -l all_pkgs (pacman -Sl 2>/dev/null | string replace -r '^\S+\s+(\S+).*' '$1')
        if test $status -ne 0
            result_line "package repo validation" SKIP "could not query pacman repos"
        else
            set -l missing ""
            for pkg in (cat $pkg_native)
                if not contains -- $pkg $all_pkgs
                    set missing "$missing $pkg"
                end
            end
            if test -z "$missing"
                result_line "native packages in pacman repos" PASS
            else
                result_line "native packages in pacman repos" WARN "not found:$missing"
            end
        end
    end

    # -- Validate AUR packages --
    if test -f $pkg_foreign
        if check_cmd paru
            set -l missing_aur ""
            for pkg in (cat $pkg_foreign)
                paru -Si $pkg >/dev/null 2>&1
                if test $status -ne 0
                    set missing_aur "$missing_aur $pkg"
                end
            end
            if test -z "$missing_aur"
                result_line "AUR packages available" PASS
            else
                result_line "AUR packages available" WARN "not found on AUR:$missing_aur"
            end
        else
            result_line "AUR packages" INFO "paru not available, skipping AUR validation"
        end
    end

    # -- Count discrepancy --
    if check_cmd pacman
        set -l sys_count (pacman -Qqen 2>/dev/null | wc -l | string trim)
        set -l bak_count (wc -l < $pkg_native | string trim)
        if test -z "$sys_count" || test -z "$bak_count"
            result_line "package count" SKIP "could not determine counts"
        else if test "$sys_count" -eq "$bak_count"
            result_line "package count: system=$sys_count vs backup=$bak_count" PASS
        else
            set -l diff (math "$sys_count - $bak_count" 2>/dev/null)
            result_line "package count: system=$sys_count vs backup=$bak_count" WARN "off by $diff (run backup.fish?)"
        end
    end
end

# ── Domain 2: Config Syntax Validation ────────────

function domain_configs
    section "CONFIG VALIDATION"

    # -- Fish config --
    if test -f $CFG/fish/config.fish
        fish --no-execute $CFG/fish/config.fish 2>/dev/null
        if test $status -eq 0
            result_line "fish/config.fish" PASS
        else
            result_line "fish/config.fish" ERROR "syntax error"
        end
    else
        result_line "fish/config.fish" WARN "missing"
    end

    # -- Fish functions --
    if test -d $CFG/fish/functions
        for fn in $CFG/fish/functions/*.fish
            set -l name (basename $fn)
            fish --no-execute $fn 2>/dev/null
            if test $status -eq 0
                result_line "fish/functions/$name" PASS
            else
                result_line "fish/functions/$name" ERROR "syntax error"
            end
        end
    else
        result_line "fish/functions" INFO "no function files"
    end

    # -- Alacritty TOML --
    if test -f $CFG/alacritty/alacritty.toml
        python3 -c "
import sys
try:
    import tomllib
    tomllib.load(open('$CFG/alacritty/alacritty.toml', 'rb'))
    sys.exit(0)
except ImportError:
    try:
        import tomli
        tomli.load(open('$CFG/alacritty/alacritty.toml', 'rb'))
        sys.exit(0)
    except ImportError:
        sys.exit(42)
except Exception as e:
    print(e, file=sys.stderr)
    sys.exit(1)
" 2>/dev/null
        set -l rc $status
        switch $rc
            case 0
                result_line "alacritty/alacritty.toml" PASS
            case 42
                result_line "alacritty/alacritty.toml" SKIP "no TOML parser (python3 tomllib/tomli)"
            case '*'
                result_line "alacritty/alacritty.toml" ERROR "invalid TOML"
        end
    else if test -d $CFG/alacritty
        result_line "alacritty config" INFO "no toml file in config/alacritty/"
    end

    # -- kitty config --
    if test -d $CFG/kitty/kitty
        set -l kf (find $CFG/kitty -name "*.conf" 2>/dev/null)
        if test -n "$kf"
            result_line "kitty configs present" PASS
        else
            result_line "kitty configs" INFO "directory empty, no .conf files"
        end
    else if test -d $CFG/kitty
        result_line "kitty configs" INFO "backed up directory is empty"
    else
        result_line "kitty configs" INFO "not backed up"
    end

    # -- ghostty config --
    if test -d $CFG/ghostty/ghostty
        set -l gf (find $CFG/ghostty -type f 2>/dev/null)
        if test -n "$gf"
            result_line "ghostty configs present" PASS
        else
            result_line "ghostty configs" INFO "directory empty"
        end
    else if test -d $CFG/ghostty
        result_line "ghostty configs" INFO "backed up directory is empty"
    else
        result_line "ghostty configs" INFO "not backed up"
    end

    # -- KDE INI files --
    set -l kde_files (find $CFG/kde -maxdepth 1 -type f 2>/dev/null | string match -rv '/style\.env$')
    if test -n "$kde_files"
        set -l kde_ok 0
        set -l kde_bad 0
        for f in $kde_files
            set -l name (basename $f)
            set -l has_errors 0
            for line in (cat $f)
                set -l trimmed (string trim $line)
                if test -z "$trimmed"
                    continue
                end
                # Allow comment lines
                if string match -q '#*' $trimmed
                    continue
                end
                # Check: [Section] or key=value or key[keyprops]=value
                if not string match -qr '^\[.*\]$' $trimmed
                    if not string match -qr '^[^=]+=(.*)$' $trimmed
                        set has_errors 1
                        break
                    end
                end
            end
            if test $has_errors -eq 0
                set kde_ok (math $kde_ok + 1)
            else
                set kde_bad (math $kde_bad + 1)
                result_line "kde/$name" ERROR "malformed line(s)"
            end
        end
        if test $kde_bad -eq 0
            result_line "KDE configs ($kde_ok files)" PASS
        end
    else
        result_line "KDE configs" INFO "no KDE files backed up"
    end

    # -- style.env --
    if test -f $CFG/kde/style.env
        set -l style_ok 1
        set -l empty_vars ""
        for line in (cat $CFG/kde/style.env)
            if not string match -qr '^[A-Z_]+=(.*)$' $line
                result_line "kde/style.env" ERROR "malformed line: $line"
                set style_ok 0
                break
            end
            # Check for empty values
            set -l parts (string split "=" $line)
            set -l key $parts[1]
            set -l val (string join "=" $parts[2..-1])
            if test -z "$val"
                set empty_vars "$empty_vars $key"
            end
        end
        if test $style_ok -eq 1
            if test -z "$empty_vars"
                result_line "kde/style.env" PASS
            else
                result_line "kde/style.env" WARN "empty value(s):$empty_vars"
            end
        end
    else
        result_line "kde/style.env" WARN "missing (run backup.fish to generate)"
    end

    # -- Fastfetch JSONC --
    if test -f $CFG/fastfetch/config.jsonc
        python3 -c '
import json, sys, re
with open(sys.argv[1]) as f:
    text = f.read()
text = re.sub(r"^\s*//.*$", "", text, flags=re.MULTILINE)
text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
try:
    json.loads(text)
    sys.exit(0)
except json.JSONDecodeError as e:
    print(e, file=sys.stderr)
    sys.exit(1)
' $CFG/fastfetch/config.jsonc 2>/dev/null
        if test $status -eq 0
            result_line "fastfetch/config.jsonc" PASS
        else
            result_line "fastfetch/config.jsonc" ERROR "invalid JSON"
        end
    else
        result_line "fastfetch/config.jsonc" WARN "missing"
    end
end

# ── Domain 3: Backup Coverage ─────────────────────

function domain_coverage
    section "BACKUP COVERAGE"

    # backup.fish targets: dirs and KDE files
    set -l backed_dirs kde fish alacritty kitty ghostty
    set -l backed_kde_files kdeglobals kwinrc plasmarc kglobalshortcutsrc dolphinrc konsolerc mimeapps.list

    # Check backup dirs exist
    set -l found_dirs 0
    set -l missing_dirs ""
    for d in $backed_dirs
        if test -d $CFG/$d
            set found_dirs (math $found_dirs + 1)
        else
            set missing_dirs "$missing_dirs $d"
        end
    end
    if test -z "$missing_dirs"
        result_line "backup target dirs ($found_dirs dirs)" PASS
    else
        result_line "backup target dirs" WARN "not backed up:$missing_dirs"
    end

    # Check KDE files
    set -l kde_found 0
    set -l kde_missing ""
    for f in $backed_kde_files
        if test -f $CFG/kde/$f
            set kde_found (math $kde_found + 1)
        else
            set kde_missing "$kde_missing $f"
        end
    end
    if test -z "$kde_missing"
        result_line "KDE files ($kde_found/7)" PASS
    else
        result_line "KDE files ($kde_found/7)" INFO "not in backup:$kde_missing (may not exist on system)"
    end

    # Scan for un-backed-up configs on system
    set -l known_configs btop fastfetch git gtk-3.0 gtk-4.0 kvantum micro mpv nvim pipewire qt5ct qt6ct spotify vim wireplumber
    set -l found_unbacked ""
    for cfg in $known_configs
        if test -d ~/.config/$cfg
            switch $cfg
                case fish kde alacritty kitty ghostty
                    continue
                case '*'
                    set found_unbacked "$found_unbacked $cfg"
            end
        end
    end
    if test -z "$found_unbacked"
        result_line "un-backed-up system configs" PASS
    else
        result_line "un-backed-up system configs" INFO "on system, not in backup.fish:$found_unbacked"
    end

    # Special cases
    if test -d $CFG/fastfetch
        result_line "fastfetch config" INFO "in repo (manual), not via backup.fish"
    end

    if test -d $CFG/git
        set -l git_count (count $CFG/git/* 2>/dev/null)
        if test $git_count -gt 0
            result_line "git config" INFO "in repo ($git_count items), not via backup.fish"
        else
            result_line "git config" INFO "empty directory"
        end
    end
end

# ── Domain 4: Dependency Consistency ──────────────

function domain_deps
    section "DEPENDENCY CONSISTENCY"

    set -l pkg_native "$PKG/pacman-native.txt"
    set -l pkg_foreign "$PKG/pacman-foreign.txt"

    # Build combined package list
    set -l all_pkgs
    if test -f $pkg_native
        for p in (cat $pkg_native)
            set all_pkgs $all_pkgs $p
        end
    end
    if test -f $pkg_foreign
        for p in (cat $pkg_foreign)
            set all_pkgs $all_pkgs $p
        end
    end

    # Scan config.fish for referenced commands
    set -l refs
    if test -f $CFG/fish/config.fish
        for line in (cat $CFG/fish/config.fish)
            # alias name="command ..." — extract the command
            if string match -qr '^alias\s+.*="' $line
                set -l parts (string split '=' $line)
                if test (count $parts) -ge 2
                    set -l rhs (string trim -c '"' -- $parts[2..-1])
                    set -l first_word (string split ' ' $rhs)[1]
                    if test -n "$first_word"
                        set refs $refs $first_word
                    end
                end
            end
            # opencode run...
            if string match -qr 'opencode' $line
                set refs $refs opencode
            end
            # bun path ref
            if string match -qr 'bun' $line
                set refs $refs bun
            end
        end
        # Deduplicate
        if test -n "$refs"
            set refs (string join \n $refs | sort -u)
        end
    end

    if test -z "$refs"
        result_line "config.fish command references" INFO "no external commands found to cross-ref"
    else
        set -l missing_deps ""
        for cmd in $refs
            if not contains -- $cmd $all_pkgs
                set missing_deps "$missing_deps $cmd"
            end
        end
        if test -z "$missing_deps"
            result_line "config.fish → package lists" PASS
        else
            result_line "config.fish → package lists" WARN "commands not in any package list:$missing_deps"
        end
    end

    # Alacritty font deps
    if test -f $CFG/alacritty/alacritty.toml
        set -l font_families (grep -i 'family' $CFG/alacritty/alacritty.toml 2>/dev/null | string replace -r '.*family\s*=\s*"([^"]+)".*' '$1' | sort -u)
        if test -n "$font_families"
            # Check if font packages exist in list
            set -l font_pkgs
            for pkg in $all_pkgs
                if string match -qr 'font|nerd|ttf|noto' $pkg
                    set font_pkgs $font_pkgs $pkg
                end
            end
            set -l unmatched ""
            for font in $font_families
                set -l found 0
                for pkg in $font_pkgs
                    if string match -qi -- "*"(string replace -r ' .*' '' $font)"*" $pkg
                        set found 1
                        break
                    end
                end
                if test $found -eq 0
                    set unmatched "$unmatched '$font'"
                end
            end
            if test -z "$unmatched"
                result_line "alacritty font deps" PASS
            else
                result_line "alacritty font deps" INFO "fonts:$unmatched (may be system-installed)"
            end
        end
    end

    # style.env: check KDE color scheme file exists
    if test -f $CFG/kde/style.env
        for line in (cat $CFG/kde/style.env)
            if string match -q 'COLOR_SCHEME=*' $line
                set -l scheme (string split '=' $line)[2]
                if test -n "$scheme"
                    if test -f /usr/share/color-schemes/$scheme.colors
                        result_line "KDE color scheme '$scheme'" PASS
                    else if test -f ~/.local/share/color-schemes/$scheme.colors
                        result_line "KDE color scheme '$scheme'" PASS
                    else
                        result_line "KDE color scheme '$scheme'" WARN ".colors file not found"
                    end
                end
            end
        end
    end

    # KDE restore tools check
    # Check KDE config tools needed by restore:
    #   Plasma 6: kwriteconfig6 + kreadconfig6 → kconfig  | kbuildsycoca6 → kservice
    #   Plasma 5: kwriteconfig5 + kreadconfig5 → kde-cli-tools  | kbuildsycoca5 → kded
    set -l tool_map \
        kwriteconfig6  kconfig \
        kreadconfig6   kconfig \
        kbuildsycoca6  kservice \
        kwriteconfig5  kde-cli-tools \
        kreadconfig5   kde-cli-tools \
        kbuildsycoca5  kded

    set -l missing_tools ""
    set -l missing_pkgs ""
    for i in (seq 1 2 (count $tool_map))
        set -l tool $tool_map[$i]
        set -l parent_pkg $tool_map[(math $i + 1)]

        if check_cmd $tool
            continue  # already installed
        end

        if not contains -- $parent_pkg $all_pkgs
            set missing_tools "$missing_tools $tool"
            set missing_pkgs "$missing_pkgs $parent_pkg"
        end
    end

    if test -z "$missing_tools"
        result_line "KDE restore tools (kwriteconfig/kreadconfig/kbuildsycoca)" PASS
    else
        result_line "KDE restore tools" WARN "add to package lists:$missing_pkgs (provides:$missing_tools)"
    end
end

# ── Domain 5: Drift Detection ─────────────────────

function domain_drift
    section "DRIFT DETECTION (STALENESS)"

    # Backup path → system path pairs
    set -l bak_files \
        $CFG/kde/kdeglobals $CFG/kde/kwinrc $CFG/kde/plasmarc \
        $CFG/kde/kglobalshortcutsrc $CFG/kde/dolphinrc $CFG/kde/konsolerc \
        $CFG/kde/mimeapps.list $CFG/fish/config.fish

    set -l sys_files \
        ~/.config/kdeglobals ~/.config/kwinrc ~/.config/plasmarc \
        ~/.config/kglobalshortcutsrc ~/.config/dolphinrc ~/.config/konsolerc \
        ~/.config/mimeapps.list ~/.config/fish/config.fish

    set -l total 0
    set -l stale 0
    set -l fresh 0
    set -l stale_detail ""

    for i in (seq 1 (count $bak_files))
        set -l bak $bak_files[$i]
        set -l sys $sys_files[$i]
        set -l label (string replace "$CFG/" "" $bak)

        if not test -f $bak
            continue
        end
        if not test -f $sys
            continue
        end
        set total (math $total + 1)

        set -l bak_time (stat -c %Y $bak 2>/dev/null)
        set -l sys_time (stat -c %Y $sys 2>/dev/null)
        if test -z "$bak_time" || test -z "$sys_time"
            continue
        end

        if test $sys_time -gt $bak_time
            set stale (math $stale + 1)
            set -l diff_sec (math "$sys_time - $bak_time")
            set -l diff_days (math "$diff_sec / 86400")
            set stale_detail "$stale_detail
    $label — $diff_days day(s) stale (system is newer)"
        else
            set fresh (math $fresh + 1)
        end
    end

    if test $total -eq 0
        result_line "drift detection" INFO "no candidate files to compare"
    else
        result_line "$fresh tracked files up to date" PASS
        if test $stale -gt 0
            result_line "$stale file(s) stale" WARN "run backup.fish$stale_detail"
        end
    end
end

# ── Domain 6: Secrets Leak Scan ───────────────────

function domain_secrets
    section "SECURITY SCAN"

    set -l patterns \
        'PRIVATE KEY' \
        'AKIA[0-9A-Z]\{16\}' \
        'ghp_[a-zA-Z0-9]\{36\}' \
        'gho_[a-zA-Z0-9]\{36\}' \
        'github_pat_[a-zA-Z0-9]\{22,\}' \
        'sk-[a-zA-Z0-9]\{20,\}' \
        'xf-[a-zA-Z0-9]\{20,\}'

    set -l scan_dirs $CFG/fish $CFG/kde $CFG/alacritty $CFG/kitty $CFG/ghostty $CFG/fastfetch

    set -l total_scanned 0
    set -l total_hits 0

    for dir in $scan_dirs
        if not test -d $dir
            continue
        end
        for f in (find $dir -type f 2>/dev/null)
            set total_scanned (math $total_scanned + 1)
            for pat in $patterns
                if string match -rq $pat < $f
                    set total_hits (math $total_hits + 1)
                    set -l relpath (string replace "$ROOT/" "" $f)
                    result_line "$relpath" WARN "potential secret: '$pat'"
                    break
                end
            end
        end
    end

    if test $total_hits -eq 0
        result_line "secrets scan ($total_scanned files)" PASS
    end
end

# ── Domain 7: Script Health ───────────────────────

function domain_scripts
    section "SCRIPT HEALTH"

    # Syntax-check all fish scripts
    set -l ok 0
    set -l bad 0
    set -l total_scripts 0

    for script in $ROOT/scripts/*.fish
        set total_scripts (math $total_scripts + 1)
        set -l name (basename $script)
        fish --no-execute $script 2>/dev/null
        if test $status -eq 0
            set ok (math $ok + 1)
            result_line "scripts/$name" PASS
        else
            set bad (math $bad + 1)
            result_line "scripts/$name" ERROR "syntax error"
        end
    end

    if test $total_scripts -eq 0
        result_line "no scripts found" WARN "scripts/ directory empty"
    else if test $bad -eq 0
        result_line "all $total_scripts scripts valid" PASS
    end

    # backup ↔ restore sync check
    if test -f $ROOT/scripts/backup.fish && test -f $ROOT/scripts/restore.fish
        set -l checks alacritty kitty ghostty kde fish
        for item in $checks
            grep -q "$item" $ROOT/scripts/backup.fish 2>/dev/null
            set -l in_backup $status
            grep -q "$item" $ROOT/scripts/restore.fish 2>/dev/null
            set -l in_restore $status
            if test $in_backup -eq 0 && test $in_restore -eq 0
                result_line "$item: backup ↔ restore" PASS
            else
                result_line "$item: backup ↔ restore" ERROR "mismatch"
            end
        end
    end

    # systemd service
    if test -f $ROOT/systemd/dotfiles-backup.service
        result_line "systemd service present" PASS
    else
        result_line "systemd/dotfiles-backup.service" INFO "not found"
    end

    # install.fish audit integration
    if test -f $ROOT/install.fish
        if string match -q '*audit*' (cat $ROOT/install.fish)
            result_line "install.fish → audit integration" PASS
        else
            result_line "install.fish → audit integration" WARN "no audit call in install.fish"
        end
    end
end

# ── Summary ───────────────────────────────────────

function show_report
    echo ""
    echo "$BOLD$CYAN═══════════════════════════════════════════════════════════════$RESET"
    echo "$BOLD$CYAN                    AUDIT REPORT SUMMARY$RESET"
    echo "$BOLD$CYAN═══════════════════════════════════════════════════════════════$RESET"
    echo ""
    printf "  %-28s %s\n" "Total checks run:"   (math $total_passed + $total_warnings + $total_errors)
    printf "  %-28s %s\n" "Passed:"             "$GREEN$total_passed$RESET"
    printf "  %-28s %s\n" "Warnings:"           "$YELLOW$total_warnings$RESET"
    printf "  %-28s %s\n" "Errors:"             "$RED$total_errors$RESET"
    echo ""

    if test $total_errors -gt 0
        echo "  $RED✗ NOT SAFE TO RESTORE$RESET  — $total_errors error(s) must be fixed"
        echo ""
        echo "  $YELLOW  Fix the errors above, then run audit again.$RESET"
        return 1
    else if test $total_warnings -gt 0
        echo "  $YELLOW⚠  SAFE TO RESTORE (with warnings)$RESET"
        echo "  $DIM  Review warnings above — no blocking issues.$RESET"
        return 0
    else
        echo "  $GREEN✓ SAFE TO RESTORE$RESET  — all checks passed"
        return 0
    end
end

# ── Help ──────────────────────────────────────────

function show_help
    echo "Usage: fish scripts/audit.fish [options]"
    echo ""
    echo "Options:"
    echo "  --all        Run all audit domains (default)"
    echo "  --packages   Package list integrity"
    echo "  --configs    Config syntax validation"
    echo "  --coverage   Backup coverage analysis"
    echo "  --deps       Dependency consistency"
    echo "  --drift      Staleness / drift detection"
    echo "  --secrets    Secrets leak scan"
    echo "  --scripts    Script health check"
    echo "  --help, -h   Show this help"
    echo ""
    echo "Without options, runs full audit (all domains)."
    echo "Exit code: 0 = safe to restore, 1 = blocking issues"
end

# ── Main ──────────────────────────────────────────

echo "" > $LOG
log "=== AUDIT START ==="

# Default: run all
set -l run_all 1
set -l run_packages 0
set -l run_configs 0
set -l run_coverage 0
set -l run_deps 0
set -l run_drift 0
set -l run_secrets 0
set -l run_scripts 0

if set -q argv[1]
    set run_all 0
    for arg in $argv
        switch $arg
            case --all
                set run_all 1
            case --packages
                set run_packages 1
            case --configs
                set run_configs 1
            case --coverage
                set run_coverage 1
            case --deps
                set run_deps 1
            case --drift
                set run_drift 1
            case --secrets
                set run_secrets 1
            case --scripts
                set run_scripts 1
            case --help -h
                show_help
                exit 0
            case '*'
                echo "$RED Unknown option: $arg$RESET"
                echo "Use --help to see available options."
                exit 1
        end
    end
end

if test $run_all -eq 1
    set run_packages 1
    set run_configs 1
    set run_coverage 1
    set run_deps 1
    set run_drift 1
    set run_secrets 1
    set run_scripts 1
end

echo ""
echo "$BOLD$CYAN╔═══════════════════════════════════════════════════════════════╗$RESET"
echo "$BOLD$CYAN║                    DOTFILES AUDIT REPORT                      ║$RESET"
echo "$BOLD$CYAN╚═══════════════════════════════════════════════════════════════╝$RESET"

if test $run_packages -eq 1
    domain_packages
end
if test $run_configs -eq 1
    domain_configs
end
if test $run_coverage -eq 1
    domain_coverage
end
if test $run_deps -eq 1
    domain_deps
end
if test $run_drift -eq 1
    domain_drift
end
if test $run_secrets -eq 1
    domain_secrets
end
if test $run_scripts -eq 1
    domain_scripts
end

log "=== AUDIT END ==="

show_report
exit $status

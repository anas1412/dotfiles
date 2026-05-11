#!/usr/bin/env fish

set -l GREEN (set_color green)
set -l CYAN (set_color cyan)
set -l YELLOW (set_color yellow)
set -l RED (set_color red)
set -l BOLD (set_color -o)
set -l RESET (set_color normal)

function step
    echo ""
    echo "$BOLD$CYAN== $argv ==$RESET"
end

function ok
    echo "  $GREEN✔$RESET $argv"
end

function warn
    echo "  $YELLOW⚠$RESET $argv"
end

function fail
    echo "  $RED✗$RESET $argv"
end

clear
echo "$BOLD$CYAN========================================$RESET"
echo "$BOLD$CYAN  Opencode + OAC Installer$RESET"
echo "$BOLD$CYAN========================================$RESET"

# ── Step 1: Install opencode CLI ───────────────────────

step "Installing Opencode CLI"

if type -q opencode
    ok "opencode already installed at "(which opencode)
else
    # Try paru first
    if type -q paru
        warn "paru installing opencode..."
        if paru -S --noconfirm opencode 2>&1
            ok "Installed opencode via paru"
        else
            warn "paru install failed, trying official install script..."
            # Fallback: official OpenCode install script
            if curl -fsSL https://opencode.ai/install | bash
                ok "Installed opencode via official script"
            else
                fail "Failed to install opencode CLI"
                echo ""
                echo "  Try manually:"
                echo "    curl -fsSL https://opencode.ai/install | bash"
                exit 1
            end
        end
    else
        warn "paru not found, using official install script..."
        if curl -fsSL https://opencode.ai/install | bash
            ok "Installed opencode via official script"
        else
            fail "Failed to install opencode CLI"
            exit 1
        end
    end

    # Verify installation
    if not type -q opencode
        fail "opencode not found after install"
        exit 1
    end
end

# ── Step 2: Install OpenAgentsControl ─────────────────

step "Installing OpenAgentsControl (OAC)"

# Check if OAC is already installed
set -l oac_marker "$HOME/.opencode/agent/core/openagent.md"
if test -f "$oac_marker"
    echo ""
    ok "OpenAgentsControl already installed at $CYAN~/.opencode/$RESET"
    echo ""
    echo "  $BOLD$CYANopencode --agent OpenAgent$RESET"
    echo ""
    exit 0
end

echo ""
echo "  This installs OAC globally at: $CYAN~/.opencode/$RESET"
echo "  Includes agents, subagents, commands, skills, context files"
echo ""

read -P "Proceed with OAC installation? [y/N]: " confirm
if not string match -qi 'y' "$confirm"
    echo ""
    warn "OAC installation skipped"
    echo ""
    ok "opencode CLI is ready — run: opencode"
    exit 0
end

set -l oac_url "https://raw.githubusercontent.com/darrenhinde/OpenAgentsControl/main/install.sh"
set -l oac_dest "/tmp/install-oac.sh"

echo ""
if curl -fsSL "$oac_url" -o "$oac_dest"
    bash "$oac_dest" developer --install-dir ~/.config/opencode
    set -l oac_status $status
    rm -f "$oac_dest"

    if test $oac_status -eq 0
        echo ""
        ok "OpenAgentsControl installed globally"
        echo ""
        echo "  You can now use: $CYANopencode --agent OpenAgent$RESET"
    else
        warn "OAC installation had issues"
        echo "  Try manually: curl -fsSL $oac_url | bash -s developer"
        exit 1
    end
else
    fail "Failed to download OAC installer"
    exit 1
end

#!/usr/bin/env fish

set -l GREEN (set_color green)
set -l CYAN (set_color cyan)
set -l YELLOW (set_color yellow)
set -l BOLD (set_color -o)
set -l RESET (set_color normal)

echo "$BOLD$CYAN========================================$RESET"
echo "$BOLD$CYAN  OpenAgentsControl Installer$RESET"
echo "$BOLD$CYAN========================================$RESET"
echo ""

echo "This will install OpenAgentsControl globally into ~/.config/opencode/"
echo ""
echo "Includes:"
echo "  - Agents: OpenAgent, OpenCoder, SystemBuilder"
echo "  - Subagents: ContextScout, TaskManager, CoderAgent, etc."
echo "  - Commands: /add-context, /commit, /test, /context"
echo "  - Skills: code-review, task-delegation, etc."
echo "  - Context files: standards, workflows, guides"
echo ""

read -P "Proceed with installation? [y/N]: " confirm
if not string match -qi 'y' "$confirm"
    echo "Cancelled."
    exit 0
end

echo ""
echo "$YELLOW Downloading and installing...$RESET"
curl -fsSL https://raw.githubusercontent.com/darrenhinde/OpenAgentsControl/main/install.sh | bash -s developer --install-dir ~/.config/opencode

if test $status -eq 0
    echo ""
    echo "$GREEN OpenAgentsControl installed globally!$RESET"
    echo ""
    echo "You can now use: opencode --agent OpenAgent"
else
    echo ""
    echo "$YELLOW Installation had issues. Check the output above.$RESET"
end

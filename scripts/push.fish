#!/usr/bin/env fish

set -l ROOT "$HOME/dotfiles"
set -l LOG "$ROOT/backup.log"

function log
    echo "["(date '+%Y-%m-%d %H:%M:%S')"] $argv" | tee -a $LOG
end

log "=== GIT PUSH START ==="
git -C $ROOT add -A
if not git -C $ROOT diff --cached --quiet
    if git -C $ROOT commit -m "automated backup (date +%F)"
        if git -C $ROOT push
            log "Successfully pushed backup to GitHub."
        else
            log "ERROR: Failed to push to GitHub."
        end
    else
        log "ERROR: Failed to commit changes."
    end
else
    log "No changes to push, repository is up to date."
end
log "=== GIT PUSH DONE ==="

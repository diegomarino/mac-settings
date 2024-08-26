#!/bin/bash


#  Set logging
LOG_FILE="/tmp/mac-settings-git-backup.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Source variables from mac-settings.sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/mac-settings.sh"

log "Starting git backup -- $HOSTNAME"

# Change to the base backup directory
cd "$BASE_OUTPUT_DIR" || { log "Error: Couldn't change to $BASE_OUTPUT_DIR"; exit 1; }

# Fetch the latest changes from the remote
git fetch origin || { log "Error: git FETCH failed"; exit 1; }

# Check if there are local changes
if ! git diff --quiet HEAD; then
    # There are local changes, commit them
    git add . || { log "Error: git ADD failed"; exit 1; }
    git commit -m "Automatic backup from $HOSTNAME: $(date '+%Y-%m-%d %H:%M:%S')" || {
        if [ $? -eq 1 ]; then
            log "No changes to commit"
        else
            log "Error: git COMMIT failed"; exit 1
        fi
    }
fi

# Check if we have any outgoing commits
OUTGOING=$(git log origin/main..HEAD)
if [ -n "$OUTGOING" ]; then
    log "Outgoing commits detected. Attempting to push..."
    
    # Try to rebase first
    if git rebase origin/main; then
        log "Rebase successful. Pushing changes..."
        if git push origin main; then
            log "Changes pushed successfully"
        else
            log "Error: Failed to push after rebase. Manual intervention may be required."
            exit 1
        fi
    else
        log "Rebase failed. Attempting merge..."
        git rebase --abort
        if git merge origin/main; then
            log "Merge successful. Pushing changes..."
            if git push origin main; then
                log "Changes pushed successfully"
            else
                log "Error: Failed to push after merge. Manual intervention may be required."
                exit 1
            fi
        else
            log "Error: Both rebase and merge failed. Manual intervention required."
            exit 1
        fi
    fi
else
    log "No outgoing commits. Local branch is up to date."
fi

log "Git backup completed successfully"
log "-------------------------------------------------"
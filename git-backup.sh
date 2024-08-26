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

# Now try to pull
git pull --rebase origin main || {
    if [ $? -eq 1 ]; then
        log "No changes to pull from remote"
    else
        log "Error: git PULL failed"; exit 1
    fi
}

# Finally, push changes
git push origin main || {
    if [ $? -eq 1 ]; then
        log "No changes to push to remote"
    else
        log "Error: git PUSH failed"; exit 1
    fi
}

log "Git backup completed successfully"
log "-------------------------------------------------"
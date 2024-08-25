#!/bin/bash

# Source variables from mac-settings.sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/mac-settings.sh"

# Now we can use the BASE_OUTPUT_DIR variable
cd "$BASE_OUTPUT_DIR" || exit 1

git add .
git commit -m "Automatic backup: $(date '+%Y-%m-%d %H:%M:%S')"
git push origin main  # Adjust the branch name if necessary
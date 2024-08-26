#!/bin/bash

# Set up PATH for cron execution
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$PATH"

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set the base output directory to be at the same level as the script directory
BASE_OUTPUT_DIR="$(dirname "$SCRIPT_DIR")/mac-settings-backups"

# Set logging
LOG_FILE="/tmp/mac-settings-backup.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Get the hostname using different methods
HOSTNAME=$(hostname -s 2>/dev/null || scutil --get LocalHostName 2>/dev/null || echo "unknown-host")
log "Hostname detectado: $HOSTNAME"

# User Configuration
# ------------------

# Homebrew binary name (change to "brew" if using Intel Mac)
BREW_BIN="brew"

# Set the output directory as a global variable
OUTPUT_DIR="${BASE_OUTPUT_DIR}/${HOSTNAME}"

# Function to create and set the output directory
set_output_directory() {
    # Ensure the output directory exists
    mkdir -p "$OUTPUT_DIR"
    log "Output directory created: $OUTPUT_DIR"
}

# List of applications to backup (add or remove as needed)
APPS_TO_BACKUP=(
    "Alfred"
    "Boop"
    "Hazel"
    "iTerm2"
    "Oh My Zsh"
    "PrusaSlicer"
)

# Function to get current timestamp
get_timestamp() {
    date +"%Y-%m-%d_%H-%M-%S"
}

# Function to gather system information
gather_system_info() {
    # OS Information
    os_info=$(sw_vers)

    # Installed applications
    installed_apps=$(ls /Applications)

    # Homebrew packages
    if command -v $BREW_BIN &>/dev/null; then
        brew_packages=$(brew list)
    else
        brew_packages="Homebrew not installed"
    fi

    # Mac App Store apps
    if command -v mas &>/dev/null; then
        mas_apps=$(mas list)
    else
        mas_apps="mas not installed"
    fi

    # Gather system defaults
    gather_system_defaults

    # Gather editor extensions
    gather_editor_extensions

    # Gather Alfred settings
    gather_alfred_settings

    # Gather Boop settings
    gather_boop_settings

    # Gather Hazel settings
    gather_hazel_settings

    # Gather iTerm2 settings
    gather_iterm_settings

    # Gather Oh My Zsh settings
    gather_ohmyzsh_settings

    # Gather PrusaSlicer settings
    gather_prusaslicer_settings

    # Gather LaunchAgents
    gather_launch_agents

    # Generate the replication script
    generate_replication_script
}

# Function to gather system defaults
gather_system_defaults() {
    defaults=(
        "NSGlobalDomain AppleInterfaceStyle"
        "NSGlobalDomain AppleLanguages"
        "NSGlobalDomain AppleLocale"
        "NSGlobalDomain AppleMeasurementUnits"
        "NSGlobalDomain AppleMetricUnits"
        "NSGlobalDomain AppleShowScrollBars"
        "NSGlobalDomain NSAutomaticCapitalizationEnabled"
        "NSGlobalDomain NSAutomaticDashSubstitutionEnabled"
        "NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled"
        "NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled"
        "NSGlobalDomain NSAutomaticSpellingCorrectionEnabled"
        "com.apple.dock autohide"
        "com.apple.dock magnification"
        "com.apple.dock tilesize"
        "com.apple.dock largesize"
        "com.apple.dock orientation"
        "com.apple.finder ShowExternalHardDrivesOnDesktop"
        "com.apple.finder ShowHardDrivesOnDesktop"
        "com.apple.finder ShowMountedServersOnDesktop"
        "com.apple.finder ShowRemovableMediaOnDesktop"
        "com.apple.finder AppleShowAllFiles"
        "com.apple.finder ShowStatusBar"
        "com.apple.finder ShowPathbar"
        "com.apple.desktopservices DSDontWriteNetworkStores"
        "com.apple.screencapture location"
        "com.apple.screencapture type"
        "com.apple.screensaver askForPassword"
        "com.apple.screensaver askForPasswordDelay"
        "com.apple.sound.beep.volume"
        "com.apple.systempreferences AttentionPrefBundleIDs"
        "com.apple.trackpad Clicking"
        "com.apple.trackpad TrackpadThreeFingerDrag"
        "com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag"
        "com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag"
        "com.apple.menuextra.clock DateFormat"
        "com.apple.menuextra.battery ShowPercent"
        "com.apple.LaunchServices LSQuarantine"
        "com.apple.commerce AutoUpdate"
        "com.apple.commerce AutoUpdateRestartRequired"
        "com.apple.SoftwareUpdate AutomaticCheckEnabled"
        "com.apple.SoftwareUpdate AutomaticDownload"
        "com.apple.SoftwareUpdate CriticalUpdateInstall"
        "com.apple.TimeMachine DoNotOfferNewDisksForBackup"
    )

    system_defaults=""
    for default in "${defaults[@]}"; do
        domain=$(echo $default | cut -d' ' -f1)
        key=$(echo $default | cut -d' ' -f2-)
        value=$(defaults read "$domain" "$key" 2>/dev/null)
        if [ $? -eq 0 ]; then
            system_defaults+="defaults write $domain $key $value\n"
        fi
    done
}

# Function to gather editor extensions
gather_editor_extensions() {
    # Cursor extensions
    if [ -d "$HOME/.cursor/extensions" ]; then
        cursor_extensions=$(ls -1 "$HOME/.cursor/extensions")
    else
        cursor_extensions="Cursor not installed or no extensions found"
    fi

    # VSCode extensions
    if command -v code &>/dev/null; then
        vscode_extensions=$(code --list-extensions)
    else
        vscode_extensions="VSCode not installed or not in PATH"
    fi

    # VSCodium extensions
    if command -v codium &>/dev/null; then
        vscodium_extensions=$(codium --list-extensions)
    else
        vscodium_extensions="VSCodium not installed or not in PATH"
    fi
}

# Function to gather Alfred settings
gather_alfred_settings() {
    alfred_dir="$HOME/Library/Application Support/Alfred"
    if [ -d "$alfred_dir" ]; then
        alfred_version=$(ls -1 "$alfred_dir" | grep -E "Alfred.+preferences" | sort -V | tail -n 1)
        alfred_prefs_dir="$alfred_dir/$alfred_version"
        if [ -d "$alfred_prefs_dir" ]; then
            alfred_settings=$(find "$alfred_prefs_dir" -type f)
            alfred_workflows=$(find "$alfred_prefs_dir/workflows" -maxdepth 1 -type d -not -name "workflows")
        else
            alfred_settings="Alfred preferences directory not found"
            alfred_workflows="Alfred workflows not found"
        fi
    else
        alfred_settings="Alfred not installed or preferences not found"
        alfred_workflows="Alfred not installed or workflows not found"
    fi
}

# Function to gather Boop settings
gather_boop_settings() {
    boop_dir="$HOME/Library/Application Support/Boop"
    if [ -d "$boop_dir" ]; then
        boop_settings=$(find "$boop_dir" -type f)
    else
        boop_settings="Boop not installed or settings not found"
    fi
}

# Function to gather Hazel settings
gather_hazel_settings() {
    hazel_dir="$HOME/Library/Application Support/Hazel"
    if [ -d "$hazel_dir" ]; then
        hazel_settings=$(find "$hazel_dir" -type f)
    else
        hazel_settings="Hazel not installed or settings not found"
    fi
}

# Function to gather iTerm2 settings
gather_iterm_settings() {
    iterm_plist="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
    if [ -f "$iterm_plist" ]; then
        iterm_settings="$iterm_plist"
    else
        iterm_settings="iTerm2 preferences not found"
    fi
}

# Function to gather Oh My Zsh settings
gather_ohmyzsh_settings() {
    ohmyzsh_dir="$HOME/.oh-my-zsh"
    if [ -d "$ohmyzsh_dir" ]; then
        ohmyzsh_settings=$(find "$ohmyzsh_dir" -type f)
        zshrc="$HOME/.zshrc"
        if [ -f "$zshrc" ]; then
            ohmyzsh_settings="$ohmyzsh_settings"$'\n'"$zshrc"
        fi
    else
        ohmyzsh_settings="Oh My Zsh not installed or settings not found"
    fi
}

# Function to gather PrusaSlicer settings
gather_prusaslicer_settings() {
    prusaslicer_dir="$HOME/Library/Application Support/PrusaSlicer"
    if [ -d "$prusaslicer_dir" ]; then
        prusaslicer_settings=$(find "$prusaslicer_dir" -type f)
    else
        prusaslicer_settings="PrusaSlicer not installed or settings not found"
    fi
}

# Function to gather LaunchAgents
gather_launch_agents() {
    launch_agents_dir="$HOME/Library/LaunchAgents"
    if [ -d "$launch_agents_dir" ]; then
        launch_agents=$(find "$launch_agents_dir" -type f -name "*.plist")
    else
        launch_agents="No user LaunchAgents found"
    fi
}

# Function to generate the replication script
generate_replication_script() {
    set_output_directory
    output_file="$OUTPUT_DIR/${HOSTNAME}-mac-settings.sh"

    log "Generando script de replicación en: $output_file"

    echo "#!/bin/bash" >"$output_file"
    echo "" >>"$output_file"
    echo "# macOS System Replication Script for $hostname" >>"$output_file"

    # Add commands to replicate the system state
    echo "# OS Information:" >>"$output_file"
    echo "$os_info" >>"$output_file"
    echo "" >>"$output_file"

    echo "# Install Homebrew" >>"$output_file"
    echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' >>"$output_file"
    echo "" >>"$output_file"

    echo "# Install Homebrew packages" >>"$output_file"
    echo "$brew_packages" | while read package; do
        echo "brew install $package" >>"$output_file"
    done
    echo "" >>"$output_file"

    echo "# Install Mac App Store apps" >>"$output_file"
    echo "$mas_apps" | while read app; do
        app_id=$(echo $app | awk '{print $1}')
        echo "mas install $app_id" >>"$output_file"
    done
    echo "" >>"$output_file"

    echo "# Install editor extensions" >>"$output_file"
    echo "" >>"$output_file"

    echo "# Cursor extensions" >>"$output_file"
    if [ "$cursor_extensions" != "Cursor not installed or no extensions found" ]; then
        echo "$cursor_extensions" | while read ext; do
            echo "# TODO: Install Cursor extension: $ext" >>"$output_file"
        done
    else
        echo "# $cursor_extensions" >>"$output_file"
    fi
    echo "" >>"$output_file"

    echo "# VSCode extensions" >>"$output_file"
    if [ "$vscode_extensions" != "VSCode not installed or not in PATH" ]; then
        echo "$vscode_extensions" | while read ext; do
            echo "code --install-extension $ext" >>"$output_file"
        done
    else
        echo "# $vscode_extensions" >>"$output_file"
    fi
    echo "" >>"$output_file"

    echo "# VSCodium extensions" >>"$output_file"
    if [ "$vscodium_extensions" != "VSCodium not installed or not in PATH" ]; then
        echo "$vscodium_extensions" | while read ext; do
            echo "codium --install-extension $ext" >>"$output_file"
        done
    else
        echo "# $vscodium_extensions" >>"$output_file"
    fi
    echo "" >>"$output_file"

    echo "# Copy Alfred settings" >>"$output_file"
    if [ "$alfred_settings" != "Alfred not installed or preferences not found" ]; then
        echo "mkdir -p \"$output_dir/Alfred\"" >>"$output_file"
        echo "$alfred_settings" | while read setting; do
            rel_path=$(realpath --relative-to="$alfred_prefs_dir" "$setting")
            echo "mkdir -p \"$output_dir/Alfred/$(dirname "$rel_path")\"" >>"$output_file"
            echo "cp \"$setting\" \"$output_dir/Alfred/$rel_path\"" >>"$output_file"
        done
    else
        echo "# $alfred_settings" >>"$output_file"
    fi
    echo "" >>"$output_file"

    echo "# Copy Alfred workflows" >>"$output_file"
    if [ "$alfred_workflows" != "Alfred not installed or workflows not found" ]; then
        echo "$alfred_workflows" | while read workflow; do
            workflow_name=$(basename "$workflow")
            echo "cp -R \"$workflow\" \"$output_dir/Alfred/workflows/$workflow_name\"" >>"$output_file"
        done
    else
        echo "# $alfred_workflows" >>"$output_file"
    fi
    echo "" >>"$output_file"

    # Copy settings for each application
    for app in "${APPS_TO_BACKUP[@]}"; do
        case $app in
        "Alfred")
            copy_settings "$app" "$alfred_settings" "$alfred_prefs_dir"
            ;;
        "Boop")
            copy_settings "$app" "$boop_settings" "$boop_dir"
            ;;
        "Hazel")
            copy_settings "$app" "$hazel_settings" "$hazel_dir"
            ;;
        "iTerm2")
            copy_settings "$app" "$iterm_settings" "$(dirname "$iterm_settings")"
            ;;
        "Oh My Zsh")
            copy_settings "$app" "$ohmyzsh_settings" "$HOME"
            ;;
        "PrusaSlicer")
            copy_settings "$app" "$prusaslicer_settings" "$prusaslicer_dir"
            ;;
        "LaunchAgents")
            copy_settings "$app" "$launch_agents" "$launch_agents_dir"
            ;;
        *)
            echo "Unknown application: $app"
            ;;
        esac
    done

    echo "# Set system preferences" >>"$output_file"
    echo -e "$system_defaults" >>"$output_file"
    echo "" >>"$output_file"

    chmod +x "$output_file"
    echo "Replication script generated: $output_file"

    # Generate additional files
    echo "$installed_apps" >"$OUTPUT_DIR/installed_apps.txt"
    echo "$brew_packages" >"$OUTPUT_DIR/brew_packages.txt"
    echo "$mas_apps" >"$OUTPUT_DIR/mas_apps.txt"
    echo "$cursor_extensions" >"$OUTPUT_DIR/cursor_extensions.txt"
    echo "$vscode_extensions" >"$OUTPUT_DIR/vscode_extensions.txt"
    echo "$vscodium_extensions" >"$OUTPUT_DIR/vscodium_extensions.txt"

    log "Additional files generated in $OUTPUT_DIR"

    # Copy Alfred settings and workflows
    if [ "$alfred_settings" != "Alfred not installed or preferences not found" ]; then
        mkdir -p "$output_dir/Alfred"
        echo "$alfred_settings" | while read setting; do
            rel_path=$(realpath --relative-to="$alfred_prefs_dir" "$setting")
            mkdir -p "$output_dir/Alfred/$(dirname "$rel_path")"
            cp "$setting" "$output_dir/Alfred/$rel_path"
        done
    fi

    if [ "$alfred_workflows" != "Alfred not installed or workflows not found" ]; then
        mkdir -p "$output_dir/Alfred/workflows"
        echo "$alfred_workflows" | while read workflow; do
            workflow_name=$(basename "$workflow")
            cp -R "$workflow" "$output_dir/Alfred/workflows/$workflow_name"
        done
    fi

    # Create .gitignore file
    create_gitignore
}

# Function to copy settings
copy_settings() {
    app_name="$1"
    settings="$2"
    source_dir="$3"

    echo "# Copy $app_name settings" >>"$output_file"
    if [ "$settings" != "$app_name not installed or settings not found" ] && [ "$settings" != "No user LaunchAgents found" ]; then
        echo "mkdir -p \"$output_dir/$app_name\"" >>"$output_file"
        echo "$settings" | while read setting; do
            rel_path=$(realpath --relative-to="$source_dir" "$setting")
            echo "mkdir -p \"$output_dir/$app_name/$(dirname "$rel_path")\"" >>"$output_file"
            echo "cp \"$setting\" \"$output_dir/$app_name/$rel_path\"" >>"$output_file"
        done

        # Actually copy the files
        mkdir -p "$output_dir/$app_name"
        echo "$settings" | while read setting; do
            rel_path=$(realpath --relative-to="$source_dir" "$setting")
            mkdir -p "$output_dir/$app_name/$(dirname "$rel_path")"
            cp "$setting" "$output_dir/$app_name/$rel_path"
        done
    else
        echo "# $settings" >>"$output_file"
    fi
    echo "" >>"$output_file"
}

# Function to create .gitignore file
create_gitignore() {
    output_dir=$(set_output_directory)
    gitignore_file="$output_dir/../.gitignore"

    cat <<EOF >"$gitignore_file"
# macOS system files
.DS_Store
.AppleDouble
.LSOverride

# Thumbnails
._*

# Files that might appear in the root of a volume
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns
.com.apple.timemachine.donotpresent

# Directories potentially created on remote AFP share
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk

# Generated folders and files
*/installed_apps.txt
*/brew_packages.txt
*/mas_apps.txt
*/cursor_extensions.txt
*/vscode_extensions.txt
*/vscodium_extensions.txt

# Application specific settings
# Uncomment these if you don't want to track them in git

# */Alfred/
# */Boop/
# */Hazel/
# */iTerm2/
# */Oh My Zsh/
# */PrusaSlicer/
# */LaunchAgents/

# Sensitive information
# Add patterns for files that might contain sensitive data
# */*_history
# */*.log
# */*.key
# */*.pem
EOF

    echo "Created .gitignore file: $gitignore_file"
}

# Main execution
main() {
    log "Iniciando backup de configuraciones de Mac para $HOSTNAME"
    set_output_directory
    gather_system_info
    log "Backup completado para $HOSTNAME"

    # Optional: Commit and push changes to Git repository
    if [[ -x "$SCRIPT_DIR/git-backup.sh" ]]; then
        log "Ejecutando git-backup.sh"
        "$SCRIPT_DIR/git-backup.sh"
    else
        log "Error: git-backup.sh no tiene permisos de ejecución o no existe"
        log "Intenta ejecutar: chmod +x $SCRIPT_DIR/git-backup.sh"
    fi
}

# Only run if the script is executed directly, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi

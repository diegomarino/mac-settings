# macOS System Settings Backup

This project contains a bash script that automatically backs up various system settings and application configurations on macOS. It's designed to run periodically, creating a snapshot of your system configuration that can be used for backup purposes or to replicate your setup on a new machine.

## Features

- Backs up system preferences using `defaults` command
- Captures installed applications from `/Applications`
- Lists Homebrew packages and Mac App Store apps
- Saves extensions for Cursor, VSCode, and VSCodium
- Backs up settings for:
  - Alfred (preferences and workflows)
  - Boop (user scripts and preferences)
  - Hazel (rules and preferences)
  - iTerm2 (preferences)
  - Oh My Zsh (custom themes, plugins, and .zshrc)
  - PrusaSlicer (profiles and configurations)
- Captures user LaunchAgents
- Optional automatic Git backup of settings

## Usage

1. Clone this repository to your local machine.
2. Make the script executable:
   ```
   chmod +x mac-settings.sh
   chmod +x git-backup.sh
   ```
3. Run the script manually:
   ```
   ./mac-settings.sh
   ```

## Automatic Execution with Cron

To run the script automatically every 15 minutes:

1. Open your terminal and edit your crontab:
   ```
   crontab -e
   ```

2. Add the following line to run the script every 15 minutes:
   ```
   */15 * * * * /path/to/your/mac-settings.sh
   ```
   Replace `/path/to/your/` with the actual path to the script on your system.

3. Save and exit the editor.

Note: Ensure that your terminal app has Full Disk Access in System Preferences > Security & Privacy > Privacy to allow cron to access all necessary files.

## Output

The script creates a directory structure parallel to its own directory:

```
parent_directory/
├── mac-settings/
│   ├── README.md
│   ├── .gitignore
│   ├── LICENSE
│   ├── git-backup.sh
│   └── mac-settings.sh
└── mac-settings-backups/
    └── [hostname]/
        ├── [hostname]-mac-settings.sh
        ├── installed_apps.txt
        ├── brew_packages.txt
        ├── mas_apps.txt
        ├── cursor_extensions.txt
        ├── vscode_extensions.txt
        ├── vscodium_extensions.txt
        └── [Application directories]
```

Each run of the script updates the files in the mac-settings-backups/[hostname] directory, where [hostname] is replaced by the actual hostname of the machine running the script.

## Customization

You can modify the `mac-settings.sh` script to add or remove applications and settings according to your needs. At the top of the script, you'll find user-configurable variables:

- `BASE_OUTPUT_DIR`: The directory where backups will be stored.
- `APPS_TO_BACKUP`: An array of application names to backup.
- `BREW_BIN`: The Homebrew binary name (useful for different Mac architectures).

Adjust these variables as needed for your specific setup.

## Automatic Git Backup

The project includes an optional feature to automatically commit and push changes to a Git repository after each run of the main script. This allows you to keep a version-controlled backup of settings from multiple devices in a single repository.

The `git-backup.sh` script uses the same configuration variables as `mac-settings.sh`, ensuring consistency between the scripts.

To set up and use this feature:

1. Initialize a Git repository in the `mac-settings-backups/` directory:
   ```
   cd ../mac-settings-backups
   git init
   git add .
   git commit -m "Initial commit"
   ```

2. Set up a remote repository (e.g., on GitHub) and add it to your local repository:
   ```
   git remote add origin https://github.com/yourusername/mac-settings-backups.git
   git push -u origin main
   ```

3. Configure your Git credentials for the repository.

4. Open `mac-settings.sh` and uncomment the following line at the end of the file:
   ```bash
   # ./git-backup.sh
   ```

5. Now, every time you run `mac-settings.sh`, it will automatically commit and push the changes to your Git repository, including backups from all devices.

To disable the automatic Git backup, simply comment out the line again:
```bash
# # ./git-backup.sh
```

Note: Be cautious about pushing sensitive information to a remote repository. Review the contents of your backups and consider using a private repository or implementing additional security measures if necessary.

## Contributing

Contributions to improve the script or add support for additional applications are welcome. Please feel free to submit a pull request or open an issue for any bugs or feature requests.

## License

This project is open source and available under the [MIT License](LICENSE).
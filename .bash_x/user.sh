#!/bin/bash

# user.sh - User specific configuration script for Linux systems

# Constants
USER_CONFIG_FILE="$HOME/.user_config_done"

# Function to setup git configuration
setup_git() {
    echo "Configuring Git..."
    read -p "Enter your Git username: " gituser
    git config --global user.name "$gituser"
    
    read -p "Enter your Git email: " gitemail
    git config --global user.email "$gitemail"
    
    git config --global init.defaultBranch main
    git config --global color.ui auto
    git config --global core.editor "nano"
    git config --global pull.rebase false
    git config --global push.default simple
    git config --global fetch.prune true
    git config --global rebase.autoStash true
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.cm commit
    git config --global alias.st status
    git config --global log.decorate short
    
    echo "Git configuration complete."
}

# Function to create and configure a GPG key for GitHub
setup_gpg_for_github() {
    if [ -f "$HOME/.bash_x/gpg.sh" ]; then
        source "$HOME/.bash_x/gpg.sh"
        echo "Checking for or creating GPG key..."
        if gpg --list-keys | grep -q "$gitemail"; then
            echo "A GPG key for $gitemail exists, but we'll ensure it's set up for Git."
        else
            create_key "$gituser" "$gitemail"
            if [ $? -ne 0 ]; then
                echo "Failed to create GPG key."
                return 1
            fi
            echo "GPG key created for $gitemail."
        fi
        # Ensure Git uses this key for signing
        local keyid=$(gpg --list-secret-keys --keyid-format LONG | grep sec | cut -d/ -f2 | cut -d' ' -f1)
        git config --global user.signingkey $keyid
        git config --global commit.gpgsign true
        echo "GPG key configured for Git commit signing."
    else
        echo "GPG script not found at $HOME/.bash_x/gpg.sh. Skipping GPG setup."
    fi
}

# Function to check if configuration has been run
is_configured() {
    [ -f "$USER_CONFIG_FILE" ]
}

# Main user setup function
user_setup() {
    if ! is_configured; then
        setup_git
        setup_gpg_for_github
        touch "$USER_CONFIG_FILE"
        echo "User setup complete. For package installation and system-wide settings, please run os.sh with sudo."
    else
        echo "User configuration has already been run. If you want to re-run, remove $USER_CONFIG_FILE."
    fi
}

# Usage help
user_help() {
    echo "Usage: ./user.sh [command]"
    echo "Commands:"
    echo "  setup   - Run the user setup"
    echo "  help    - Show this help"
}

# Command execution
if [ $# -eq 0 ]; then
    user_help
else
    case "$1" in
        setup) user_setup ;;
        help) user_help ;;
        *) echo "Unknown command. Use 'help' for usage information." ;;
    esac
fi
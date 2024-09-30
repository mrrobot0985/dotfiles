#!/bin/bash

# os.sh - Host management script for setting up security best practices and system-wide configurations

# Constants
OS_CONFIG_FILE="/etc/os_config_done"
FIREWALL_SERVICE="ufw"

ensure_root() {
    echo "Debug: ensure_root called with EUID $EUID and arguments: $@"
    if [ "$EUID" -ne 0 ]; then
        echo "Debug: Not root, elevating..."
        if [ -x "$(command -v sudo)" ]; then
            echo "Debug: Elevating with sudo..."
            exec sudo bash "$0" "$@"
            exit $?
        else
            echo "sudo is not available. Please run this script as root."
            exit 1
        fi
    else
        echo "Debug: Already root. Proceeding..."
    fi
}

# Add this at the very beginning of the script
echo "Debug: Script started with args: $@"

# Setup sudo for commands that need root
sudo_if_needed() {
    if [ "$EUID" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

# Function to setup basic security configurations
setup_security() {
    echo "Setting up security configurations..."
    sudo_if_needed apt update && sudo_if_needed apt upgrade -y
    
    echo "Installing fail2ban and ufw..."
    sudo_if_needed apt install -y fail2ban ufw
    
    echo "Configuring UFW..."
    sudo_if_needed ufw default deny incoming
    sudo_if_needed ufw default allow outgoing
    sudo_if_needed ufw allow ssh/tcp
    sudo_if_needed ufw --force enable

    echo "Setting up Fail2ban..."
    sudo_if_needed cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    sudo_if_needed systemctl enable fail2ban
    sudo_if_needed systemctl start fail2ban

    echo "Disabling root login over SSH..."
    sudo_if_needed sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo_if_needed systemctl restart sshd

    echo "Setting up automatic updates..."
    sudo_if_needed apt install -y unattended-upgrades
    sudo_if_needed dpkg-reconfigure --priority=low unattended-upgrades
    
    echo "Security setup complete."
}

# Function to install and update system packages
install_packages() {
    echo "Updating package list and installing common tools..."
    sudo_if_needed apt update
    
    packages=(
        git
        podman
        python3-pip
        curl
        wget
        htop
        vim
        tree
    )
    
    for package in "${packages[@]}"; do
        if ! dpkg -s $package > /dev/null 2>&1; then
            echo "Installing $package..."
            sudo_if_needed apt install -y $package || echo "Failed to install $package."
        else
            echo "$package is already installed."
        fi
    done
}

setup_drivers() {
    echo "Checking for graphics drivers..."

    # Check if a package is installed
    is_package_installed() {
        dpkg -l | grep -q "$1"
    }

    # NVIDIA GPU check
    if lspci | grep -i 'VGA\|3D.*NVIDIA'; then
        echo "NVIDIA GPU detected."
        if ! command -v nvidia-smi &> /dev/null; then
            echo "Installing NVIDIA drivers..."
            sudo_if_needed apt-get update
            sudo_if_needed apt-get install -y nvidia-driver-$(nvidia-detect | grep -oP '(?<=Detected NVIDIA GPUs:).*' | awk '{print $1}')
        fi
    else
        echo "No NVIDIA GPU detected."
    fi

    # AMD and Intel GPU checks remain unchanged from your previous script
    # ... (include your AMD and Intel checks here if necessary)
}

# Main function to call setup
os_setup() {
    ensure_root "$@"
    
    if [ -f "$OS_CONFIG_FILE" ]; then
        echo "System configuration has already been run. If you want to re-run, remove $OS_CONFIG_FILE."
        return
    fi

    setup_security
    install_packages
    setup_drivers
    sudo_if_needed touch $OS_CONFIG_FILE
    echo "System setup complete."
}

# Usage help
os_help() {
    echo "Usage: sudo ./os.sh [command]"
    echo "Commands:"
    echo "  setup   - Run the initial security and package setup"
    echo "  help    - Show this help"
}

# Command execution
if [ $# -eq 0 ]; then
    os_help
else
    ensure_root "$@"
    case "$1" in
        setup) os_setup ;;
        help) os_help ;;
        *) echo "Unknown command. Use 'help' for usage information." ;;
    esac
fi
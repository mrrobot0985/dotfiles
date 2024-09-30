#!/bin/bash

# Define constants
CONFIG_DIR=/etc/wireguard
LOG_FILE=/var/log/wg-vpn.log

# Ensure wg-quick is installed
if ! command -v wg-quick &> /dev/null; then
    echo "wg-quick could not be found. Please install WireGuard tools."
    exit 1
fi

# Logging function
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to list available VPN configurations
list_vpns() {
    echo "Available VPN configurations:"
    for file in "$CONFIG_DIR"/*.conf; do
        echo "${file##*/}" | sed 's/.conf$//'
    done
}

# Function to show usage information
wg_vpn_help() {
    echo "Usage: x wg-vpn [command]"
    echo "Commands:"
    echo "  up [config]       - Bring up the VPN specified by config or first available"
    echo "  down [config]     - Bring down the VPN specified by config or all"
    echo "  list              - List all WireGuard interfaces"
    echo "  status [config]   - Show status of VPN config or all configs"
    echo "  configs           - List available VPN configurations"
    echo "  help              - Show this help message"
}

# Main function to handle wg-vpn commands
wg_vpn_main() {
    if [ $# -eq 0 ]; then
        wg_vpn_help
        return
    fi

    case "$1" in
        up)
            CONFIG="${2:-$(ls $CONFIG_DIR/*.conf | head -n 1 | xargs basename -s .conf)}"
            sudo wg-quick up "$CONFIG_DIR/$CONFIG.conf"
            [[ $? -eq 0 ]] && log_action "VPN $CONFIG up" && echo "VPN $CONFIG is now up" || echo "Failed to bring up VPN $CONFIG"
            ;;
        down)
            if [ -n "$2" ]; then
                sudo wg-quick down "$CONFIG_DIR/$2.conf"
            else
                sudo wg-quick down all
            fi
            log_action "VPN ${2:-all} down"
            ;;
        list)
            sudo wg show interfaces
            ;;
        status)
            if [ -n "$2" ]; then
                sudo wg show "$2"
            else
                sudo wg show all
            fi
            ;;
        configs)
            list_vpns
            ;;
        help)
            wg_vpn_help
            ;;
        *)
            echo "Unknown command. Use 'x wg-vpn help' for usage."
            return 1
            ;;
    esac

    # Additional checks or operations could be added here, like verifying VPN status post operation
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    wg_vpn_main "$@"
fi

# Function to report script loaded, for integration with your bash_x system
report_to_bash_aliases() {
    echo "wg-vpn functions loaded: up, down, list, status, configs"
}

# If the script is sourced, it won't execute the main function but will report loaded functions
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    report_to_bash_aliases
fi
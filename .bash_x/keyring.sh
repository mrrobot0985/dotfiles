#!/bin/bash

# keyring.sh - Enhanced wrapper for secret-tool to manage keyring items easily

# Check if secret-tool is installed
if ! command -v secret-tool &> /dev/null; then
    echo "secret-tool is not installed. It can be installed with 'libsecret-tools'."
    read -p "Do you want to install libsecret-tools? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo apt update && sudo apt install libsecret-tools -y
        if ! command -v secret-tool &> /dev/null; then
            echo "Installation failed or libsecret-tools does not provide secret-tool. Please check your package manager."
            exit 1
        fi
    else
        exit 1
    fi
fi

# Function to show usage
keyring_help() {
    echo "Usage: x keyring [command] [options]"
    echo "Commands:"
    echo "  store   <label> <attribute> <value> - Store a secret."
    echo "  lookup  <attribute> <value>         - Lookup a secret."
    echo "  delete  <attribute> <value>         - Delete a secret."
    echo "  search  [--all] [--unlock] <attribute> <value> - Search for secrets."
    echo "  lock    --collection='collection'   - Lock a specific collection."
    echo "  help                                - Show this help message."
}

# Main keyring function
keyring_main() {
    if [ $# -eq 0 ]; then
        keyring_help
        return
    fi

    case "$1" in
        store)
            if [ $# -lt 4 ]; then
                echo "Usage: x keyring store <label> <attribute> <value>"
                return 1
            fi
            secret-tool store --label="$2" "$3" "$4"
            ;;
        lookup)
            if [ $# -ne 3 ]; then
                echo "Usage: x keyring lookup <attribute> <value>"
                return 1
            fi
            secret-tool lookup "$2" "$3"
            ;;
        delete)
            if [ $# -ne 3 ]; then
                echo "Usage: x keyring delete <attribute> <value>"
                return 1
            fi
            secret-tool clear "$2" "$3"
            ;;
        search)
            shift
            OPTIONS=()
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --all|--unlock) OPTIONS+=("$1"); shift ;;
                    *) break ;;
                esac
            done
            if [ $# -ne 2 ]; then
                echo "Usage: x keyring search [--all] [--unlock] <attribute> <value>"
                return 1
            fi
            secret-tool search "${OPTIONS[@]}" "$1" "$2"
            ;;
        lock)
            if [ "$2" != "--collection" ] || [ -z "$3" ]; then
                echo "Usage: x keyring lock --collection='collection'"
                return 1
            fi
            secret-tool lock --collection="$3"
            ;;
        help)
            keyring_help
            ;;
        *)
            echo "Unknown command. Use 'x keyring help' for usage."
            return 1
            ;;
    esac
}

# Run the main function if the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    keyring_main "$@"
fi

# Function to report script loaded
report_to_bash_aliases() {
    echo "keyring functions loaded: store, lookup, delete, search, lock"
}
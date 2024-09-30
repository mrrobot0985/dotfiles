#!/bin/bash

# generator.sh - A utility for generating various types of data

# Password Generator
generate_password() {
    local length=${1:-16}  # Default length is 16 if not specified
    if ! [[ "$length" =~ ^[0-9]+$ ]]; then
        echo "Error: Length must be a number." >&2
        return 1
    fi
    tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' </dev/urandom | head -c "$length"
    echo  # New line for formatting
}

# Hash Generator (using SHA256 for simplicity)
generate_hash() {
    local input=${1:-$(date +%s%N)}  # Use current nanoseconds if no input provided
    echo -n "$input" | sha256sum | cut -d' ' -f1
}

# Random Name Generator 
generate_random_name() {
    local names=("Alice" "Bob" "Charlie" "Diana" "Ethan" "Fiona" "George" "Hannah" "Ian" "Julia")
    echo ${names[$RANDOM % ${#names[@]}]}
}

# Detected Name Generator (mock function)
detect_name() {
    echo "JohnDoe"  # This would typically be more complex
}

# Help function for usage
generator_help() {
    echo "Usage: x generator <type> [options]"
    echo "Types and Options:"
    echo "  password [length] - Generate a password. Optional length (default 16)."
    echo "  hash [string]     - Generate a SHA256 hash. Optional string to hash."
    echo "  random_name       - Generate a random name from a predefined list."
    echo "  detected_name     - 'Detects' a name (currently static for demo)."
    echo "Examples:"
    echo "  x generator password 20  - Generates a 20-character password"
    echo "  x generator hash 'my secret' - Hashes the string 'my secret'"
}

# Main generator function
generator_main() {
    if [ $# -eq 0 ]; then
        generator_help
        return
    fi

    case "$1" in
        password|hash|random_name|detected_name)
            if [[ "$1" == "password" && $# -eq 1 ]]; then
                generate_password
            elif [[ "$1" == "password" ]]; then
                generate_password "$2"
            elif [[ "$1" == "hash" ]]; then
                generate_hash "${2:-}"
            else
                "generate_$1"
            fi
            ;;
        help|--help)
            generator_help
            ;;
        *)
            echo "Unknown type. Use 'help' for usage information."
            return 1
            ;;
    esac
}

# Run the main function if the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    generator_main "$@"
fi

# Function to report script loaded
report_to_bash_aliases() {
    echo "generator functions loaded: password, hash, random_name, detected_name"
}
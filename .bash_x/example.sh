#!/bin/bash

# Example script to demonstrate how to set up a script in ~/.bash_x/

# Function to show usage or help
example_help() {
    echo "Usage: x example [action] [parameters]"
    echo "Actions:"
    echo "  hello       - Say hello to someone"
    echo "  echo        - Echo back any input"
}

# Main function that will be called when 'x example' is executed
example_main() {
    case "$1" in
        hello)
            if [ -n "$2" ]; then
                echo "Hello, $2!"
            else
                echo "Hello, World!"
            fi
            ;;
        echo)
            shift
            echo "$@"
            ;;
        *)
            example_help
            return 1
            ;;
    esac
}

# If this script is run directly (not sourced), it'll execute the main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    example_main "$@"
fi

# Optionally, if you want to provide a way for .bash_aliases to know this script is loaded
report_to_bash_aliases() {
    echo "example functions loaded: hello, echo"
}

# Call this function when the script is sourced to indicate it's been loaded
report_to_bash_aliases
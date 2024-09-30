#!/bin/bash

# init function: Setup colors for better readability
init() {
    NC='\e[0m'       # No Color
    RED='\e[31m'
    GREEN='\e[32m'
    BLUE='\e[34m'
    ORANGE='\e[33m'
    PURPLE='\e[35m'
    OUTPUT_MODE=${OUTPUT_MODE:-default}
}

# Welcome message with dynamic aliases placeholder
welcome() {
    echo -e "\n${GREEN}Welcome to ${USER} terminal, ${PURPLE}${USER}!${NC}"
    echo -e "${BLUE}You're now logged into: ${PURPLE}$(hostname -f)${NC}"
    echo -e "${BLUE}Current time: ${ORANGE}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${BLUE}Current directory: ${ORANGE}$PWD${NC}"
    echo -e "${BLUE}Mode: ${ORANGE}${OUTPUT_MODE}${NC}"
    environment_info
    echo -e "${BLUE}Aliases: ${NC}$(display_aliases)"
}

# Show help for x_shell
show_help() {
    echo -e "${BLUE}x (${USER}) Help:${NC}"
    echo -e "Use 'x' as an alias to run commands or access sub-commands from $HOME/.bash_x/:"
    echo -e "Examples:"
    echo -e "  ${GREEN}x ls -la${NC} - Runs 'ls -la'."
    echo -e "  ${GREEN}x echo Hello, World!${NC} - Prints 'Hello, World!'."
    echo -e "  ${GREEN}x myscript.sh${NC} - Executes 'myscript.sh' if in PATH or current directory."
    
    echo -e "\nAvailable subcommands from $HOME/.bash_x/:"
    if [[ -d $HOME/.bash_x ]]; then
        for file in $HOME/.bash_x/*.sh; do
            if [[ -x "$file" ]]; then
                echo -e "  ${GREEN}x $(basename "$file" .sh)${NC}"
            fi
        done
    else
        echo -e "${RED}x Directory $HOME/.bash_x does not exist.${NC}"
    fi
}

# Environment Information with color
environment_info() {
    echo -e "\n${BLUE}System Information:${NC}"
    echo -e "${BLUE}Kernel: ${ORANGE}$(uname -r)${NC}"
    echo -e "${BLUE}Shell: ${ORANGE}$SHELL${NC}"
    echo -e "${BLUE}CPU: ${ORANGE}$(grep -m 1 'model name' /proc/cpuinfo | cut -d ':' -f2 | sed 's/^ //')${NC}"
    echo -e "${BLUE}Memory: ${ORANGE}$(free -h | awk '/^Mem:/ {print $2}')${NC}"
}

# Display aliases based on the output mode, excluding directories and home
display_aliases() {
    local aliases_to_check=(ls la ll debug nodebug l gs ga gc gp gl update myip ports runpy runjs top)
    local exclude_aliases=(.. ... ~)

    case $OUTPUT_MODE in
        default)
            for alias in "${aliases_to_check[@]}"; do
                if [[ ! " ${exclude_aliases[@]} " =~ " ${alias} " ]]; then
                    echo -n "$alias "
                fi
            done
            ;;
        *)
            echo "Unknown mode: $OUTPUT_MODE. Using default."
            display_aliases  # Fallback to default
            ;;
    esac
}

# x_shell function: acts as a dispatcher for commands or scripts in $HOME/.bash_x/
x_shell() {
    if [ $# -eq 0 ]; then
        show_help
        return
    fi
    
    local cmd="$1"
    shift
    
    if [[ -x "$HOME/.bash_x/$cmd.sh" ]]; then
        "$HOME/.bash_x/$cmd.sh" "$@"
    else
        "$cmd" "$@"
    fi
}

# Main execution
init

# Directory check before attempting to make scripts executable
if [[ ! -d $HOME/.bash_x ]]; then
    echo -e "${RED}x Directory $HOME/.bash_x does not exist. Please create it or check the path.${NC}"
else
    welcome
    # Make all scripts in $HOME/.bash_x executable
    chmod +x $HOME/.bash_x/*.sh 2>/dev/null
fi

# Set up x alias for x_shell
alias x=x_shell
echo
x
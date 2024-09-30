#!/bin/bash

# ssh-keygen.sh - SSH key management with secret-tool for keyring management

# Constants
MINIMUM_BITS=3072
DEFAULT_NAME="id_rsa"
DEFAULT_TYPE="rsa"
SSH_DIR=~/.ssh

# Function to show usage
ssh_keygen_help() {
    echo "Usage: ssh-keygen <command> [options]"
    echo "Commands:"
    echo "  list    - List all SSH keys in $SSH_DIR"
    echo "  create  - Create a new SSH key"
    echo "  read    - Read an SSH public key"
    echo "  update  - Update the password of an existing SSH key"
    echo "  delete  - Delete an SSH key pair"
    echo "  help    - Show this help message"
    echo "Environment Variable for Password Override: X_SSH_<KEYNAME>"
}

# Secret management with secret-tool
store_secret() {
    local key="$1"
    local value="$2"
    echo "$value" | secret-tool store --label="SSH Key Password for $key" "$key" password
}

get_secret() {
    local key="$1"
    secret-tool lookup "$key" password
}

update_secret() {
    local key="$1"
    local new_value="$2"
    if secret-tool lookup "$key" password > /dev/null; then
        echo "$new_value" | secret-tool store --label="SSH Key Password for $key" "$key" password
    else
        echo "No existing secret found for $key."
    fi
}

delete_secret() {
    local key="$1"
    secret-tool clear "$key" password
}

# Function to generate or retrieve password
get_or_generate_password() {
    local keyname=$1
    local env_var="X_SSH_$(echo $keyname | tr '[:lower:]' '[:upper:]')"
    local password=${!env_var}
    if [ -z "$password" ]; then
        password=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
        store_secret "$keyname" "$password"
        echo "Generated and stored password for $keyname."
    else
        echo "Using password from environment variable for $keyname."
    fi
    echo "$password"
}

# List all SSH keys
list_keys() {
    echo "Listing SSH keys in $SSH_DIR:"
    ls -l $SSH_DIR/*.pub 2>/dev/null | awk '{print $9}' | sed 's/.pub$//'
    if [ $? -ne 0 ]; then
        echo "No keys found or unable to list."
    fi
}

# Read an SSH public key
read_key() {
    local name=$1
    cat $SSH_DIR/$name.pub 2>/dev/null || echo "Key not found or unable to read."
}

# Create a new SSH key with password handling
create_key() {
    local name=$1
    if [ -z "$name" ]; then
        echo "Provide a name for the key:"
        read -r name
    fi

    local keyfile=$SSH_DIR/$name
    if [[ -f $keyfile && -f $keyfile.pub ]]; then
        echo "Info: Key files for '$name' already exist. No action taken."
        return
    fi

    local password=$(get_or_generate_password $name)
    
    ssh-keygen -t $DEFAULT_TYPE -b $MINIMUM_BITS -f "$keyfile" -N "$password" -C "$name@$(hostname)"
    if [ $? -eq 0 ]; then
        echo "SSH key pair generated at $keyfile and $keyfile.pub"
    else
        echo "Failed to create SSH key."
    fi
}

# Update password of an existing key
update_key() {
    local name=$1
    local keyfile=$SSH_DIR/$name
    if [[ ! -f $keyfile ]]; then
        echo "Key does not exist."
        return
    fi
    
    local new_password=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 20)
    update_secret "$name" "$new_password"
    echo "Password updated for key '$name'."
}

# Delete an SSH key pair
delete_key() {
    local name=$1
    local keyfile=$SSH_DIR/$name
    if [ ! -f "$keyfile" ]; then
        echo "Key not found: $name"
        return
    fi
    
    read -p "Are you sure you want to delete the key pair for '$name'? (y/n) " -n 1 -r
    echo    # Move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$keyfile" "$keyfile.pub"
        if [ $? -eq 0 ]; then
            delete_secret "$name"
            echo "SSH key pair for '$name' has been deleted."
        else
            echo "Failed to delete SSH key pair for '$name'."
        fi
    else
        echo "Deletion canceled."
    fi
}

# Backup SSH key pair
backup_key() {
    local name=$1
    local keyfile="$SSH_DIR/$name"
    if [ ! -f "$keyfile" ] || [ ! -f "$keyfile.pub" ]; then
        echo "Key pair for '$name' not found."
        return
    fi

    local backup_file="ssh_$(date +%Y%m%d)_$name.tar.gz"
    local temp_dir=$(mktemp -d)
    cp "$keyfile" "$keyfile.pub" "$temp_dir/"
    
    # Retrieve the password from secret-tool and include it in the backup
    local password=$(get_secret "$name")
    echo "$password" > "$temp_dir/password.txt"
    
    echo "Enter password for the backup archive:"
    read -s backup_password
    
    tar -czf "$backup_file" -C "$temp_dir" .
    if [ $? -eq 0 ]; then
        echo "Backup created: $backup_file"
    else
        echo "Failed to create backup."
    fi
    
    rm -rf "$temp_dir"
}

# Show SSH public key
show_key() {
    local name=$1
    if [ -z "$name" ]; then
        echo "Please specify the name of the key to show:"
        read -r name
    fi
    local pub_key_file="$SSH_DIR/$name.pub"
    if [ -f "$pub_key_file" ]; then
        cat "$pub_key_file"
    else
        echo "Public key for '$name' not found."
    fi
}

# Main menu
ssh_keygen_main() {
    if [ $# -eq 0 ]; then
        ssh_keygen_help
        return
    fi

    case "$1" in
        backup) backup_key "$2" ;;
        show) show_key "$2" ;;
        list) list_keys ;;
        create) create_key "$2" ;;
        read)
            if [ -z "$2" ]; then
                echo "Please provide a key name to read."
            else
                read_key "$2"
            fi
            ;;
        update)
            if [ -z "$2" ]; then
                echo "Please provide a key name to update."
            else
                update_key "$2"
            fi
            ;;
        delete)
            if [ -z "$2" ]; then
                echo "Please provide a key name to delete."
            else
                delete_key "$2"
            fi
            ;;
        help) ssh_keygen_help ;;
        *) echo "Unknown command. Use 'help' for usage information." ;;
    esac
}

# Run if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ssh_keygen_main "$@"
fi
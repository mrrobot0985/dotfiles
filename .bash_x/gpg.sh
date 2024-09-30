#!/bin/bash

# gpg-keygen.sh - Full-featured GPG key management with secret-tool for secret management

# Configuration
DEFAULT_NAME="Test User"
DEFAULT_EMAIL="test@example.com"
MINIMUM_KEY_SIZE=4096

# Helper functions
gpg_keygen_help() {
    echo "Usage: gpg-keygen <command> [options]"
    echo "Commands:"
    echo "  create  - Create a new GPG key"
    echo "  delete  - Delete a GPG key"
    echo "  revoke  - Revoke a GPG key"
    echo "  backup  - Backup a GPG key"
    echo "  export  - Export public key"
    echo "  show    - Show the public key of a specified key"
    echo "  list    - List all available GPG keys"
    echo "  help    - Show this help message"
}

# Secret management using secret-tool
store_secret() {
    local key="$1"
    local secret="$2"
    secret-tool store --label="GPG Passphrase for $key" attribute1 "$key" <<< "$secret"
}

get_secret() {
    local key="$1"
    secret-tool lookup attribute1 "$key"
}

delete_secret() {
    local key="$1"
    secret-tool clear attribute1 "$key"
}

# GPG Key Management Functions
create_key() {
    local name="${1:-$DEFAULT_NAME}"
    local email="${2:-$DEFAULT_EMAIL}"
    local passphrase=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 20)

    if store_secret "$name" "$passphrase"; then
        cat >gpg-batch <<EOF
Key-Type: RSA
Key-Length: $MINIMUM_KEY_SIZE
Subkey-Type: RSA
Subkey-Length: $MINIMUM_KEY_SIZE
Name-Real: $name
Name-Email: $email
Expire-Date: 0
Passphrase: $passphrase
%no-ask-passphrase
%no-protection
%commit
EOF

        gpg --batch --generate-key gpg-batch && echo "GPG key for $name ($email) has been created." || echo "Failed to create GPG key."
        rm gpg-batch
    else
        echo "Failed to store passphrase. Key creation aborted."
    fi
}

delete_key() {
    local key_specifier=$1
    if [[ -z "$key_specifier" ]]; then
        echo "Please provide an email, Key ID, or name to delete:"
        read -r key_specifier
    fi

    local key_id=$(gpg --list-keys "$key_specifier" 2>/dev/null | awk '/^pub/{getline; print $1; exit}' | sed 's/\/.*//')
    if [[ -z "$key_id" ]]; then
        echo "Could not find key with provided specifier."
        return 1
    fi

    local email=$(gpg --list-keys "$key_id" | grep -oP '(?<=<)[^>]+(?=>)')
    local name=$(gpg --list-keys "$key_id" | grep -oP '(?<=\().*(?=\))')

    echo "You are about to delete the GPG key for '$name ($email)' with ID: $key_id."
    read -p "Are you sure you want to proceed? (y/n): " confirm

    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        gpg --batch --yes --delete-secret-and-public-key "$key_id"
        if [ $? -eq 0 ]; then
            echo "GPG key successfully deleted."
            delete_secret "$key_specifier"
        else
            echo "Failed to delete GPG key."
        fi
    else
        echo "Deletion cancelled."
    fi
}

revoke_key() {
    local key_specifier=$1
    if [[ -z "$key_specifier" ]]; then
        echo "Please provide an email, Key ID, or name to revoke:"
        read -r key_specifier
    fi

    local key_id=$(gpg --list-keys "$key_specifier" 2>/dev/null | awk '/^pub/{getline; print $1; exit}' | sed 's/\/.*//')
    if [[ -z "$key_id" ]]; then
        echo "Could not find key with provided specifier."
        return 1
    fi

    local email=$(gpg --list-keys "$key_id" | grep -oP '(?<=<)[^>]+(?=>)')
    local name=$(gpg --list-keys "$key_id" | grep -oP '(?<=\().*(?=\))')
    
    local revoke_file="revoke_cert_for_${key_id}.asc"
    
    echo "Generating revocation certificate for '$name ($email)' with ID: $key_id."
    
    gpg --output "$revoke_file" --gen-revoke "$key_id"
    
    if [ $? -eq 0 ]; then
        echo "Revocation certificate generated: $revoke_file"
        read -p "Would you like to apply this revocation now? (y/n): " apply_revocation
        
        if [[ $apply_revocation == [yY] || $apply_revocation == [yY][eE][sS] ]]; then
            gpg --import "$revoke_file"
            if [ $? -eq 0 ]; then
                echo "Key for '$name ($email)' has been revoked."
            else
                echo "Failed to apply revocation."
            fi
        else
            echo "Revocation not applied. Certificate saved for later use."
        fi
    else
        echo "Failed to generate revocation certificate."
    fi
}

backup_key() {
    local key_specifier=$1
    if [[ -z "$key_specifier" ]]; then
        echo "Please provide an email, Key ID, or name to backup:"
        read -r key_specifier
    fi

    local key_id=$(gpg --list-keys "$key_specifier" 2>/dev/null | awk '/^pub/{getline; print $1; exit}' | sed 's/\/.*//')
    if [[ -z "$key_id" ]]; then
        echo "Could not find key with provided specifier."
        return 1
    fi

    local backup_file="gpg_backup_${key_id}_$(date +%Y%m%d).gpg"
    gpg --output "$backup_file" --armor --export-secret-keys "$key_id"
    gpg --output "${backup_file}.public" --armor --export "$key_id"
    echo "Backup complete. Private and public keys saved to ${backup_file} and ${backup_file}.public"
}

export_public_key() {
    local key_specifier=$1
    if [[ -z "$key_specifier" ]]; then
        echo "Please provide an email, Key ID, or name to export:"
        read -r key_specifier
    fi

    local key_id=$(gpg --list-keys "$key_specifier" 2>/dev/null | awk '/^pub/{getline; print $1; exit}' | sed 's/\/.*//')
    if [[ -z "$key_id" ]]; then
        echo "Could not find key with provided specifier."
        return 1
    fi

    local export_file="public_key_${key_id}.asc"
    gpg --output "$export_file" --armor --export "$key_id"
    echo "Public key exported to $export_file"
}

show_public_key() {
    local key_specifier=$1
    if [[ -z "$key_specifier" ]]; then
        echo "Please provide an email, Key ID, or name to show:"
        read -r key_specifier
    fi

    gpg --armor --export "$key_specifier"
}

list_keys() {
    gpg --list-keys
}

# Main function to handle commands
gpg_keygen_main() {
    case "$1" in
        create) create_key "$2" "$3" ;;
        delete) delete_key "$2" ;;
        revoke) revoke_key "$2" ;;
        backup) backup_key "$2" ;;
        export) export_public_key "$2" ;;
        show) show_public_key "$2" ;;
        list) list_keys ;;
        help) gpg_keygen_help ;;
        *) gpg_keygen_help ;;
    esac
}

# Entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    gpg_keygen_main "$@"
fi
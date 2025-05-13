#!/bin/bash

# CONFIG
AUTHFILE="/etc/u2f_mappings"
U2F_LINE_PATTERN="pam_u2f.so"
USER=$(logname)
BACKUP_BASE="/etc/pam.d"
BACKUP_DIR_LATEST=$(ls -td "$BACKUP_BASE"/u2f-backup-* 2>/dev/null | head -n1)

# Function to remove pam_u2f.so lines safely
remove_u2f_lines() {
    local file=$1
    if [[ -f "$file" ]]; then
        sed -i "/$U2F_LINE_PATTERN/d" "$file"
        echo "Removed U2F line from $file"
    fi
}

echo "=== Reverting U2F setup ==="

# 1. Restore from latest backup if available
if [[ -n "$BACKUP_DIR_LATEST" ]]; then
    echo "Restoring from backup: $BACKUP_DIR_LATEST"
    for backup_file in "$BACKUP_DIR_LATEST"/*; do
        orig_file="${BACKUP_BASE}/$(basename "$backup_file")"
        if [[ -f "$orig_file" ]]; then
            cp "$backup_file" "$orig_file"
            echo "Restored $orig_file"
        fi
    done
else
    echo "No backup found. Manually removing U2F lines from known files."
    for file in /etc/pam.d/login /etc/pam.d/sudo /etc/pam.d/su /etc/pam.d/gdm-password /etc/pam.d/lightdm; do
        remove_u2f_lines "$file"
    done
fi

# 2. Remove the shared authfile
if [[ -f "$AUTHFILE" ]]; then
    rm -f "$AUTHFILE"
    echo "Deleted $AUTHFILE"
fi

# 3. Optional: Remove individual user U2F keys
read -rp "Do you want to delete the user's and root's ~/.config/Yubico/u2f_keys files? (y/N): " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    rm -f "/home/$USER/.config/Yubico/u2f_keys"
    rm -f "/root/.config/Yubico/u2f_keys"
    echo "Deleted u2f_keys for $USER and root"
else
    echo "Skipped deletion of user-specific u2f_keys."
fi

echo "✅ U2F has been removed from your system."

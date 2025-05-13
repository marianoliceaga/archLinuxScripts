#!/bin/bash

set -e

FPRINTD_LINE_PATTERN="pam_fprintd.so"
BACKUP_DIR_LATEST=$(ls -td /etc/pam.d/fingerprint-backup-* 2>/dev/null | head -n1)

echo "🧹 Reverting fingerprint configuration..."

# 1. Restore from backup if available
if [[ -n "$BACKUP_DIR_LATEST" ]]; then
    echo "📦 Restoring from backup at $BACKUP_DIR_LATEST"
    for backup_file in "$BACKUP_DIR_LATEST"/*; do
        orig_file="/etc/pam.d/$(basename "$backup_file")"
        cp "$backup_file" "$orig_file"
        echo "  → Restored $orig_file"
    done
else
    echo "⚠️ No backup found. Removing pam_fprintd.so lines manually."
    for file in /etc/pam.d/login /etc/pam.d/sudo /etc/pam.d/su /etc/pam.d/gdm-password /etc/pam.d/lightdm; do
        if [[ -f "$file" ]]; then
            sed -i "/$FPRINTD_LINE_PATTERN/d" "$file"
            echo "  → Cleaned $file"
        fi
    done
fi

# 2. Optional: Remove enrolled fingerprint
read -rp "🗑️  Do you want to delete your fingerprint data (fprintd-delete)? [y/N]: " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    fprintd-delete
    echo "🧼 Fingerprint data deleted"
else
    echo "Skipped fingerprint deletion"
fi

echo "❌ Fingerprint authentication removed from system."


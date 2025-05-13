#!/bin/bash

set -e

PAM_FILES=(
    "/etc/pam.d/login"
    "/etc/pam.d/sudo"
    "/etc/pam.d/su"
    "/etc/pam.d/gdm-password"
    "/etc/pam.d/lightdm"
)
FPRINTD_LINE="auth      sufficient    pam_fprintd.so"
BACKUP_DIR="/etc/pam.d/fingerprint-backup-$(date +%Y%m%d-%H%M%S)"

echo "🔍 Installing dependencies..."
sudo pacman -S --noconfirm fprintd

echo "📦 Backing up PAM files to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

for file in "${PAM_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo "- Processing $file"
        cp "$file" "$BACKUP_DIR/"

        # Only insert if not already present
        if ! grep -q "pam_fprintd.so" "$file"; then
            sed -i "1i $FPRINTD_LINE" "$file"
            echo "  → Added fingerprint line"
        else
            echo "  → Already configured"
        fi
    fi
done

echo "🖐️ Registering your fingerprint (run as current user)"
fprintd-enroll

echo "✅ Fingerprint authentication enabled for login, sudo, su, and graphical sessions."
echo "🔁 Test login and sudo in another terminal before logging out!"


#!/bin/bash

set -e

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root."
   exit 1
fi

echo "🔒 Disabling root remote login..."

# Backup sshd_config
SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.bak.$(date +%F-%H%M%S)"
cp "$SSHD_CONFIG" "$BACKUP"
echo "✅ Backup of sshd_config saved to $BACKUP"

# Disable root login in sshd_config
if grep -q "^PermitRootLogin" "$SSHD_CONFIG"; then
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
else
    echo "PermitRootLogin no" >> "$SSHD_CONFIG"
fi
echo "✅ Root login via SSH disabled in sshd_config"

# Restart SSH service
if systemctl is-active --quiet sshd; then
    systemctl restart sshd
    echo "🔄 SSH service restarted (sshd)"
elif systemctl is-active --quiet ssh; then
    systemctl restart ssh
    echo "🔄 SSH service restarted (ssh)"
else
    echo "⚠️ SSH service not found or inactive — please restart manually."
fi

# Lock the root account
passwd -l root && echo "✅ Root account locked"

# Change root shell to /usr/sbin/nologin
usermod -s /usr/sbin/nologin root && echo "✅ Root shell changed to /usr/sbin/nologin"

echo "✅ All changes applied successfully."

# Optional: remind the user to test before logging out
echo -e "\n⚠️ Please ensure you can log in as a non-root user with sudo access before closing this session!"

#!/bin/bash
set -e

BACKUP_DIR="/etc/pam.d/backup_fingerprint_u2f"
FILES=("system-local-login" "login" "sddm" "sudo")

if [ ! -d "$BACKUP_DIR" ]; then
  echo "[!] Backup directory not found: $BACKUP_DIR"
  exit 1
fi

echo "[*] Restoring PAM configuration..."
for file in "${FILES[@]}"; do
  if [ -f "$BACKUP_DIR/$file.bak" ]; then
    cp "$BACKUP_DIR/$file.bak" "/etc/pam.d/$file"
    echo " - Restored /etc/pam.d/$file"
  else
    echo " - Skipped $file (no backup found)"
  fi
done

echo "[✓] Original PAM configuration restored."

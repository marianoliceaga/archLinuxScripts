#!/bin/bash
set -e

BACKUP_DIR="/etc/pam.d/backup_fingerprint_u2f"
mkdir -p "$BACKUP_DIR"

FILES=("system-local-login" "login" "sddm" "sudo")

echo "[*] Backing up original PAM files..."
for file in "${FILES[@]}"; do
  cp "/etc/pam.d/$file" "$BACKUP_DIR/$file.bak"
done

echo "[*] Applying fingerprint + U2F-only login policy..."

PAM_POLICY=$(cat <<'EOF'
#%PAM-1.0
auth       requisite    pam_nologin.so
auth       [success=1 default=ignore] pam_fprintd.so
auth       [success=1 default=ignore] pam_u2f.so cue
auth       required     pam_deny.so

account    required     pam_unix.so
session    required     pam_limits.so
EOF
)

# Apply to system-local-login, login, and sudo
for file in "system-local-login" "login" "sudo"; do
  echo "$PAM_POLICY" > "/etc/pam.d/$file"
done

# Configure sddm to use system-local-login (without modifying its internals)
cat <<EOF > /etc/pam.d/sddm
auth      include     system-local-login
account   include     system-local-login
password  include     system-local-login
session   include     system-local-login
EOF

echo "[✓] Only fingerprint and U2F logins are now allowed."
echo "[ℹ] If you get locked out, boot with a live USB and restore from: $BACKUP_DIR"

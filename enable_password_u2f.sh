#!/bin/bash

set -e

PAM_FILES=(
    "/etc/pam.d/login"
    "/etc/pam.d/sudo"
    "/etc/pam.d/su"
    "/etc/pam.d/gdm-password"
    "/etc/pam.d/lightdm"
)
AUTHFILE="/etc/u2f_mappings"
U2F_LINE="auth required pam_u2f.so authfile=${AUTHFILE} cue userpresence"
BACKUP_DIR="/etc/pam.d/u2f-2fa-backup-$(date +%Y%m%d-%H%M%S)"
CURRENT_USER=$(logname)

echo "📦 Backing up PAM files to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# 1. Register U2F if not already done
if [[ ! -f "$AUTHFILE" ]]; then
    echo "🔐 Registering U2F for root and $CURRENT_USER"
    sudo mkdir -p /root/.config/Yubico
    sudo pamu2fcfg -u root | sudo tee /root/.config/Yubico/u2f_keys > /dev/null

    sudo -u "$CURRENT_USER" mkdir -p "/home/$CURRENT_USER/.config/Yubico"
    sudo -u "$CURRENT_USER" pamu2fcfg -u "$CURRENT_USER" > "/home/$CURRENT_USER/.config/Yubico/u2f_keys"

    echo "🔗 Creating $AUTHFILE"
    cat /root/.config/Yubico/u2f_keys > "$AUTHFILE"
    echo "" >> "$AUTHFILE"
    cat "/home/$CURRENT_USER/.config/Yubico/u2f_keys" >> "$AUTHFILE"
    chmod 644 "$AUTHFILE"
fi

# 2. Insert U2F line AFTER pam_unix.so in each PAM file
for file in "${PAM_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo "- Updating $file"
        cp "$file" "$BACKUP_DIR/"

        if grep -q "$U2F_LINE" "$file"; then
            echo "  → U2F line already exists"
        else
            # Insert U2F line after pam_unix.so "auth" line
            awk -v u2fline="$U2F_LINE" '
                BEGIN { inserted = 0 }
                {
                    print $0
                    if (!inserted && $1 == "auth" && $3 ~ /pam_unix.so/) {
                        print u2fline
                        inserted = 1
                    }
                }
            ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
            echo "  → Added U2F line"
        fi
    fi
done

echo "✅ Combined password + U2F enabled for all relevant services."
echo "🔁 Test in a new terminal or tty before logging out."

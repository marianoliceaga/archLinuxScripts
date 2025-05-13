#!/bin/bash

# ===== CONFIG =====
PAM_FILES=(
    "/etc/pam.d/login"
    "/etc/pam.d/sudo"
    "/etc/pam.d/su"
    "/etc/pam.d/gdm-password"  # GDM
    "/etc/pam.d/lightdm"       # LightDM
)
AUTHFILE="/etc/u2f_mappings"
U2F_LINE="auth       required     pam_u2f.so authfile=${AUTHFILE} cue userpresence"
CURRENT_USER=$(logname)
BACKUP_DIR="/etc/pam.d/u2f-backup-$(date +%Y%m%d-%H%M%S)"

# ===== 1. Install pam-u2f if missing =====
if ! pacman -Q pam-u2f &>/dev/null; then
    echo "Installing pam-u2f..."
    sudo pacman -S --noconfirm pam-u2f
fi

# ===== 2. Register U2F keys for root and user =====
echo "Registering U2F device for root and $CURRENT_USER"
echo ">>> Touch the device when prompted"

sudo mkdir -p /root/.config/Yubico
sudo pamu2fcfg -u root | sudo tee /root/.config/Yubico/u2f_keys > /dev/null

sudo -u "$CURRENT_USER" mkdir -p "/home/$CURRENT_USER/.config/Yubico"
sudo -u "$CURRENT_USER" pamu2fcfg -u "$CURRENT_USER" > "/home/$CURRENT_USER/.config/Yubico/u2f_keys"

# ===== 3. Combine into shared authfile =====
echo "Creating $AUTHFILE with both keys"
cat /root/.config/Yubico/u2f_keys > "$AUTHFILE"
echo "" >> "$AUTHFILE"
cat "/home/$CURRENT_USER/.config/Yubico/u2f_keys" >> "$AUTHFILE"
chmod 644 "$AUTHFILE"

# ===== 4. Patch PAM files =====
echo "Backing up original PAM files to

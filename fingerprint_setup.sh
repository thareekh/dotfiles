#!/bin/bash

set -e

echo "======================================"
echo " Goodix 27c6:550a Fingerprint Setup"
echo "======================================"

# Check yay
if ! command -v yay >/dev/null 2>&1; then
    echo "ERROR: yay is not installed."
    exit 1
fi

echo
echo "==> Installing Goodix fingerprint driver..."
yay -S --needed fprintd libfprint-2-tod1-goodix

echo
echo "==> Restarting fingerprint daemon..."
sudo systemctl restart fprintd

echo
echo "==> Checking fingerprint device..."
fprintd-list "$USER"

# -------------------------------------------------
# Configure SDDM fingerprint login
# -------------------------------------------------

echo
echo "==> Configuring SDDM fingerprint authentication..."

if [ ! -f /etc/pam.d/sddm ]; then
    echo "ERROR: /etc/pam.d/sddm does not exist."
    exit 1
fi

# Create backup
sudo cp /etc/pam.d/sddm /etc/pam.d/sddm.backup

# Add fingerprint authentication only if not already present
if ! grep -q "pam_fprintd.so" /etc/pam.d/sddm; then
    sudo sed -i '2i auth    sufficient    pam_fprintd.so' /etc/pam.d/sddm
    echo "Fingerprint PAM authentication added."
else
    echo "Fingerprint PAM authentication already configured."
fi

# Check PAM module
if [ -f /usr/lib/security/pam_fprintd.so ]; then
    echo "PAM fingerprint module found."
else
    echo "ERROR: pam_fprintd.so was not found."
    exit 1
fi

echo
echo "======================================"
echo " Setup complete!"
echo "======================================"

echo
echo "Fingerprint device:"
fprintd-list "$USER"

echo
echo "If no fingerprint is enrolled, run:"
echo "    fprintd-enroll"

echo
echo "Test your fingerprint with:"
echo "    fprintd-verify"

echo
echo "SDDM configuration backup:"
echo "    /etc/pam.d/sddm.backup"

echo
echo "You can reboot and test fingerprint login:"
echo "    reboot"

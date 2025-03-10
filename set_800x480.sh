#!/bin/bash

# Script to set 800x480 resolution on both HDMI ports for Raspberry Pi OS

# Check if running as root (needed for package installs)
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo: sudo ./set_800x480.sh"
    exit 1
fi

# Update package lists and install wlr-randr
echo "Updating package lists and installing wlr-randr..."
apt update
apt install -y wlr-randr

# Create or edit ~/.config/wayfire.ini for the current user (default: pi)
WAYFIRE_CONFIG="/home/pi/.config/wayfire.ini"
mkdir -p /home/pi/.config  # Ensure .config directory exists
chown pi:pi /home/pi/.config  # Set correct ownership

# Check if wayfire.ini exists and has [autostart] section
if [ ! -f "$WAYFIRE_CONFIG" ]; then
    echo "Creating new wayfire.ini..."
    cat <<EOF > "$WAYFIRE_CONFIG"
[autostart]
resolution_hdmi_a1 = wlr-randr --output HDMI-A-1 --custom-mode 800x480@60
resolution_hdmi_a2 = wlr-randr --output HDMI-A-2 --custom-mode 800x480@60
EOF
else
    # Check if [autostart] exists
    if ! grep -q "\[autostart\]" "$WAYFIRE_CONFIG"; then
        echo "Adding [autostart] section to existing wayfire.ini..."
        echo -e "\n[autostart]" >> "$WAYFIRE_CONFIG"
    fi
    # Add resolution commands if not already present
    if ! grep -q "resolution_hdmi_a1" "$WAYFIRE_CONFIG"; then
        echo "Adding HDMI-A-1 resolution setting..."
        sed -i "/\[autostart\]/a resolution_hdmi_a1 = wlr-randr --output HDMI-A-1 --custom-mode 800x480@60" "$WAYFIRE_CONFIG"
    fi
    if ! grep -q "resolution_hdmi_a2" "$WAYFIRE_CONFIG"; then
        echo "Adding HDMI-A-2 resolution setting..."
        sed -i "/\[autostart\]/a resolution_hdmi_a2 = wlr-randr --output HDMI-A-2 --custom-mode 800x480@60" "$WAYFIRE_CONFIG"
    fi
fi

# Set correct ownership and permissions
chown pi:pi "$WAYFIRE_CONFIG"
chmod 644 "$WAYFIRE_CONFIG"

# Apply the resolution immediately for the current session
echo "Applying 800x480 resolution to both HDMI ports now..."
su - pi -c "wlr-randr --output HDMI-A-1 --custom-mode 800x480@60" 2>/dev/null || true
su - pi -c "wlr-randr --output HDMI-A-2 --custom-mode 800x480@60" 2>/dev/null || true

echo "Setup complete! Resolution set to 800x480 for both HDMI ports."
echo "Please reboot to ensure it applies on startup: sudo reboot"

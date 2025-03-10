#!/bin/bash

# Script to set 800x480 resolution on both HDMI ports for Raspberry Pi OS

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo: sudo ./set_800x480.sh"
    exit 1
fi

# Update package lists and install wlr-randr
echo "Updating package lists and installing wlr-randr..."
apt update
apt install -y wlr-randr

# Create or edit ~/.config/wayfire.ini for user 'pi'
WAYFIRE_CONFIG="/home/pi/.config/wayfire.ini"
mkdir -p /home/pi/.config
chown pi:pi /home/pi/.config

# Check if wayfire.ini exists and has [autostart] section
if [ ! -f "$WAYFIRE_CONFIG" ]; then
    echo "Creating new wayfire.ini..."
    cat <<EOF > "$WAYFIRE_CONFIG"
[autostart]
resolution_script = /home/pi/set_resolution.sh
EOF
else
    if ! grep -q "\[autostart\]" "$WAYFIRE_CONFIG"; then
        echo "Adding [autostart] section..."
        echo -e "\n[autostart]" >> "$WAYFIRE_CONFIG"
    fi
    if ! grep -q "resolution_script" "$WAYFIRE_CONFIG"; then
        echo "Adding resolution script to autostart..."
        sed -i "/\[autostart\]/a resolution_script = /home/pi/set_resolution.sh" "$WAYFIRE_CONFIG"
    fi
fi

# Create a separate resolution script with retry logic
RESOLUTION_SCRIPT="/home/pi/set_resolution.sh"
cat <<'EOF' > "$RESOLUTION_SCRIPT"
#!/bin/bash
# Wait and retry setting 800x480 on both HDMI ports
for i in {1..5}; do
    wlr-randr --output HDMI-A-1 --custom-mode 800x480@60 2>/dev/null && HDMI1_SET=true || HDMI1_SET=false
    wlr-randr --output HDMI-A-2 --custom-mode 800x480@60 2>/dev/null && HDMI2_SET=true || HDMI2_SET=false
    if [ "$HDMI1_SET" = true ] && [ "$HDMI2_SET" = true ]; then
        break
    fi
    sleep 2  # Wait 2 seconds before retrying
done
EOF

# Set permissions and ownership
chmod +x "$RESOLUTION_SCRIPT"
chown pi:pi "$RESOLUTION_SCRIPT"
chown pi:pi "$WAYFIRE_CONFIG"
chmod 644 "$WAYFIRE_CONFIG"

# Apply immediately
echo "Applying 800x480 resolution to both HDMI ports now..."
su - pi -c "/home/pi/set_resolution.sh"

echo "Setup complete! Resolution set to 800x480 for both HDMI ports."
echo "Please reboot to ensure it applies on startup: sudo reboot"

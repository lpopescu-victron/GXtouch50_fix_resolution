#!/bin/bash

# Script to set resolution on both HDMI ports based on manually selected screen model for Raspberry Pi OS
# This script can be run as an update to clean up previous files and processes.

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo: sudo ./set_resolution.sh"
    exit 1
fi

# Stop any running processes related to the previous resolution setup
echo "Stopping any running set-resolution processes..."
systemctl stop set-resolution.service 2>/dev/null && echo "Stopped set-resolution.service."
pkill -f "/home/pi/set_resolution.sh" 2>/dev/null && echo "Killed any running set_resolution.sh processes."

# Delete previous files
echo "Cleaning up previous files..."
rm -f /home/pi/set_resolution.sh 2>/dev/null && echo "Deleted old set_resolution.sh."
rm -f /home/pi/resolution_log.txt 2>/dev/null && echo "Deleted old resolution_log.txt."
rm -f /etc/systemd/system/set-resolution.service 2>/dev/null && echo "Deleted old set-resolution.service."

# Reload systemd to remove any lingering service definitions
echo "Reloading systemd..."
systemctl daemon-reload && echo "Systemd reloaded."

# Install wlr-randr
echo "Installing wlr-randr..."
apt update && apt install -y wlr-randr && echo "wlr-randr installed."

# Prompt user to select screen model
echo "Select your screen model:"
echo "1) GX Touch 50 (800x480)"
echo "2) GX Touch 70 (1024x600)"
echo "3) Default Pi settings (no custom resolution)"
read -p "Enter your choice (1-3): " CHOICE

# Validate input and set resolution
case "$CHOICE" in
    1)
        SCREEN_MODEL="GX Touch 50"
        RESOLUTION="800x480@60"
        ;;
    2)
        SCREEN_MODEL="GX Touch 70"
        RESOLUTION="1024x600@60"
        ;;
    3)
        SCREEN_MODEL="Default Pi settings"
        RESOLUTION=""
        ;;
    *)
        echo "Invalid choice! Defaulting to Default Pi settings."
        SCREEN_MODEL="Default Pi settings"
        RESOLUTION=""
        ;;
esac

echo "Selected screen model: $SCREEN_MODEL"

# Create resolution script
echo "Creating new set_resolution.sh..."
cat <<EOF > /home/pi/set_resolution.sh
#!/bin/bash
sleep 30
LOG_FILE="/home/pi/resolution_log.txt"
touch "\$LOG_FILE"
chmod 666 "\$LOG_FILE"
echo "Script started at \$(date)" > "\$LOG_FILE"
export XDG_RUNTIME_DIR=/run/user/1000
export WAYLAND_DISPLAY=wayland-0
echo "XDG_RUNTIME_DIR=\$XDG_RUNTIME_DIR" >> "\$LOG_FILE"
echo "WAYLAND_DISPLAY=\$WAYLAND_DISPLAY" >> "\$LOG_FILE"

# Force resolution on both HDMI ports
if [ -n "$RESOLUTION" ]; then
    # Retry logic for HDMI-A-1
    for i in {1..5}; do
        echo "Attempt \$i: Applying resolution $RESOLUTION to HDMI-A-1..." >> "\$LOG_FILE"
        wlr-randr --output HDMI-A-1 --on --custom-mode $RESOLUTION >> "\$LOG_FILE" 2>&1
        if [ \$? -eq 0 ]; then
            echo "Resolution applied successfully to HDMI-A-1." >> "\$LOG_FILE"
            break
        else
            echo "Attempt \$i: Failed to set $RESOLUTION on HDMI-A-1" >> "\$LOG_FILE"
            sleep 5
        fi
    done

    # Retry logic for HDMI-A-2
    for i in {1..5}; do
        echo "Attempt \$i: Applying resolution $RESOLUTION to HDMI-A-2..." >> "\$LOG_FILE"
        wlr-randr --output HDMI-A-2 --on --custom-mode $RESOLUTION >> "\$LOG_FILE" 2>&1
        if [ \$? -eq 0 ]; then
            echo "Resolution applied successfully to HDMI-A-2." >> "\$LOG_FILE"
            break
        else
            echo "Attempt \$i: Failed to set $RESOLUTION on HDMI-A-2" >> "\$LOG_FILE"
            sleep 5
        fi
    done

    # Verify resolution
    wlr-randr >> "\$LOG_FILE" 2>&1
    grep -q "$RESOLUTION" "\$LOG_FILE" && echo "Resolution applied successfully." >> "\$LOG_FILE" || echo "Failed to apply resolution." >> "\$LOG_FILE"
fi
echo "Script completed at \$(date)" >> "\$LOG_FILE"

# Clean up after successful execution
rm -f /home/pi/set_resolution.sh && echo "Deleted set_resolution.sh after execution." >> "\$LOG_FILE"
EOF

# Set permissions
echo "Setting permissions for set_resolution.sh..."
chmod +x /home/pi/set_resolution.sh && echo "Permissions set."
chown pi:pi /home/pi/set_resolution.sh && echo "Ownership set to pi:pi."

# Create systemd service
echo "Creating set-resolution.service..."
cat <<EOF > /etc/systemd/system/set-resolution.service
[Unit]
Description=Set screen resolution on both HDMI ports
After=graphical.target
Wants=graphical.target

[Service]
Type=oneshot
User=pi
ExecStart=/home/pi/set_resolution.sh
RemainAfterExit=yes

[Install]
WantedBy=graphical.target
EOF

# Enable service
echo "Enabling set-resolution.service..."
systemctl daemon-reload && echo "Systemd reloaded."
systemctl enable set-resolution.service && echo "set-resolution.service enabled."

# Inform user
if [ -n "$RESOLUTION" ]; then
    echo "Resolution for $SCREEN_MODEL ($RESOLUTION) will be forced on both HDMI-A-1 and HDMI-A-2 after reboot."
    echo "Check /home/pi/resolution_log.txt after reboot for debugging."
else
    echo "Default Pi settings will be used after reboot."
fi

echo "Rebooting now..."

# Reboot
reboot

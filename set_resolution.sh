#!/bin/bash

# Script to set resolution on both HDMI ports based on manually selected screen model for Raspberry Pi OS

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo: sudo ./set_resolution.sh"
    exit 1
fi

# Install wlr-randr
echo "Installing wlr-randr..."
apt update
apt install -y wlr-randr

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
cat <<EOF > /home/pi/set_resolution.sh
#!/bin/bash
sleep 60
LOG_FILE="/home/pi/resolution_log.txt"
touch "\$LOG_FILE"
chmod 666 "\$LOG_FILE"
echo "Script started at \$(date)" > "\$LOG_FILE"
export XDG_RUNTIME_DIR=/run/user/1000
export WAYLAND_DISPLAY=wayland-0
echo "XDG_RUNTIME_DIR=\$XDG_RUNTIME_DIR" >> "\$LOG_FILE"
echo "WAYLAND_DISPLAY=\$WAYLAND_DISPLAY" >> "\$LOG_FILE"
if [ -n "$RESOLUTION" ]; then
    for i in {1..3}; do
        wlr-randr --output HDMI-A-1 --on --custom-mode $RESOLUTION >> "\$LOG_FILE" 2>&1 || echo "Attempt \$i: Failed to set $RESOLUTION on HDMI-A-1" >> "\$LOG_FILE"
        wlr-randr --output HDMI-A-2 --on --custom-mode $RESOLUTION >> "\$LOG_FILE" 2>&1 || echo "Attempt \$i: Failed to set $RESOLUTION on HDMI-A-2" >> "\$LOG_FILE"
        sleep 5
        wlr-randr >> "\$LOG_FILE" 2>&1
        grep -q "$RESOLUTION" "\$LOG_FILE" && break
    done
fi
echo "Script completed at \$(date)" >> "\$LOG_FILE"
EOF

# Set permissions
chmod +x /home/pi/set_resolution.sh
chown pi:pi /home/pi/set_resolution.sh

# Create systemd service
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
systemctl daemon-reload
systemctl enable set-resolution.service

# Inform user
if [ -n "$RESOLUTION" ]; then
    echo "Resolution for $SCREEN_MODEL ($RESOLUTION) will be applied to both HDMI-A-1 and HDMI-A-2 after reboot."
    echo "Check /home/pi/resolution_log.txt after reboot for debugging."
else
    echo "Default Pi settings will be used after reboot."
fi
echo "Rebooting now..."

# Reboot
reboot

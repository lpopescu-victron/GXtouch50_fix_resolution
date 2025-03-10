#!/bin/bash

# Script to set resolution based on manually selected screen model for Raspberry Pi OS

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo: sudo ./set_resolution.sh"
    exit 1
fi

# Clean up old files to ensure fresh setup
echo "Cleaning up old resolution files..."
rm -f /home/pi/set_resolution_auto.sh /home/pi/resolution_log.txt /home/pi/.config/wayfire.ini /etc/systemd/system/set-resolution.service /home/pi/.config/systemd/user/set-resolution.service

# Update package lists and install wlr-randr
echo "Updating package lists and installing wlr-randr..."
apt update
apt install -y wlr-randr

# Prompt user to select screen model
echo "Select your screen model:"
echo "1) GX Touch 50 (800x480)"
echo "2) GX Touch 70 (1024x600)"
echo "3) Default Pi settings (no custom resolution)"
read -p "Enter your choice (1-3): " CHOICE

# Validate input
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
        RESOLUTION="default"
        ;;
    *)
        echo "Invalid choice! Defaulting to Default Pi settings."
        SCREEN_MODEL="Default Pi settings"
        RESOLUTION="default"
        ;;
esac

echo "Selected screen model: $SCREEN_MODEL"

# Create resolution script
RESOLUTION_SCRIPT="/home/pi/set_resolution_auto.sh"
cat <<EOF > "$RESOLUTION_SCRIPT"
#!/bin/bash
# Set resolution on both HDMI ports based on selected model, log to file
LOG_FILE="/home/pi/resolution_log.txt"
echo "Resolution script started at \$(date)" > "\$LOG_FILE"
logger -t set-resolution "Script started"

# Wait for display initialization
sleep 15
echo "Waited 15 seconds for display initialization" >> "\$LOG_FILE"
logger -t set-resolution "Waited 15 seconds"

# Log environment for debugging
echo "XDG_RUNTIME_DIR=\$XDG_RUNTIME_DIR" >> "\$LOG_FILE"
echo "WAYLAND_DISPLAY=\$WAYLAND_DISPLAY" >> "\$LOG_FILE"
logger -t set-resolution "XDG_RUNTIME_DIR=\$XDG_RUNTIME_DIR, WAYLAND_DISPLAY=\$WAYLAND_DISPLAY"

# Apply to HDMI-A-1
echo "Applying selected model: $SCREEN_MODEL to HDMI-A-1..." | tee -a "\$LOG_FILE"
logger -t set-resolution "Applying $SCREEN_MODEL to HDMI-A-1"
if [ "$RESOLUTION" != "default" ]; then
    wlr-randr --output HDMI-A-1 --custom-mode $RESOLUTION 2>>"\$LOG_FILE" && echo "Successfully set $RESOLUTION on HDMI-A-1" >> "\$LOG_FILE" || echo "Failed to set $RESOLUTION on HDMI-A-1, trying 800x480@60..." >> "\$LOG_FILE" && wlr-randr --output HDMI-A-1 --custom-mode 800x480@60 2>>"\$LOG_FILE" && echo "Fallback to 800x480@60 succeeded on HDMI-A-1" >> "\$LOG_FILE" || echo "Fallback failed on HDMI-A-1" >> "\$LOG_FILE"
else
    echo "Using default resolution for HDMI-A-1" | tee -a "\$LOG_FILE"
fi

# Apply to HDMI-A-2
echo "Applying selected model: $SCREEN_MODEL to HDMI-A-2..." | tee -a "\$LOG_FILE"
logger -t set-resolution "Applying $SCREEN_MODEL to HDMI-A-2"
if [ "$RESOLUTION" != "default" ]; then
    wlr-randr --output HDMI-A-2 --custom-mode $RESOLUTION 2>>"\$LOG_FILE" && echo "Successfully set $RESOLUTION on HDMI-A-2" >> "\$LOG_FILE" || echo "Failed to set $RESOLUTION on HDMI-A-2, trying 800x480@60..." >> "\$LOG_FILE" && wlr-randr --output HDMI-A-2 --custom-mode 800x480@60 2>>"\$LOG_FILE" && echo "Fallback to 800x480@60 succeeded on HDMI-A-2" >> "\$LOG_FILE" || echo "Fallback failed on HDMI-A-2" >> "\$LOG_FILE"
else
    echo "Using default resolution for HDMI-A-2" | tee -a "\$LOG_FILE"
fi

echo "Resolution setup complete for this session at \$(date)" | tee -a "\$LOG_FILE"
logger -t set-resolution "Setup complete"
EOF

# Set permissions and ownership
chmod +x "$RESOLUTION_SCRIPT"
chown pi:pi "$RESOLUTION_SCRIPT"

# Create user systemd service
mkdir -p /home/pi/.config/systemd/user
SERVICE_FILE="/home/pi/.config/systemd/user/set-resolution.service"
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Set screen resolution on HDMI ports
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=oneshot
ExecStart=/home/pi/set_resolution_auto.sh
RemainAfterExit=yes
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

# Set permissions for user service
chown pi:pi "$SERVICE_FILE"
chmod 644 "$SERVICE_FILE"

# Enable user service
su - pi -c "systemctl --user enable set-resolution.service"
su - pi -c "systemctl --user daemon-reload"

# Inform user
echo "Resolution for $SCREEN_MODEL will be applied after reboot."
echo "After reboot, check messages in /home/pi/resolution_log.txt or run: /home/pi/set_resolution_auto.sh"
echo "Check system logs with: journalctl -u set-resolution.service --user-unit"

# Clean up this script
echo "Cleaning up downloaded script..."
rm -f "$0"

# Reboot the Pi
echo "Rebooting now to apply changes permanently..."
echo "Post-reboot, check resolution with: wlr-randr and service status with: systemctl --user status set-resolution.service"
reboot

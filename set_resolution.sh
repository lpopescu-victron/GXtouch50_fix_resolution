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

# Configure /etc/rc.local to set resolution on both HDMI ports at boot with logging
echo "Configuring /etc/rc.local..."
cat <<EOF > /etc/rc.local
#!/bin/bash
sleep 40
LOG_FILE="/home/pi/resolution_log.txt"
touch "\$LOG_FILE"
chmod 666 "\$LOG_FILE"
echo "rc.local started at \$(date)" > "\$LOG_FILE"
if [ -n "$RESOLUTION" ]; then
    su - pi -c "wlr-randr --output HDMI-A-1 --on --custom-mode $RESOLUTION" >> "\$LOG_FILE" 2>&1 || echo "Failed to set $RESOLUTION on HDMI-A-1" >> "\$LOG_FILE"
    su - pi -c "wlr-randr --output HDMI-A-2 --on --custom-mode $RESOLUTION" >> "\$LOG_FILE" 2>&1 || echo "Failed to set $RESOLUTION on HDMI-A-2" >> "\$LOG_FILE"
    su - pi -c "wlr-randr" >> "\$LOG_FILE" 2>&1  # Log current state of all outputs
fi
echo "rc.local completed at \$(date)" >> "\$LOG_FILE"
exit 0
EOF

# Make rc.local executable
chmod +x /etc/rc.local

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

#!/bin/bash

# Script to set resolution based on manually selected screen model for Raspberry Pi OS

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo: sudo ./set_resolution.sh"
    exit 1
fi

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

# Create or edit ~/.config/wayfire.ini for user 'pi'
WAYFIRE_CONFIG="/home/pi/.config/wayfire.ini"
mkdir -p /home/pi/.config
chown pi:pi /home/pi/.config

# Check if wayfire.ini exists and has [autostart] section
if [ ! -f "$WAYFIRE_CONFIG" ]; then
    echo "Creating new wayfire.ini..."
    cat <<EOF > "$WAYFIRE_CONFIG"
[autostart]
resolution_script = /home/pi/set_resolution_auto.sh
EOF
else
    if ! grep -q "\[autostart\]" "$WAYFIRE_CONFIG"; then
        echo "Adding [autostart] section..."
        echo -e "\n[autostart]" >> "$WAYFIRE_CONFIG"
    fi
    if ! grep -q "resolution_script" "$WAYFIRE_CONFIG"; then
        echo "Adding resolution script to autostart..."
        sed -i "/\[autostart\]/a resolution_script = /home/pi/set_resolution_auto.sh" "$WAYFIRE_CONFIG"
    fi
fi

# Create a separate resolution script with selected resolution and logging
RESOLUTION_SCRIPT="/home/pi/set_resolution_auto.sh"
cat <<EOF > "$RESOLUTION_SCRIPT"
#!/bin/bash
# Set resolution on both HDMI ports based on selected model, log to file
LOG_FILE="/home/pi/resolution_log.txt"
echo "Resolution script started at \$(date)" > "\$LOG_FILE"

# Wait for display initialization
sleep 5
echo "Waited 5 seconds for display initialization" >> "\$LOG_FILE"

for i in {1..5}; do
    # Apply to HDMI-A-1
    HDMI1_MODEL=\$(wlr-randr | grep -A1 "HDMI-A-1" | grep -o '"[^"]*"' | head -n1)
    if [ -n "\$HDMI1_MODEL" ]; then
        echo "Detected \$HDMI1_MODEL on HDMI-A-1, applying selected model: $SCREEN_MODEL..." | tee -a "\$LOG_FILE"
    else
        echo "No screen detected on HDMI-A-1, still applying selected model: $SCREEN_MODEL..." | tee -a "\$LOG_FILE"
    fi
    if [ "$RESOLUTION" != "default" ]; then
        wlr-randr --output HDMI-A-1 --custom-mode $RESOLUTION 2>>"\$LOG_FILE" && HDMI1_SET=true || HDMI1_SET=false
        [ "\$HDMI1_SET" = false ] && echo "Failed to set $RESOLUTION on HDMI-A-1" >> "\$LOG_FILE"
    else
        echo "Using default resolution for HDMI-A-1" | tee -a "\$LOG_FILE"
        HDMI1_SET=true
    fi

    # Apply to HDMI-A-2
    HDMI2_MODEL=\$(wlr-randr | grep -A1 "HDMI-A-2" | grep -o '"[^"]*"' | head -n1)
    if [ -n "\$HDMI2_MODEL" ]; then
        echo "Detected \$HDMI2_MODEL on HDMI-A-2, applying selected model: $SCREEN_MODEL..." | tee -a "\$LOG_FILE"
    else
        echo "No screen detected on HDMI-A-2, still applying selected model: $SCREEN_MODEL..." | tee -a "\$LOG_FILE"
    fi
    if [ "$RESOLUTION" != "default" ]; then
        wlr-randr --output HDMI-A-2 --custom-mode $RESOLUTION 2>>"\$LOG_FILE" && HDMI2_SET=true || HDMI2_SET=false
        [ "\$HDMI2_SET" = false ] && echo "Failed to set $RESOLUTION on HDMI-A-2" >> "\$LOG_FILE"
    else
        echo "Using default resolution for HDMI-A-2" | tee -a "\$LOG_FILE"
        HDMI2_SET=true
    fi

    # Exit loop if both are set or no further changes needed
    if [ "\$HDMI1_SET" = true ] && [ "\$HDMI2_SET" = true ]; then
        break
    fi
    sleep 2  # Wait 2 seconds before retrying
done
echo "Resolution setup complete for this session at \$(date)" | tee -a "\$LOG_FILE"
EOF

# Set permissions and ownership
chmod +x "$RESOLUTION_SCRIPT"
chown pi:pi "$RESOLUTION_SCRIPT"
chown pi:pi "$WAYFIRE_CONFIG"
chmod 644 "$WAYFIRE_CONFIG"

# Inform user
echo "Resolution for $SCREEN_MODEL will be applied after reboot."
echo "After reboot, check messages in /home/pi/resolution_log.txt or run: /home/pi/set_resolution_auto.sh"

# Clean up this script
echo "Cleaning up downloaded script..."
rm -f "$0"

# Reboot the Pi
echo "Rebooting now to apply changes permanently..."
echo "Post-reboot, check resolution with: wlr-randr"
reboot

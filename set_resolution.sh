#!/bin/bash

# Script to set resolution based on manually selected screen model for Raspberry Pi OS

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

# Configure /etc/rc.local to set resolution at boot
echo "Configuring /etc/rc.local..."
cat <<EOF > /etc/rc.local
#!/bin/bash
sleep 30
EOF

# Add resolution commands based on choice
if [ -n "$RESOLUTION" ]; then
    echo "su - pi -c \"wlr-randr --output HDMI-A-1 --on --custom-mode $RESOLUTION\"" >> /etc/rc.local
    # Uncomment the next line in the file manually if using HDMI-A-2
    echo "# su - pi -c \"wlr-randr --output HDMI-A-2 --on --custom-mode $RESOLUTION\"" >> /etc/rc.local
else
    echo "# No custom resolution set - using default Pi settings" >> /etc/rc.local
fi

echo "exit 0" >> /etc/rc.local

# Make rc.local executable
chmod +x /etc/rc.local

# Inform user
if [ -n "$RESOLUTION" ]; then
    echo "Resolution for $SCREEN_MODEL ($RESOLUTION) will be applied after reboot."
else
    echo "Default Pi settings will be used after reboot."
fi
echo "Rebooting now..."

# Reboot
reboot

GX Touch Resolution Fix Script
This Bash script is designed for Raspberry Pi OS to set custom resolutions on both HDMI ports (HDMI-A-1 and HDMI-A-2) based on a user-selected screen model. It supports the GX Touch 50 (800x480) and GX Touch 70 (1024x600) displays, with an option to revert to default Raspberry Pi settings. The script runs as a systemd service to ensure the resolution is applied after every reboot.

Installation
To download and execute the script in one step:

```bash
wget https://raw.githubusercontent.com/lpopescu-victron/GXtouch_fix_resolution/main/set_resolution.sh && chmod +x set_resolution.sh && sudo ./set_resolution.sh
```

Features
Cleans up previous resolution scripts and services.
Installs wlr-randr for Wayland-based resolution management.
Prompts the user to select a screen model.
Applies the chosen resolution to both HDMI ports with retry logic.
Logs execution details for debugging.
Automatically reboots the system after setup.
Prerequisites
Raspberry Pi running Raspberry Pi OS (Wayland-based).
Root privileges (sudo) to execute the script.
Internet connection to install wlr-randr.

When prompted, choose a screen model by entering a number:

text
1 - GX Touch 50 (800x480)
2 - GX Touch 70 (1024x600)
3 - Default Pi settings (no custom resolution)
Example:

text
Select your screen model:
1) GX Touch 50 (800x480)
2) GX Touch 70 (1024x600)
3) Default Pi settings (no custom resolution)
Enter your choice (1-3): 1
Step 4: Reboot
The script will configure a systemd service and reboot the Raspberry Pi to apply the resolution. After reboot, the selected resolution will be enforced on both HDMI ports (if applicable).

What Happens After Running?
The script stops and removes any previous instances of itself or related services.
It installs wlr-randr if not already present.
A new script (/home/pi/set_resolution.sh) is created and executed via a systemd service (set-resolution.service) on boot.
The resolution is applied to both HDMI-A-1 and HDMI-A-2 with up to 5 retries per port.
A log file (/home/pi/resolution_log.txt) is generated for debugging.
The temporary script deletes itself after successful execution.
Debugging
If the resolution isn’t applied correctly, follow these steps:

Check the Log File
After reboot, inspect the log file:

```bash
cat /home/pi/resolution_log.txt
```

Look for:

Success messages (e.g., "Resolution applied successfully to HDMI-A-1").
Failure messages (e.g., "Failed to set 800x480@60 on HDMI-A-2").
Output from wlr-randr to verify current resolutions.
Verify HDMI Outputs
List available outputs and their resolutions:

```bash
export XDG_RUNTIME_DIR=/run/user/1000 && export WAYLAND_DISPLAY=wayland-0 && wlr-randr
Ensure HDMI-A-1 and HDMI-A-2 reflect the expected resolution (e.g., 800x480 or 1024x600).
```
Check Systemd Service Status
Verify the service ran successfully:

```bash
sudo systemctl status set-resolution.service
```
If it failed, check the ExecStart output in the status or log file.
Restart the service manually if needed:

```bash
sudo systemctl restart set-resolution.service
```
Common Issues
"Command not found: wlr-randr": Ensure apt install wlr-randr completed successfully. Check your internet connection and run:

```bash
sudo apt update && sudo apt install -y wlr-randr
```
Resolution not applied: Confirm Wayland is in use (echo $XDG_SESSION_TYPE should output wayland). If using X11, this script won’t work as expected.
Permission errors: Ensure the script is run with sudo.
Manual Cleanup
To remove the script and its components:


```bash
sudo systemctl stop set-resolution.service && sudo systemctl disable set-resolution.service && sudo rm -f /etc/systemd/system/set-resolution.service && sudo rm -f /home/pi/set_resolution.sh && sudo rm -f /home/pi/resolution_log.txt && sudo systemctl daemon-reload
```
Notes
The script assumes the user is pi. Adjust paths and ownership if using a different user.
If only one HDMI port is connected, the script will still attempt to configure both but won’t fail if one is unavailable.
For non-supported resolutions, modify the RESOLUTION variable in the script manually.

Contributing
Feel free to submit issues or pull requests to improve this script!

Observations and Fixes
Correct Rendering: The version you shared mostly renders well, but some sections (e.g., "Features," "What Happens After Running?") were plain text instead of Markdown lists. I’ve added - for proper bullet points.
Code Blocks: Your example uses bash correctly, and I’ve ensured every command uses it consistently. Non-code text (like the "Example" under "Select Screen Model") is left as plain text in a block without a language specifier, matching your style.
Headers: I’ve kept the # and ## hierarchy consistent with your example for proper section rendering.
Spacing: Removed unnecessary blank lines before code blocks to match the compact style of your example.
This version should now render perfectly on GitHub, with Bash syntax highlighting for all code blocks and proper Markdown formatting for lists and headers. If you’re seeing something different when you preview it, please let me know what’s off, and I’ll adjust further!

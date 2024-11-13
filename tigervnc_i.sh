#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update package list
echo "Updating package list..."
apt update

# Install TigerVNC server
echo "Installing TigerVNC..."
apt install -y tigervnc-standalone-server tigervnc-common tigervnc-tools

# Create a user for VNC (change 'username' to your desired username)
VNC_USER="justin"
if id "$VNC_USER" &>/dev/null; then
    echo "User $VNC_USER exists."
else
    echo "User $VNC_USER does not exist. Please create the user first."
    exit 1
fi

# Set up VNC password for the user
echo "Setting up VNC password for user $VNC_USER..."
sudo -u $VNC_USER vncpasswd

# Create a systemd service file for TigerVNC
echo "Creating VNC service file..."

sudo bash -c 'cat << EOL > /etc/systemd/system/vncserver@.service
[Unit]
Description=Start TightVNC server at startup
After=syslog.target network.target

[Service]
Type=forking
User=$VNC_USER
Group=$VNC_USER
WorkingDirectory=/home/$VNC_USER

PIDFile=/home/$VNC_USER/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1280x800 :%i
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOL'

# Enable the VNC service to start on boot
echo "Enabling VNC service..."
systemctl daemon-reload
systemctl enable vncserver@1.service

# Start the VNC service
echo "Starting VNC service..."
systemctl start vncserver@1.service

echo "TigerVNC installation and configuration completed. You can connect using a VNC client."

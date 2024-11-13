#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update package list
echo "Updating package list..."
apt update

# Install required packages
echo "Installing required packages..."
apt install -y git python3-pip openssl python3-websockify dbus-x11

# Install noVNC
echo "Cloning noVNC repository..."
git clone https://github.com/novnc/noVNC.git /opt/noVNC


# Create OpenSSL RSA key
echo "Generating OpenSSL RSA key..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /opt/noVNC/privatekey.pem \
    -out /opt/noVNC/certificate.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=example.com"

# Create a systemd service file for noVNC
echo "Creating noVNC service file..."
VNC_USER="justin"
sudo bash -c 'cat << EOL > /etc/systemd/system/novnc.service
[Unit]
Description=noVNC WebSocket Proxy

[Service]
Type=simple
User=$VNC_USER
Group=$VNC_USER
ExecStart=/opt/noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 6081 --web /opt/noVNC --cert /opt/noVNC/certificate.pem --key /opt/noVNC/privatekey.pem
Restart=on-failure

[Install]
WantedBy=graphical.target
EOL'

# Enable and start the noVNC service
echo "Enabling and starting noVNC service..."
systemctl daemon-reload
systemctl enable novnc.service
systemctl start novnc.service

echo "noVNC installation and configuration completed. You can access it at http://<your_server_ip>:6080."

#!/bin/bash

echo "Resetting UFW to defaults..."
sudo ufw --force reset

echo "Setting default policies..."
sudo ufw default deny incoming
sudo ufw default deny outgoing

echo "Allowing DNS (TCP + UDP)..."
sudo ufw allow out 53

echo "Allowing HTTP (port 80)..."
sudo ufw allow out 80/tcp

echo "Allowing HTTPS (port 443)..."
sudo ufw allow out 443/tcp

echo "Allowing NTP for Snap and time sync..."
sudo ufw allow out 123/udp

echo "Allowing Docker bridge subnet (adjust if needed)..."
sudo ufw allow out to 172.17.0.0/16

echo "Allowing local network access (for bridged VirtualBox or local services)..."
sudo ufw allow out to 192.168.0.0/16

echo "Allowing ICMP (ping)..."
sudo ufw allow out proto icmp

echo "Enabling UFW..."
sudo ufw --force enable

echo "Done. Your firewall is now configured securely."
sudo ufw status verbose

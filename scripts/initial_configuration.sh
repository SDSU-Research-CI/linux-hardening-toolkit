#!/bin/bash

# Enable Firewall:
sudo ufw allow ssh
sudo ufw enable

# Install Fail2Ban
sudo apt install fail2ban

# Install Net-Tools for legacy network commands:
sudo apt install net-tools

# Install openssh-server:
sudo apt install openssh-server

# Run updates:
sudo apt update
sudo apt upgrade

# Sleep must die:
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

echo "This script has run successfully, continuing with next hardening process"


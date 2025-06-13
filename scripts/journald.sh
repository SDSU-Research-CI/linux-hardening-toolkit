#!/bin/bash

# Check if the script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Add or update the Compress line in journald.conf
echo "Updating journald.conf..."
echo "Compress=yes" >> /etc/systemd/journald.conf
echo "Storage=persistent" >> /etc/systemd/journald.conf

sudo systemctl restart systemd-journald
echo "Done!"

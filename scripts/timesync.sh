#!/usr/bin/env bash

# Define variables
TIMESYNCD_CONF="/etc/systemd/timesyncd.conf"
NTP_SERVER="130.191.200.1"
FALLBACK_NTP="130.191.1.1"

# Check if the timesyncd.conf file exists
if [ -f "$TIMESYNCD_CONF" ]; then
    echo "Updating NTP configuration in $TIMESYNCD_CONF..."

    # Backup the existing configuration file
    sudo cp "$TIMESYNCD_CONF" "${TIMESYNCD_CONF}.bak.$(date +%F-%T)"

    # Update the NTP and FallbackNTP lines
    sudo sed -i "s|^NTP=.*|NTP=${NTP_SERVER}|" "$TIMESYNCD_CONF"
    sudo sed -i "s|^FallbackNTP=.*|FallbackNTP=${FALLBACK_NTP}|" "$TIMESYNCD_CONF"

    # Add the NTP lines if they don't exist
    if ! grep -q "^NTP=" "$TIMESYNCD_CONF"; then
        echo "NTP=${NTP_SERVER}" | sudo tee -a "$TIMESYNCD_CONF" > /dev/null
    fi
    if ! grep -q "^FallbackNTP=" "$TIMESYNCD_CONF"; then
        echo "FallbackNTP=${FALLBACK_NTP}" | sudo tee -a "$TIMESYNCD_CONF" > /dev/null
    fi

    echo "NTP configuration updated successfully."
else
    echo "Error: $TIMESYNCD_CONF does not exist."
    exit 1
fi

# Reload and restart the systemd-journald service
echo "Reloading and restarting systemd-journald service..."
sudo systemctl reload-or-restart systemd-journald

echo "Script completed successfully."


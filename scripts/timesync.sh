#!/usr/bin/env bash

# Point time sync at the SDSU NTP servers.
# Supports systemd-timesyncd (Ubuntu 18.04 to 24.04) and chrony (Ubuntu 25.10 and newer, 26.04).
# Note: the SDSU servers answer only on the campus network or VPN. Chrony keeps the
# default Ubuntu sources as a backup, so time still syncs when they are unreachable.

# Define variables
NTP_SERVER="130.191.200.1"
FALLBACK_NTP="130.191.1.1"
TIMESYNCD_CONF="/etc/systemd/timesyncd.conf"
CHRONY_CONF="/etc/chrony/chrony.conf"
CHRONY_SOURCES_DIR="/etc/chrony/sources.d"
STAMP="$(date +%F-%H%M%S)"

# Must run as root
if [ "$EUID" -ne 0 ]; then
    exec sudo bash "$0" "$@"
fi

if [ -f "$TIMESYNCD_CONF" ]; then
    # ---------- systemd-timesyncd ----------
    echo "Updating NTP configuration in $TIMESYNCD_CONF..."
    cp "$TIMESYNCD_CONF" "${TIMESYNCD_CONF}.bak.${STAMP}"

    # Update the NTP and FallbackNTP lines
    sed -i "s|^NTP=.*|NTP=${NTP_SERVER}|" "$TIMESYNCD_CONF"
    sed -i "s|^FallbackNTP=.*|FallbackNTP=${FALLBACK_NTP}|" "$TIMESYNCD_CONF"

    # Add the NTP lines if they don't exist
    grep -q "^NTP=" "$TIMESYNCD_CONF" || echo "NTP=${NTP_SERVER}" >> "$TIMESYNCD_CONF"
    grep -q "^FallbackNTP=" "$TIMESYNCD_CONF" || echo "FallbackNTP=${FALLBACK_NTP}" >> "$TIMESYNCD_CONF"

    echo "NTP configuration updated successfully."
    echo "Restarting systemd-timesyncd..."
    systemctl restart systemd-timesyncd

elif [ -f "$CHRONY_CONF" ]; then
    # ---------- chrony ----------
    echo "chrony detected, adding SDSU NTP servers..."
    if grep -qE '^\s*sourcedir\s+/etc/chrony/sources\.d' "$CHRONY_CONF"; then
        mkdir -p "$CHRONY_SOURCES_DIR"
        [ -f "$CHRONY_SOURCES_DIR/sdsu.sources" ] && cp "$CHRONY_SOURCES_DIR/sdsu.sources" "$CHRONY_SOURCES_DIR/sdsu.sources.bak.${STAMP}.disabled"
        cat > "$CHRONY_SOURCES_DIR/sdsu.sources" <<SRC
# SDSU NTP servers (managed by timesync.sh)
server ${NTP_SERVER} iburst prefer
server ${FALLBACK_NTP} iburst
SRC
        chronyc reload sources >/dev/null 2>&1 || systemctl restart chrony
    else
        cp "$CHRONY_CONF" "${CHRONY_CONF}.bak.${STAMP}"
        if ! grep -q "$NTP_SERVER" "$CHRONY_CONF"; then
            {
                echo ""
                echo "# SDSU NTP servers (managed by timesync.sh)"
                echo "server ${NTP_SERVER} iburst prefer"
                echo "server ${FALLBACK_NTP} iburst"
            } >> "$CHRONY_CONF"
        fi
        systemctl restart chrony
    fi
    echo "chrony configuration updated successfully."

else
    echo "Error: neither $TIMESYNCD_CONF nor $CHRONY_CONF exists, no time sync service to configure."
    exit 1
fi

echo "Script completed successfully."
exit 0

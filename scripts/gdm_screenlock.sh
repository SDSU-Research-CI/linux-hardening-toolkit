#!/usr/bin/env bash

# Define variables
LOCKS_DIR="/etc/dconf/db/local.d/locks"
LOCKS_FILE="${LOCKS_DIR}/screensaver"
CONTENT="# Lock desktop screensaver settings

/org/gnome/desktop/session/idle-delay
/org/gnome/desktop/screensaver/lock-delay
"

# Create the locks directory if it doesn't exist
if [ ! -d "$LOCKS_DIR" ]; then
    echo "Creating locks directory: $LOCKS_DIR"
    sudo mkdir -p "$LOCKS_DIR"
else
    echo "Locks directory already exists: $LOCKS_DIR"
fi

# Write the content to the screensaver lock file
if [ ! -f "$LOCKS_FILE" ]; then
    echo "Creating lock file: $LOCKS_FILE"
    echo "$CONTENT" | sudo tee "$LOCKS_FILE" > /dev/null
else
    echo "Lock file already exists: $LOCKS_FILE"
fi

# Update the dconf database
echo "Updating dconf database..."
sudo dconf update

echo "Screensaver lock configuration completed."


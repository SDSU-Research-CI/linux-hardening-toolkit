#!/bin/bash

# ================================
# Master Launcher: harden_launcher.sh
# Purpose: Entry point for modular hardening framework
# ================================

set -e

# -------- Logging --------
LOGFILE="/var/log/hardening.log"
echo "Starting hardening process at $(date)" | tee -a "$LOGFILE"

# -------- Detect Environment --------
IS_WSL=0
if grep -qEi "(Microsoft|WSL)" /proc/version; then
    echo "WSL detected — certain configurations will be skipped."
    IS_WSL=1
fi

# -------- User Inputs --------
echo "========== HARDENING SETUP =========="
CURRENT_USER=${SUDO_USER:-$(whoami)}
echo "Detected current user: $CURRENT_USER"

# Confirm or override admin user
while true; do
    read -p "Would you like to use this as the admin account? Type 'yes' to confirm, or enter a different username: " ADMIN_INPUT
    if [[ "$ADMIN_INPUT" =~ ^[Yy][Ee][Ss]$ || -z "$ADMIN_INPUT" ]]; then
        ADMIN_USER="$CURRENT_USER"
        break
    elif [[ "$ADMIN_INPUT" =~ ^[a-zA-Z0-9_][-a-zA-Z0-9_]*$ ]]; then
        ADMIN_USER="$ADMIN_INPUT"
        break
    else
        echo "Invalid input. Please type 'yes' or a valid username."
    fi
done
echo "Using admin account: $ADMIN_USER"

# Source folder input and safe tilde expansion
DEFAULT_SOURCE_DIR="/root"
echo "Specify the full path where the hardening scripts were copied (default: $DEFAULT_SOURCE_DIR):"
read -p "Script source path: " SOURCE_DIR
SOURCE_DIR_RAW="${SOURCE_DIR:-$DEFAULT_SOURCE_DIR}"
if [[ "$SOURCE_DIR_RAW" == ~* ]]; then
    USER_HOME=$(eval echo "~$SUDO_USER")
    SOURCE_DIR="${SOURCE_DIR_RAW/#\~/$USER_HOME}"
else
    SOURCE_DIR="$SOURCE_DIR_RAW"
fi

# Target folder
TARGET_DIR="/home/scripts"
mkdir -p "$TARGET_DIR"

# -------- Copy Scripts (excluding self) --------
SCRIPT_PATH=$(realpath "$0")
echo "Copying scripts to $TARGET_DIR..."
find "$SOURCE_DIR" -type f -name "*.sh" | while read -r f; do
    [[ "$(realpath "$f")" == "$SCRIPT_PATH" ]] && continue
    cp "$f" "$TARGET_DIR/"
done
chmod +x "$TARGET_DIR"/*.sh

# -------- SSH Group Setup --------
echo "Ensuring sshusers group exists..."
sudo groupadd -f sshusers

echo "Adding admin account '$ADMIN_USER' to sshusers group..."
sudo usermod -aG sshusers "$ADMIN_USER"

echo "You may specify additional users to allow remote SSH access."
read -p "Enter comma-separated usernames (or leave blank to skip): " extra_ssh_users
IFS=',' read -ra SSH_USERS <<< "$extra_ssh_users"

if [[ ${#SSH_USERS[@]} -gt 0 && -n "${SSH_USERS[0]// /}" ]]; then
  for user in "${SSH_USERS[@]}"; do
    user=$(echo "$user" | xargs)  # trim whitespace
    if [[ -n "$user" ]]; then
      echo "Adding user '$user' to sshusers group..."
      sudo usermod -aG sshusers "$user"
    fi
  done
else
  echo "No additional users provided."
fi

# -------- Run Scripts Recursively (excluding this one) --------
echo "Running all .sh scripts in $TARGET_DIR recursively..."
find "$TARGET_DIR" -type f -name "*.sh" | while read -r script; do
    [[ "$(realpath "$script")" == "$SCRIPT_PATH" ]] && {
        echo "Skipping self: $script"
        continue
    }
    echo "Executing $script..."
    sudo bash "$script"
done

# -------- Apply Additional Hardening --------
echo "Installing AppArmor, vim, removing FTP client..."
sudo apt install -y apparmor apparmor-utils vim || true
sudo apt purge -y ftp || true

# -------- Configure SSH --------
if [[ $IS_WSL -eq 0 && -f "/etc/ssh/sshd_config" ]]; then
    SSH_CONFIG="/etc/ssh/sshd_config"
    echo "Updating SSH settings..."
    function update_ssh_config() {
        local key="$1"; local value="$2"
        grep -q "^$key" "$SSH_CONFIG" &&
            sudo sed -i "s|^$key.*|$key $value|" "$SSH_CONFIG" ||
            echo "$key $value" | sudo tee -a "$SSH_CONFIG" >/dev/null
    }

    update_ssh_config "AllowGroups" "sshusers"
    update_ssh_config "Banner" "/etc/issue.net"
    update_ssh_config "ClientAliveInterval" "15"
    update_ssh_config "ClientAliveCountMax" "3"
    update_ssh_config "MaxStartups" "10:30:60"

    sudo systemctl restart sshd
else
    echo "Skipping SSH configuration — not applicable in WSL or sshd not found."
fi

# -------- Set Root Password --------
echo "Set root password now:"
sudo passwd root

# -------- Clean Up --------
echo "Cleaning up script folder..."
sudo rm -rf "$TARGET_DIR"

# -------- Finish --------
echo "*** Base hardening completed. ***"
echo "You may now run the CIS-CAT Assessor tool for scoring."
echo "Logs saved at $LOGFILE"

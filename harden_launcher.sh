#!/bin/bash

# ================================
# Master Launcher: harden_launcher.sh
# Purpose: Entry point for modular hardening framework
# ================================

set -e

# -------- Logging --------
LOGFILE="/var/log/hardening.log"
echo "Starting hardening process at $(date)" | tee -a "$LOGFILE"
echo "Hostname: $(hostname)" >> "$LOGFILE"
echo "OS Version: $(lsb_release -ds 2>/dev/null || cat /etc/os-release)" >> "$LOGFILE"
echo "Kernel: $(uname -r)" >> "$LOGFILE"
echo "Script launched by: ${SUDO_USER:-$(whoami)}" >> "$LOGFILE"
echo "Working directory: $(pwd)" >> "$LOGFILE"

# -------- Function: Run Script with Validation --------
run_script() {
    local script=$1
    echo "Running script: $script" | tee -a "$LOGFILE"
    if [[ -f "$script" ]]; then
        if sudo bash "$script" >> "$LOGFILE" 2>&1; then
            echo "✅ Success: $script" | tee -a "$LOGFILE"
        else
            echo "❌ Error: $script failed" | tee -a "$LOGFILE"
            exit 1
        fi
    else
        echo "⚠️ Warning: $script not found" | tee -a "$LOGFILE"
    fi
}
# -------- Detect Environment --------
IS_WSL=0
if grep -qEi "(Microsoft|WSL)" /proc/version; then
    echo "WSL detected — certain configurations will be skipped."
    IS_WSL=1
fi

# -------- User Inputs --------
echo
echo "========== HARDENING SETUP =========="
CURRENT_USER=${SUDO_USER:-$(whoami)}
echo "Detected current user: $CURRENT_USER"
echo
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
echo "Admin account selected: $ADMIN_USER" >> "$LOGFILE"

# Source folder input and safe tilde expansion
BASE_DIR="$(dirname "$(realpath "$0")")"
echo "Detected this script is running from: $BASE_DIR"
read -p "Use this as the source folder for scripts? (Y/n): " USE_BASE

if [[ "$USE_BASE" =~ ^[Nn]$ ]]; then
    read -p "Enter the full path to the scripts folder: " USER_INPUT_DIR
    SOURCE_DIR_RAW="${USER_INPUT_DIR:-$BASE_DIR}"
    if [[ "$SOURCE_DIR_RAW" == ~* ]]; then
        USER_HOME=$(eval echo "~$SUDO_USER")
        SOURCE_DIR="${SOURCE_DIR_RAW/#\~/$USER_HOME}"
    else
        SOURCE_DIR="$SOURCE_DIR_RAW"
    fi
else
    SOURCE_DIR="$BASE_DIR"
fi

echo "Using source directory: $SOURCE_DIR"

# Target folder
TARGET_DIR="/home/scripts"
mkdir -p "$TARGET_DIR"

# -------- Flatten and Copy Scripts from Subfolders --------
echo "Copying all .sh scripts into $TARGET_DIR..."

if [[ -d "$SOURCE_DIR/scripts" ]]; then
    find "$SOURCE_DIR/scripts" -type f -name "*.sh" -exec cp {} "$TARGET_DIR/" \;
else
    echo "Warning: $SOURCE_DIR/scripts not found"
fi

# Exclude the launcher from being copied into the run list
SCRIPT_PATH=$(realpath "$0")
rm -f "$TARGET_DIR/$(basename "$SCRIPT_PATH")"

chmod +x "$TARGET_DIR"/*.sh

ESSENTIAL_ORDER=(
  initial_configuration.sh
  testfix.sh
  ciscat-configs.sh
  ciscat-sysctl.sh
  reverse.sh
  suspicious.sh
  journald.sh
  autorun.sh
)

for name in "${ESSENTIAL_ORDER[@]}"; do
  script_path="$TARGET_DIR/$name"
  if [[ -f "$script_path" ]]; then
    run_script "$script_path"
  else
    echo "Warning: $name not found"
  fi
done

# -------- Additional Sysctl Configuration --------
echo "Applying additional sysctl parameters..." | tee -a "$LOGFILE"
sudo sysctl -w net.ipv4.conf.all.log_martians=1
sudo sysctl -w net.ipv4.conf.default.log_martians=1
sudo sysctl -w net.ipv4.route.flush=1

sudo sysctl -w net.ipv4.conf.all.rp_filter=1
sudo sysctl -w net.ipv4.conf.default.rp_filter=1
sudo sysctl -w net.ipv4.route.flush=1

# -------- Run Any Remaining .sh Scripts --------
echo "Checking for any additional .sh scripts to run..."

for script in "$TARGET_DIR"/*.sh; do
  base=$(basename "$script")
  if [[ ! " ${ESSENTIAL_ORDER[*]} " =~ " $base " ]]; then
    run_script "$script"
  fi
done

# -------- SSH Group Setup --------
echo "Ensuring sshusers group exists..."
sudo groupadd -f sshusers

echo "You may specify additional users to allow remote SSH access."
read -p "Enter comma-separated usernames (or leave blank to skip): " extra_ssh_users
IFS=',' read -ra SSH_USERS <<< "$extra_ssh_users"

if [[ ${#SSH_USERS[@]} -gt 0 && -n "${SSH_USERS[0]// /}" ]]; then
  for user in "${SSH_USERS[@]}"; do
    user=$(echo "$user" | xargs)  # trim whitespace
    if [[ -n "$user" ]]; then
      echo "Adding user '$user' to sshusers group..."
      if getent passwd "$user" >/dev/null; then
        sudo usermod -aG sshusers "$user"
      else
        echo "User '$user' not found in local passwd — treating as domain user"
        sudo sed -i "/^sshusers:/ s/\$/,$user/" /etc/group
      fi
    fi
  done
else
  echo "No additional users provided."
fi
echo "Additional SSH users provided: ${SSH_USERS[*]}" >> "$LOGFILE"

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
echo "*** Base hardening completed. ***" | tee -a "$LOGFILE"
echo "Completed at: $(date)" >> "$LOGFILE"
echo "You may now run the CIS-CAT Assessor tool for scoring."
echo "Logs saved at $LOGFILE"

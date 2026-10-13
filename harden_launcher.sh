#!/bin/bash

# ================================
# Master Launcher: harden_launcher.sh
# Purpose: Entry point for modular hardening framework
# Supports: Ubuntu 18.04 to 26.04 LTS (including Kubuntu) and WSL2
# ================================
#
# Design notes (v1.2.0)
# - No "set -e". Many CIS checks end with a grep or test whose non-zero exit
#   code is a normal result, not a failure. Each script's result is logged,
#   the run continues, and a summary is printed at the end.
# - Every script runs detached from the terminal (setsid) with stdin closed and
#   apt prompts disabled, so a hidden prompt or a job-control stop can never
#   freeze the run.
# - Every script has a time limit (SCRIPT_TIMEOUT, default 1800 seconds).

# -------- Must run as root --------
if [[ $EUID -ne 0 ]]; then
    exec sudo bash "$(realpath "$0")" "$@"
fi

SCRIPT_TIMEOUT="${SCRIPT_TIMEOUT:-1800}"

# -------- Logging --------
LOGFILE="/var/log/hardening.log"
echo "Starting hardening process at $(date)" | tee -a "$LOGFILE"
echo "Hostname: $(hostname)" >> "$LOGFILE"
echo "OS Version: $(lsb_release -ds 2>/dev/null || cat /etc/os-release)" >> "$LOGFILE"
echo "Kernel: $(uname -r)" >> "$LOGFILE"
echo "Script launched by: ${SUDO_USER:-$(whoami)}" >> "$LOGFILE"
echo "Working directory: $(pwd)" >> "$LOGFILE"

# -------- Detect Environment --------
OS_ID=$(. /etc/os-release 2>/dev/null; echo "${ID:-unknown}")
OS_LIKE=$(. /etc/os-release 2>/dev/null; echo "${ID_LIKE:-}")
OS_VERSION=$(. /etc/os-release 2>/dev/null; echo "${VERSION_ID:-unknown}")

IS_WSL=0
if grep -qEi "(Microsoft|WSL)" /proc/version; then
    echo "WSL detected, certain configurations will be skipped."
    IS_WSL=1
fi

# Ubuntu 25.10 and newer ship sudo-rs, which does not support every sudoers option
IS_SUDO_RS=0
if sudo --version 2>/dev/null | head -n 1 | grep -qi "sudo-rs"; then
    IS_SUDO_RS=1
    echo "sudo-rs detected: sudoers options it does not support will be skipped." | tee -a "$LOGFILE"
fi
echo "Detected: id=$OS_ID version=$OS_VERSION wsl=$IS_WSL sudo-rs=$IS_SUDO_RS" >> "$LOGFILE"

if [[ "$OS_ID" != "ubuntu" && "$OS_ID" != "debian" && "$OS_LIKE" != *debian* && "$OS_LIKE" != *ubuntu* ]]; then
    echo "WARNING: this toolkit is built for Ubuntu and Debian based systems (detected: $OS_ID)."
    read -p "Continue anyway? (y/N): " CONTINUE_ANYWAY
    [[ "$CONTINUE_ANYWAY" =~ ^[Yy]$ ]] || exit 1
fi

# -------- Function: Run Script with Validation --------
FAILED_SCRIPTS=()

run_script() {
    local script=$1 rc runner=()
    echo "Running script: $script" | tee -a "$LOGFILE"
    if [[ ! -f "$script" ]]; then
        echo "⚠️ Warning: $script not found" | tee -a "$LOGFILE"
        return 0
    fi
    command -v setsid >/dev/null 2>&1 && runner+=(setsid -w)
    command -v timeout >/dev/null 2>&1 && runner+=(timeout -k 30 "$SCRIPT_TIMEOUT")
    DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a APT_LISTCHANGES_FRONTEND=none \
        "${runner[@]}" bash "$script" < /dev/null >> "$LOGFILE" 2>&1
    rc=$?
    if [[ $rc -eq 0 ]]; then
        echo "✅ Success: $script" | tee -a "$LOGFILE"
    else
        if [[ $rc -eq 124 || $rc -eq 137 ]]; then
            echo "⚠️ Timeout after ${SCRIPT_TIMEOUT}s: $script (continuing)" | tee -a "$LOGFILE"
        else
            echo "⚠️ Exit code $rc: $script (continuing, check $LOGFILE)" | tee -a "$LOGFILE"
        fi
        FAILED_SCRIPTS+=("$(basename "$script"):$rc")
    fi
    return 0
}

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
        USER_HOME=$(getent passwd "${SUDO_USER:-root}" | cut -d: -f6)
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
sysctl -w net.ipv4.conf.all.log_martians=1 >> "$LOGFILE" 2>&1 || true
sysctl -w net.ipv4.conf.default.log_martians=1 >> "$LOGFILE" 2>&1 || true
sysctl -w net.ipv4.conf.all.rp_filter=1 >> "$LOGFILE" 2>&1 || true
sysctl -w net.ipv4.conf.default.rp_filter=1 >> "$LOGFILE" 2>&1 || true
sysctl -w net.ipv4.route.flush=1 >> "$LOGFILE" 2>&1 || true

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
groupadd -f sshusers

add_ssh_user() {
    local user="$1"
    [[ -z "$user" ]] && return 0
    if getent group sshusers | grep -qE "[:,]${user}(,|\$)"; then
        echo "'$user' is already in sshusers."
        return 0
    fi
    echo "Adding user '$user' to sshusers group..."
    if grep -q "^${user}:" /etc/passwd; then
        usermod -aG sshusers "$user"
    else
        echo "User '$user' not found in local passwd, treating as domain user"
        # Append without a leading comma when the member list is empty
        sed -i "/^sshusers:/ { /:\$/ s/\$/${user}/; t; s/\$/,${user}/ }" /etc/group
    fi
}

# The admin account and the user who launched this script are always allowed,
# so the AllowGroups setting below can never lock them out.
add_ssh_user "$ADMIN_USER"
[[ "$CURRENT_USER" != "$ADMIN_USER" ]] && add_ssh_user "$CURRENT_USER"

echo "You may specify additional users to allow remote SSH access."
read -p "Enter comma-separated usernames (or leave blank to skip): " extra_ssh_users
IFS=',' read -ra SSH_USERS <<< "$extra_ssh_users"

if [[ ${#SSH_USERS[@]} -gt 0 && -n "${SSH_USERS[0]// /}" ]]; then
  for user in "${SSH_USERS[@]}"; do
    user=$(echo "$user" | xargs)  # trim whitespace
    add_ssh_user "$user"
  done
else
  echo "No additional users provided."
fi
echo "Additional SSH users provided: ${SSH_USERS[*]}" >> "$LOGFILE"

# -------- Apply Additional Hardening --------
echo "Installing AppArmor, vim, removing FTP client..."
DEBIAN_FRONTEND=noninteractive apt-get install -y apparmor apparmor-utils vim < /dev/null >> "$LOGFILE" 2>&1 || true
DEBIAN_FRONTEND=noninteractive apt-get purge -y ftp < /dev/null >> "$LOGFILE" 2>&1 || true

# -------- Configure SSH --------
if [[ $IS_WSL -eq 0 && -f "/etc/ssh/sshd_config" ]]; then
    SSH_CONFIG="/etc/ssh/sshd_config"
    SSH_BACKUP="${SSH_CONFIG}.pre-hardening.$(date +%Y%m%d-%H%M%S)"
    cp -p "$SSH_CONFIG" "$SSH_BACKUP"
    echo "Updating SSH settings (backup: $SSH_BACKUP)..."
    update_ssh_config() {
        local key="$1"; local value="$2"
        if grep -q "^$key" "$SSH_CONFIG"; then
            sed -i "s|^$key.*|$key $value|" "$SSH_CONFIG"
        else
            echo "$key $value" >> "$SSH_CONFIG"
        fi
    }

    update_ssh_config "AllowGroups" "sshusers"
    update_ssh_config "Banner" "/etc/issue.net"
    update_ssh_config "ClientAliveInterval" "15"
    update_ssh_config "ClientAliveCountMax" "3"
    update_ssh_config "MaxStartups" "10:30:60"

    # Only restart ssh if the new configuration is valid; otherwise roll back
    SSHD_BIN=$(command -v sshd || echo /usr/sbin/sshd)
    mkdir -p /run/sshd
    if "$SSHD_BIN" -t >> "$LOGFILE" 2>&1; then
        for svc in ssh sshd; do
            if systemctl list-unit-files "$svc.service" 2>/dev/null | grep -q "$svc.service"; then
                systemctl restart "$svc.service" && break
            fi
        done
    else
        echo "⚠️ New sshd_config failed validation, restoring $SSH_BACKUP" | tee -a "$LOGFILE"
        cp -p "$SSH_BACKUP" "$SSH_CONFIG"
        FAILED_SCRIPTS+=("sshd_config:validation")
    fi
else
    echo "Skipping SSH configuration, not applicable in WSL or sshd not found."
fi

# -------- Set Root Password --------
if [[ -t 0 ]]; then
    echo "Set root password now:"
    passwd root
else
    echo "No terminal available, skipping root password prompt." | tee -a "$LOGFILE"
fi

# -------- Clean Up --------
echo "Cleaning up script folder..."
rm -rf "$TARGET_DIR"

# -------- Finish --------
echo
echo "========== SUMMARY =========="
if [[ ${#FAILED_SCRIPTS[@]} -eq 0 ]]; then
    echo "All scripts finished with exit code 0." | tee -a "$LOGFILE"
else
    echo "Scripts that returned a non-zero code (review $LOGFILE):" | tee -a "$LOGFILE"
    printf '  %s\n' "${FAILED_SCRIPTS[@]}" | tee -a "$LOGFILE"
fi
echo "*** Base hardening completed. ***" | tee -a "$LOGFILE"
echo "Completed at: $(date)" >> "$LOGFILE"
echo "You may now run the CIS-CAT Assessor tool for scoring."
echo "Logs saved at $LOGFILE"

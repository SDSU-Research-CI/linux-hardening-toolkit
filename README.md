# Linux Hardening Toolkit

This toolkit helps system administrators apply CIS Benchmark-aligned hardening for Ubuntu Linux environments (18.04 to 26.04 LTS, including Kubuntu), with WSL compatibility and automation.

---

## 📦 Folder Structure

```
linux-hardening-toolkit/
├── README.md
├── CHANGELOG.md
├── harden_launcher.sh
├── scripts/
│   ├── gnome2.sh
│   └── [other .sh scripts...]
```

---

## ✅ Supported Ubuntu Versions

* **18.04 LTS**
* **20.04 LTS**
* **22.04 LTS** ✅ tested
* **24.04.3 LTS** ✅ tested
* **26.04.1 LTS** ✅ tested (Kubuntu, v1.2.0)
* **WSL2** ✅ supported (with automatic exclusions)

> v1.2.0 was also run through a clean Ubuntu 22.04 and 24.04 environment to confirm nothing changed for those releases (classic `sudo` rules, SSH setup and group setup behave as before).

> 🔒 Uses CIS Level 1 Workstation guidance by default.

---

## 🔖 Version

Current Version: `v1.2.0`
Released: October 13, 2026
Maintainer: Alison Peterson

---

## 🚀 What's New in v1.2.0

* ✅ Ubuntu 26.04 LTS support: detects `sudo-rs` and skips the `Defaults logfile=` rule it cannot parse
* ✅ A script that returns a non-zero code no longer stops the whole run. Failures are logged and listed in a summary at the end
* ✅ Each script runs detached from the terminal with stdin closed and a time limit (`SCRIPT_TIMEOUT`, default 3600 seconds), so a hidden prompt or a stopped `apt-get` can no longer freeze the launcher
* ✅ The admin account and launching user are added to `sshusers` before `AllowGroups` is applied, and `sshd_config` is validated (with automatic rollback) before ssh restarts
* ✅ `timesync.sh` supports chrony (Ubuntu 26.04) as well as systemd-timesyncd
* ✅ `ciscat-configs.sh` no longer reports a false failure when the umask check finds nothing

---

## 🚀 What's New in v1.1.1

* ✅ Added `-y` to all apt install/remove/upgrade commands to suppress interactive prompts
* ✅ Replaced `ufw enable` with `ufw --force enable` to avoid SSH disruption confirmation
* ✅ Confirmed compatibility with Ubuntu 24.04.3 LTS
* 📁 All scripts remain flattened under `scripts/`
* 🔧 Logs enhanced at `/var/log/hardening.log`

---

## 🆕 Ubuntu 26.04 Notes

Ubuntu 26.04 changed two defaults that older versions of this toolkit did not expect. v1.2.0 handles both automatically:

| Change in 26.04 | What the toolkit does |
|---|---|
| `sudo-rs` replaces classic `sudo` and does not support `Defaults logfile=` | Detected at start. The sudoers `logfile` rule (`testfix.sh`, rule 14/284) is skipped and `Defaults use_pty` is still applied |
| `chrony` replaces `systemd-timesyncd` | `timesync.sh` adds the SDSU NTP servers to chrony. The default Ubuntu sources stay as a backup |

Good to know:

* The SDSU NTP servers answer only on the campus network or VPN. Off campus they show `Reach 0` in `chronyc sources` and chrony keeps using the Ubuntu sources
* `forwarding.sh` and `ipforward.sh` disable IP forwarding, which can break Waydroid or container networking
* The run ends with a **SUMMARY** block. Scripts that returned a non-zero code are listed there, so review `/var/log/hardening.log` for those

---

## ⚙️ How to Use

1. **Clone the Repository**

From any Linux system:

```bash
git clone https://github.com/SDSU-Research-CI/linux-hardening-toolkit.git
cd linux-hardening-toolkit
sudo chmod +x harden_launcher.sh
sudo ./harden_launcher.sh
```

> 📝 Note: No need to manually upload or unzip files, run everything directly from the cloned folder.

2. **Follow the prompts:**

   * Detects user and OS automatically
   * Smart detection of script folder
   * Runs critical scripts in order, then all others
   * Logs each result to `/var/log/hardening.log`

3. **Review Logs & Reboot if Needed**

---

## 🛠 Post-Run Checklist

* ✅ Review `/etc/ssh/sshd_config`
* ✅ Run CIS-CAT Assessor for scoring
* ✅ Apply kernel upgrades (if prompted)
* ✅ Reboot to apply new modules and microcode

---

## 📬 Contributions

Please coordinate through the Linux Working Group if you'd like to extend this for:

* CIS Level 2 or STIG compliance
* Server profile customization
* Cloud-init or remote automation

---

© San Diego State University · College of Sciences · 2026

Maintained by: Alison Peterson

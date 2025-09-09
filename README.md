# Linux Hardening Toolkit

This toolkit helps system administrators apply CIS Benchmark-aligned hardening for Ubuntu Linux environments (18.04–24.04 LTS), with WSL compatibility and automation.

---

## 📦 Folder Structure

```
linux-hardening-toolkit/
├── README.md
├── VERSION
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
* **WSL2** ✅ supported (with automatic exclusions)

> 🔒 Uses CIS Level 1 Workstation guidance by default.

---

## 🔖 Version

Current Version: `v1.1.1`
Released: July 2, 2025
Maintainer: Alison Peterson

---

## 🚀 What's New in v1.1.1

* ✅ Added `-y` to all apt install/remove/upgrade commands to suppress interactive prompts
* ✅ Replaced `ufw enable` with `ufw --force enable` to avoid SSH disruption confirmation
* ✅ Confirmed compatibility with Ubuntu 24.04.3 LTS
* 📁 All scripts remain flattened under `scripts/`
* 🔧 Logs enhanced at `/var/log/hardening.log`

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

> 📝 Note: No need to manually upload or unzip files — run everything directly from the cloned folder.

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

© San Diego State University · College of Science · 2025

Maintained by: Alison Peterson

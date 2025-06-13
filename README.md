# Linux Hardening Toolkit

This toolkit helps system administrators apply CIS Benchmark-aligned hardening for Ubuntu Linux environments (18.04–24.04 LTS), with WSL compatibility and automation.

---

## 📦 Folder Structure

```
Linux Hardening Toolkit/
├── README.md
├── harden_launcher.sh             # Main entry point
├── scripts/                       # All .sh files copied from 22.04 & More Scripts folders
├── CIS_Ubuntu_Linux_24.04_LTS_Benchmark_v1.0.0.pdfs
```

---

## ✅ Supported Ubuntu Versions

* **18.04 LTS**
* **20.04 LTS**
* **22.04 LTS** ✅ tested
* **24.04 LTS** ✅ target
* **WSL2** ✅ supported (with automatic exclusions)

> 🔒 Uses CIS Level 1 Workstation guidance by default.

---

## ⚙️ How to Use

1. **Upload to Server**
   Copy the `Linux Hardening Toolkit` folder to your server (via SCP, rsync, USB, etc).

2. **Open a Terminal and run:**

cd "Linux Hardening Toolkit"
sudo chmod +x harden_launcher.sh
sudo ./harden_launcher.sh


3. **Follow the prompts:**

   * It will detect the user and OS type
   * Add users to the `sshusers` group
   * Recursively run all `*.sh` scripts
   * Skip unsupported modules in WSL
   * Set root password
   * Clean up `/home/scripts` after completion

4. **Review Logs**
   Output is saved to:

   /var/log/hardening.log

---

## 🛠 Post-Run Checklist

* ✅ Review `/etc/ssh/sshd_config`
* ✅ Run CIS-CAT Assessor tool for compliance score
* ✅ Create backup snapshot (if applicable)

---

## 🧩 Notes

* Make sure all `.sh` files from `scripts/` and `More Scripts/` are moved into the single `scripts/` folder.
* The script avoids executing itself by checking real paths.
* Designed for minimal input and clean exit.

---

## 🔖 Version

Current Version: `v1.0.0`
Released: June 13, 2025
Maintainer: Alison Peterson

---

## 📬 Contributions

If you'd like to extend this for:

* Server profiles
* Level 2 benchmarks
* Cloud-init compatibility

Reach out to your college IT lead or the Linux Working Group.

---

© San Diego State University · College of Science · 2025

Maintained by: Alison Peterson

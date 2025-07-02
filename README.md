# Linux Hardening Toolkit

This toolkit helps system administrators apply CIS Benchmark-aligned hardening for Ubuntu Linux environments (18.04–24.04 LTS), with WSL compatibility and automation.

---

## 📦 Folder Structure

```
linux-hardening-toolkit/
├── README.md
├── VERSION
├── harden_launcher.sh
├── scripts/
│   ├── gnome2.sh
│   └── [other .sh scripts...]
```

---

## ✅ Supported Ubuntu Versions

- **18.04 LTS**
- **20.04 LTS**
- **22.04 LTS** ✅ tested
- **24.04 LTS** ✅ target
- **WSL2** ✅ supported (with automatic exclusions)

> 🔒 Uses CIS Level 1 Workstation guidance by default.

---

## 🔖 Version

Current Version: `v1.1.0`\
Released: July 2, 2025\
Maintainer: Alison Peterson

---

## 🚀 What's New in v1.1.0

- 🚫 Removed legacy `go.sh`
- ✅ Added logging to `/var/log/hardening.log` for each script's success/failure
- 📁 Flattened script structure — all `.sh` files now live in `/scripts/`
- 🧠 Smart script source detection — defaults to launcher’s directory
- 🖥️ Fixed GDM login banner config via `gnome2.sh`
- 🧼 Improved cleanup and handling for domain (AD) users

---

## ⚙️ How to Use

1. **Upload to Server** Copy the `linux-hardening-toolkit` folder to your server (via SCP, rsync, USB, etc).

2. **Open a Terminal and run:**

```bash
cd linux-hardening-toolkit
sudo chmod +x harden_launcher.sh
sudo ./harden_launcher.sh
```

3. **Follow the prompts:**

   - It will detect the user and OS type
   - Add users to the `sshusers` group
   - Runs core scripts in order, then all remaining `.sh` scripts automatically
   - Skip unsupported modules in WSL
   - Set root password
   - Clean up `/home/scripts` after completion

4. **Review Logs** Output is saved to:

   ```
   /var/log/hardening.log
   ```

---

## 🛠 Post-Run Checklist

- ✅ Review `/etc/ssh/sshd_config`
- ✅ Run CIS-CAT Assessor tool for compliance score
- ✅ Create backup snapshot (if applicable)

---

## 🧩 Notes

- Make sure all `.sh` files are placed inside the `scripts/` folder before running.
- The script avoids executing itself by checking real paths.
- Designed for minimal input and clean exit.

---

## 📬 Contributions

If you'd like to extend this for:

- Server profiles
- Level 2 benchmarks
- Cloud-init compatibility

Reach out to your college IT lead or the Linux Working Group.

---

© San Diego State University · College of Science · 2025

Maintained by: Alison Peterson


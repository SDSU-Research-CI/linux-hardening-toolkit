# Changelog

## v1.2.0 - Ubuntu 26.04 Support (October 13, 2026)

- ✅ Added Ubuntu 26.04.1 LTS (Kubuntu) support
- ✅ Detects `sudo-rs` and skips the sudoers `logfile` rule (`testfix.sh`, rule 14/284)
- ✅ Launcher no longer exits on the first non-zero script; failures are collected and summarized
- ✅ Scripts run with `setsid`, stdin from `/dev/null`, noninteractive apt, and a per-script timeout
- ✅ Admin and launching users added to `sshusers` before `AllowGroups`; `sshd -t` validation with rollback before restart
- 🐛 `ciscat-configs.sh`: final umask `grep` no longer causes a false failure
- 🐛 `testfix.sh`: apt calls are noninteractive and no longer read from the terminal
- 🔒 Replaced `eval echo "~$SUDO_USER"` with `getent passwd`

## v1.1.1 – Patch Release (July 2, 2025)

- ✅ Added `-y` to all apt install/remove/purge/upgrade commands to suppress interactive prompts
- ✅ Replaced `ufw enable` with `ufw --force enable` to avoid SSH disruption confirmation
- ✅ Confirmed compatibility with Ubuntu 24.04.3 LTS
- 🐛 Fixed startup issues caused by `apt` and `ufw` prompts blocking automated runs

## v1.1.0 – Initial Public Release (July 2, 2025)

- 🚫 Removed legacy `go.sh`
- ✅ Added logging to `/var/log/hardening.log` with per-script success/failure status
- 📁 Flattened script structure — all `.sh` files now live under `/scripts/`
- 🧠 Smart script source detection — defaults to launcher's directory
- 🖥️ Fixed GDM login banner newline formatting via `gnome2.sh`
- 🧼 Improved cleanup handling and SSH user assignment
- 🔓 Public repo enabled at SDSU Research GitHub Org

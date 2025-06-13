#!/bin/bash

# cis-cat configure additional settings.

#2.2.4 Ensure telnet client is not installed
sudo apt purge telnet

# 3.5.1.3 Ensure ufw service is enabled
sudo ufw allow proto tcp from any to any port 22
sudo ufw enable

#3.5.1.4 Ensure ufw loopback traffic is configured
sudo ufw allow in on lo
sudo ufw allow out on lo
sudo ufw deny in from 127.0.0.0/8
sudo ufw deny in from ::1

#3.5.1.7 Ensure ufw default deny firewall policy
sudo ufw default deny incoming
sudo ufw logging on

#4.2.3 Ensure permissions on all logfiles are configured
sudo find /var/log -type f -exec chmod g-wx,o-rwx "{}" + -o -type d -exec chmod g-w,o-rwx "{}" + 

#5.3.1 Ensure permissions on /etc/ssh/sshd_config are configured
sudo chown root:root /etc/ssh/sshd_config
sudo chmod og-rwx /etc/ssh/sshd_config

#5.4.1 Ensure password creation requirements are configured
sudo apt install libpam-pwquality

#5.5.4 Ensure default user umask is 027 or more restrictive
sudo grep -RPi '(^|^[^#]*)\s*umask\s+([0-7][0-7][01][0-7]\b|[0-7][0-7][0-7][0-6]\b|[0-7][01][0-7]\b|[0-7][0-7][0-6]\b|(u=[rwx]{0,3},)?(g=[rwx]{0,3},)?o=[rwx]+\b|(u=[rwx]{1,3},)?g=[^rx]{1,3}(,o=[rwx]{0,3})?\b)' /etc/login.defs /etc/profile* /etc/bash.bashrc*



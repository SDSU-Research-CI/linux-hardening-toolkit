#!/bin/bash
# Run this script to finisht the configuration of CIS-CAT configurations required below.
# You will need to copy 20-ciscat.conf to /etc/sysctl.d

# CIS-CAT 3.2.1 Ensure packet redirect sending is disabled
sudo sysctl -w net.ipv4.conf.all.send_redirects=0
sudo sysctl -w net.ipv4.conf.default.send_redirects=0
sudo sysctl -w net.ipv4.route.flush=1

# CIS-CAT 3.3.1 Ensure source routed packets are not accepted
sudo sysctl -w net.ipv4.conf.all.accept_source_route=0
sudo sysctl -w net.ipv4.conf.default.accept_source_route=0
sudo sysctl -w net.ipv4.route.flush=1
sudo sysctl -w net.ipv6.conf.all.accept_source_route=0
sudo sysctl -w net.ipv6.conf.default.accept_source_route=0
sudo sysctl -w net.ipv6.route.flush=1 


# CIS-CAT 3.3.2 Ensure ICMP redirects are not accepted
sudo sysctl -w net.ipv4.conf.all.accept_redirects=0
sudo sysctl -w net.ipv4.conf.default.accept_redirects=0
sudo sysctl -w net.ipv4.route.flush=1
sudo sysctl -w net.ipv6.conf.all.accept_redirects=0
sudo sysctl -w net.ipv6.conf.default.accept_redirects=0
sudo sysctl -w net.ipv6.route.flush=1 


# CIS-CAT 3.3.3 Ensure secure ICMP redirects are not accepted
sudo sysctl -w net.ipv4.conf.all.secure_redirects=0
sudo sysctl -w net.ipv4.conf.default.secure_redirects=0
sudo sysctl -w net.ipv4.route.flush=1

# CIS-CAT 3.3.4 Ensure suspicious packets are logged
sudo sysctl -w net.ipv4.conf.all.log_martians=1
sudo sysctl -w net.ipv4.conf.default.log_martians=1
sudo sysctl -w net.ipv4.route.flush=1

# CIS-CAT 3.3.5 Ensure broadcast ICMP requests are ignored
sudo sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1
sudo sysctl -w net.ipv4.conf.all.log_martians=1
sudo sysctl -w net.ipv4.conf.default.log_martians=1
sudo sysctl -w net.ipv4.route.flush=1
sudo sysctl -w net.ipv4.route.flush=1

# CIS-CAT 3.3.6 Ensure bogus ICMP responses are ignored
sudo sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1
sudo sysctl -w net.ipv4.route.flush=1

# CIS-CAT 3.3.7 Ensure Reverse Path Filtering is enabled
sudo sysctl -w net.ipv4.conf.all.rp_filter=1
sudo sysctl -w net.ipv4.conf.default.rp_filter=1
sudo sysctl -w net.ipv4.route.flush=1

# CIS-CAT 3.3.8 Ensure TCP SYN Cookies is enabled
sudo sysctl -w net.ipv4.tcp_syncookies=1
sudo sysctl -w net.ipv4.route.flush=1

# CIS-CAT 3.3.9 Ensure IPv6 router advertisements are not accepted
sudo sysctl -w net.ipv6.conf.all.accept_ra=0
sudo sysctl -w net.ipv6.conf.default.accept_ra=0
sudo sysctl -w net.ipv6.route.flush=1



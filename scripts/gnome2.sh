#!/usr/bin/env bash

{
  l_pkgoutput=""

  if command -v dpkg-query > /dev/null 2>&1; then
    l_pq="dpkg-query -W"
  elif command -v rpm > /dev/null 2>&1; then
    l_pq="rpm -q"
  fi

  l_pcl="gdm gdm3" # Space-separated list of packages to check

  for l_pn in $l_pcl; do
    $l_pq "$l_pn" > /dev/null 2>&1 && l_pkgoutput="$l_pkgoutput\n - Package: \"$l_pn\" exists on the system\n - checking configuration"
  done

  if [ -n "$l_pkgoutput" ]; then
    l_gdmprofile="gdm" # Set this to desired profile name IaW Local site policy
    l_bmessage="'This system is provided by San Diego State University for the use of authorized users only. Individuals using this computer system without authority, or in violation of state or federal laws, are subject to having their activities monitored by law enforcement officials.'" # Set to desired banner message

    if [ ! -f "/etc/dconf/profile/$l_gdmprofile" ]; then
      echo "Creating profile \"$l_gdmprofile\""
      echo "user-db:user\nsystem-db:$l_gdmprofile\nfile-db:/usr/share/$l_gdmprofile/greeter-dconf-defaults" > /etc/dconf/profile/$l_gdmprofile
    fi

    if [ ! -d "/etc/dconf/db/$l_gdmprofile.d/" ]; then
      echo "Creating dconf database directory \"/etc/dconf/db/$l_gdmprofile.d/\""
      mkdir -p /etc/dconf/db/$l_gdmprofile.d/
    fi

    l_kfile="/etc/dconf/db/$l_gdmprofile.d/01-banner-message"

    if [ ! -f "$l_kfile" ]; then
      echo "Creating gdm keyfile for machine-wide settings"
      echo "[org/gnome/login-screen]" > "$l_kfile"
      echo "banner-message-enable=true" >> "$l_kfile"
      echo "banner-message-text=$l_bmessage" >> "$l_kfile"
    else
      ! grep -Pq '^\h*\[org\/gnome\/login-screen\]' "$l_kfile" && sed -ri '/^\s*banner-message-enable/ i\[org/gnome/login-screen]' "$l_kfile"
      ! grep -Pq '^\h*banner-message-enable\h*=\h*true\b' "$l_kfile" && sed -ri 's/^\s*(banner-message-enable\s*=\s*)(\S+)(\s*.*$)/\1true \3/' "$l_kfile"
      ! grep -Piq "^\h*banner-message-text=[\'\"]+\S+" "$l_kfile" && sed -ri "/^\s*banner-message-enable/ a\banner-message-text=$l_bmessage" "$l_kfile"
    fi

    dconf update
  else
    echo -e "\n\n - GNOME Desktop Manager isn't installed\n - Recommendation is Not Applicable\n - No remediation required\n"
  fi
}


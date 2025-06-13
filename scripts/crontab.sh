#!/usr/bin/env bash



{

[ ! -e "/etc/cron.allow" ] && touch /etc/cron.allow

chown root:root /etc/cron.allow

chmod u-x,g-wx,o-rwx /etc/cron.allow

} 

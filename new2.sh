#!/bin/bash
wget -O pihole.sh https://install.pi-hole.net
bash pihole.sh
curl -o /etc/lighttpd/lighttpd.conf https://raw.githubusercontent.com/stirre/hetznerVPS/master/lighttpd.conf
systemctl restart lighttpd
pihole -up

ufw allow proto tcp from 10.6.0.0/24 to 10.6.0.1 port 53 comment 'wg-pihole-dns-tcp'
ufw allow proto udp from 10.6.0.0/24 to 10.6.0.1 port 53 comment 'wg-pihole-dns-udp'
ufw allow proto tcp from 10.6.0.0/24 to 10.6.0.1 port 800 comment 'wg-pihole-admin-http-tcp'
ufw allow 4711/tcp
ufw allow 51820/udp

curl -o /etc/pihole/pihole-FTL.conf https://raw.githubusercontent.com/stirre/hetznerVPS/master/pihole-FTL.conf
sed -i '/^function connectFTL/s/4711/4712/' /var/www/html/admin/scripts/pi-hole/php/FTL.php

systemctl stop systemd-resolved
systemctl disable systemd-resolved
ufw enable
pihole -a -p

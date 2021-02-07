#!/bin/bash
apt update
apt dist-upgrade -y
apt autoremove -y
curl -o /etc/ssh/sshd_config https://raw.githubusercontent.com/stirre/hetznerVPS/master/sshd_config
service ssh restart
curl -L https://install.pivpn.io > pivpn.sh
sudo bash pivpn.sh
curl -o /etc/dnscrypt-proxy/dnscrypt-proxy.toml https://raw.githubusercontent.com/stirre/hetznerVPS/master/dnscrypt-proxy.toml
curl -o /etc/systemd/system/dnscrypt-proxy.socket https://raw.githubusercontent.com/stirre/hetznerVPS/master/dnscrypt-proxy.socket
systemctl restart dnscrypt-proxy.socket
systemctl restart dnscrypt-proxy

curl -L https://install.pivpn.io > pivpn.sh
sudo bash pivpn.sh

wget -O pihole.sh https://install.pi-hole.net
bash pihole.sh
curl -o /etc/lighttpd/lighttpd.conf https://raw.githubusercontent.com/stirre/hetznerVPS/master/lighttpd.conf
systemctl restart lighttpd
pi-hole -up

ufw allow proto tcp from 10.6.0.0/24 to 10.6.0.1 port 53 comment 'wg-pihole-dns-tcp'
ufw allow proto udp from 10.6.0.0/24 to 10.6.0.1 port 53 comment 'wg-pihole-dns-udp'
ufw allow proto tcp from 10.6.0.0/24 to 10.6.0.1 port 800 comment 'wg-pihole-admin-http-tcp'
ufw allow 4711/tcp

curl -o /etc/pihole/pihole-FTL.conf https://raw.githubusercontent.com/stirre/hetznerVPS/master/pihole-FTL.conf
sed -i '/^function connectFTL/s/4711/4712/' /var/www/html/admin/scripts/pi-hole/php/FTL.php

systemctl stop systemd-resolved
systemctl disable systemd-resolved

#!/bin/bash
wget -O pihole.sh https://install.pi-hole.net
bash pihole.sh
pihole -up

ufw allow proto tcp from 10.6.0.0/24 to 10.6.0.1 port 53 comment 'wg-pihole-dns-tcp'
ufw allow proto udp from 10.6.0.0/24 to 10.6.0.1 port 53 comment 'wg-pihole-dns-udp'
ufw allow proto tcp from 10.6.0.0/24 to 10.6.0.1 port 800 comment 'wg-pihole-admin-http-tcp'
ufw allow proto tcp from 2a01:4f8:c2c:a67b::/64 to 2a01:4f8:c2c:a67b::/64 port 53 comment 'wg-pihole-dns-tcp'
ufw allow proto udp from 2a01:4f8:c2c:a67b::/64 to 2a01:4f8:c2c:a67b::/64 port 53 comment 'wg-pihole-dns-udp'
ufw allow proto tcp from 2a01:4f8:c2c:a67b::/64 to 2a01:4f8:c2c:a67b::/64 port 800 comment 'wg-pihole-admin-http-tcp'

curl -o /etc/pihole/pihole-FTL.conf https://raw.githubusercontent.com/stirre/hetznerVPS/master/pihole-FTL.conf
sed -i '/^function connectFTL/s/4711/4712/' /var/www/html/admin/scripts/pi-hole/php/FTL.php

sudo sed -i s/"DEFAULT_FORWARD_POLICY=\"DROP"/"DEFAULT_FORWARD_POLICY=\"ACCEPT"/ /etc/default/ufw
sudo sed -i s/"#net\/ipv4\/ip_forward"/"net\/ipv4\/ip_forward"/ /etc/ufw/sysctl.conf
sudo sed -i s/"#net\/ipv6\/conf\/default\/forwarding"/"net\/ipv6\/conf\/default\/forwarding"/ /etc/ufw/sysctl.conf
sudo sed -i s/"#net\/ipv6\/conf\/all\/forwarding"/"net\/ipv6\/conf\/all\/forwarding"/ /etc/ufw/sysctl.conf
sudo sed -i s/"#net.ipv4.ip_forward=1"/"net.ipv4.ip_forward=1"/ /etc/default/ufw
sudo sed -i s/"#net.ipv6.conf.all.forwarding=1"/"net.ipv6.conf.all.forwarding=1"/ /etc/default/ufw

systemctl stop systemd-resolved
systemctl disable systemd-resolved
ufw enable
pihole -a -p

ufw route allow in on wg0 out on eth0

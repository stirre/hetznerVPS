#!/bin/bash
apt update
apt dist-upgrade -y
apt autoremove -y
sed -i "s/#Port 22/Port 9471/" /etc/ssh/sshd_config
sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
service ssh restart
apt install dnscrypt-proxy -y
mv /etc/dnscrypt-proxy/dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml.backup
curl -o /etc/dnscrypt-proxy/dnscrypt-proxy.toml https://raw.githubusercontent.com/stirre/hetznerVPS/master/dnscrypt-proxy.toml
curl -o /lib/systemd/system/dnscrypt-proxy.socket https://raw.githubusercontent.com/stirre/hetznerVPS/master/dnscrypt-proxy.socket
systemctl restart dnscrypt-proxy.socket
systemctl restart dnscrypt-proxy

ufw allow 9471/tcp
ufw allow 4711/tcp
ufw allow 51800/udp
ufw enable

curl -L https://install.pivpn.io > pivpn.sh
sudo bash pivpn.sh


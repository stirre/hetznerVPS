#!/bin/bash
clear
echo " ##############################################################################"
echo " # Wireguard-DNScrypt-VPN-Server setup script for Ubuntu 18.04 and above      #"
echo " # My base_setup script is needed to install, if not installed this script    #"
echo " # will automatically download the script, but you need to run this manualy   #"
echo " # More information: https://github.com/zzzkeil/Wireguard-DNScrypt-VPN-Server #"
echo " ##############################################################################"
echo " ##############################################################################"
echo " # Version 1 - status: update dnscrypt 2.0.45 with blocked_names etc #"
echo " ##############################################################################"
echo ""
echo ""
echo ""
echo "To EXIT this script press  [ENTER]"
echo 
read -p "To RUN this script press  [Y]" -n 1 -r
echo
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi
#
### root check
if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit 1
fi
#
### OS version check
if [[ -e /etc/debian_version ]]; then
      echo "Debian Distribution"
      else
      echo "This is not a Debian Distribution."
      exit 1
fi
#
### create backupfolder for original files
mkdir /root/script_backupfiles/
#
### wireguard port stettings
echo " Make your port settings now:"
echo "------------------------------------------------------------"
read -p "Choose your Wireguard Port: " -e -i 51820 wg0port
echo "------------------------------------------------------------"

if [[ "$VERSION_ID" = 'VERSION_ID="18.04"' ]]; then
    add-apt-repository ppa:wireguard/wireguard
fi

if [[ "$VERSION_ID" = 'VERSION_ID="20.04"' ]]; then
    echo " system is ubuntu 20.04 - no ppa:wireguard needed "
fi

apt update && apt dist-upgrade -y && apt autoremove -y

apt install qrencode python curl
#
### setup ufw and sysctl
inet=$(ip route show default | awk '/default/ {print $5}')
cp /etc/default/ufw /root/script_backupfiles/ufw.orig
cp /etc/ufw/before.rules /root/script_backupfiles/before.rules.orig
cp /etc/ufw/before6.rules /root/script_backupfiles/before6.rules.orig
sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
cp /etc/sysctl.conf /root/script_backupfiles/sysctl.conf.orig
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sed -i 's/#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=1/g' /etc/sysctl.conf
cp /etc/ufw/sysctl.conf /root/script_backupfiles/sysctl.conf.ufw.orig
sed -i 's@#net/ipv4/ip_forward=1@net/ipv4/ip_forward=1@g' /etc/ufw/sysctl.conf
sed -i 's@#net/ipv6/conf/default/forwarding=1@net/ipv6/conf/default/forwarding=1@g' /etc/ufw/sysctl.conf
sed -i 's@#net/ipv6/conf/all/forwarding=1@net/ipv6/conf/all/forwarding=1@g' /etc/ufw/sysctl.conf
#


###setup DNSCrypt
mkdir /etc/dnscrypt-proxy/
wget -O /etc/dnscrypt-proxy/dnscrypt-proxy.tar.gz https://github.com/jedisct1/dnscrypt-proxy/releases/download/2.0.45/dnscrypt-proxy-linux_x86_64-2.0.45.tar.gz
tar -xvzf /etc/dnscrypt-proxy/dnscrypt-proxy.tar.gz -C /etc/dnscrypt-proxy/
mv -f /etc/dnscrypt-proxy/linux-x86_64/* /etc/dnscrypt-proxy/
cp /etc/dnscrypt-proxy/example-blocked-names.txt /etc/dnscrypt-proxy/blocklist.txt 
curl -o /etc/dnscrypt-proxy/dnscrypt-proxy.toml https://raw.githubusercontent.com/zzzkeil/Wireguard-DNScrypt-VPN-Server/master/configs/dnscrypt-proxy.toml
curl -o /etc/dnscrypt-proxy/dnscrypt-proxy-update.sh https://raw.githubusercontent.com/zzzkeil/Wireguard-DNScrypt-VPN-Server/master/configs/dnscrypt-proxy-update.sh
chmod +x /etc/dnscrypt-proxy/dnscrypt-proxy-update.sh
#
### setup blocklist and a allowlist from (anudeepND)"
mkdir /etc/dnscrypt-proxy/utils/
mkdir /etc/dnscrypt-proxy/utils/generate-domains-blocklists/
curl -o /etc/dnscrypt-proxy/utils/generate-domains-blocklists/domains-blocklist.conf https://raw.githubusercontent.com/zzzkeil/Wireguard-DNScrypt-VPN-Server/master/blocklist/domains-blocklist-default.conf
curl -o /etc/dnscrypt-proxy/utils/generate-domains-blocklists/domains-blocklist-local-additions.txt https://raw.githubusercontent.com/jedisct1/dnscrypt-proxy/master/utils/generate-domains-blocklist/domains-blocklist-local-additions.txt
curl -o /etc/dnscrypt-proxy/utils/generate-domains-blocklists/domains-time-restricted.txt https://raw.githubusercontent.com/jedisct1/dnscrypt-proxy/master/utils/generate-domains-blocklist/domains-time-restricted.txt
curl -o /etc/dnscrypt-proxy/utils/generate-domains-blocklists/domains-allowlist.txt https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/whitelist.txt
# old curl -o /etc/dnscrypt-proxy/utils/generate-domains-blacklists/generate-domains-blacklist.py https://raw.githubusercontent.com/jedisct1/dnscrypt-proxy/master/utils/generate-domains-blacklists/generate-domains-blacklist.py
curl -o /etc/dnscrypt-proxy/utils/generate-domains-blocklists/generate-domains-blocklist.py https://raw.githubusercontent.com/DNSCrypt/dnscrypt-proxy/master/utils/generate-domains-blocklist/generate-domains-blocklist.py
chmod +x /etc/dnscrypt-proxy/utils/generate-domains-blocklists/generate-domains-blocklist.py
cd /etc/dnscrypt-proxy/utils/generate-domains-blocklists/
./generate-domains-blocklist.py > /etc/dnscrypt-proxy/blocklist.txt
cd
## check if generate blocklist failed - file is empty
curl -o /etc/dnscrypt-proxy/checkblocklist.sh https://raw.githubusercontent.com/zzzkeil/Wireguard-DNScrypt-VPN-Server/master/configs/checkblocklist.sh
chmod +x /etc/dnscrypt-proxy/checkblocklist.sh
#
### create crontabs
(crontab -l ; echo "50 23 * * 4 cd /etc/dnscrypt-proxy/utils/generate-domains-blocklists/ &&  ./generate-domains-blocklist.py > /etc/dnscrypt-proxy/blocklists.txt") | sort - | uniq - | crontab -
(crontab -l ; echo "40 23 * * 4 curl -o /etc/dnscrypt-proxy/utils/generate-domains-blocklists/domains-allowlist.txt https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/whitelist.txt") | sort - | uniq - | crontab -
(crontab -l ; echo "30 23 * * 4 curl -o /etc/dnscrypt-proxy/utils/generate-domains-blocklists/domains-blocklist.conf https://raw.githubusercontent.com/zzzkeil/Wireguard-DNScrypt-VPN-Server/master/blocklist/domains-blocklist-default.conf") | sort - | uniq - | crontab -
(crontab -l ; echo "15 * * * 5 cd /etc/dnscrypt-proxy/ &&  ./etc/dnscrypt-proxy/checkblocklist.sh") | sort - | uniq - | crontab -
(crontab -l ; echo "59 23 * * 4,5 /bin/systemctl restart dnscrypt-proxy.service") | sort - | uniq - | crontab -
(crontab -l ; echo "59 23 * * 6 /etc/dnscrypt-proxy/dnscrypt-proxy-update.sh") | sort - | uniq - | crontab -
#
### setup systemctl
systemctl stop systemd-resolved
systemctl disable systemd-resolved
cp /etc/resolv.conf /etc/resolv.conf.orig
rm -f /etc/resolv.conf
systemctl enable unbound
systemctl enable wg-quick@wg0.service
systemctl start wg-quick@wg0.service
cp /etc/systemd/system/multi-user.target.wants/unbound.service /root/script_backupfiles/unbound.service.orig
systemctl disable unbound
curl -o /lib/systemd/system/unbound.service https://raw.githubusercontent.com/zzzkeil/Wireguard-DNScrypt-VPN-Server/master/configs/unbound.service
systemctl enable unbound
/etc/dnscrypt-proxy/dnscrypt-proxy -service install
/etc/dnscrypt-proxy/dnscrypt-proxy -service start
systemctl restart unbound
#
### set file for install check and tools download"
echo "
+++ do not delete this file +++
Instructions coming soon 
For - News / Updates / Issues - check my github site
https://github.com/zzzkeil/Wireguard-DNScrypt-VPN-Server
" > /root/Wireguard-DNScrypt-VPN-Server.README
curl -o add_client.sh https://raw.githubusercontent.com/zzzkeil/Wireguard-DNScrypt-VPN-Server/master/tools/add_client.sh
curl -o remove_client.sh https://raw.githubusercontent.com/zzzkeil/Wireguard-DNScrypt-VPN-Server/master/tools/remove_client.sh
#
### finish
clear
echo ""
echo "QR Code for client1.conf "
qrencode -t ansiutf8 < /etc/wireguard/client1.conf
echo "Scan the QR Code with your Wiregard App"
qrencode -o /etc/wireguard/client1.png < /etc/wireguard/client1.conf
qrencode -o /etc/wireguard/client2.png < /etc/wireguard/client2.conf
qrencode -o /etc/wireguard/client3.png < /etc/wireguard/client3.conf
qrencode -o /etc/wireguard/client4.png < /etc/wireguard/client4.conf
qrencode -o /etc/wireguard/client5.png < /etc/wireguard/client5.conf
echo "4 extra client.conf and QR Codes files in folder : /etc/wireguard/"
echo ""
echo " to add or remove clients run ./add_client.sh or remove_client.sh"
echo ""
ln -s /etc/wireguard/ /root/wireguard_folder
ln -s /etc/dnscrypt-proxy/ /root/dnscrypt-proxy_folder
ln -s /var/log /root/system-log_folder
ufw --force enable
ufw reload

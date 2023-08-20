#!/bin/bash

# Change these to match your requirements
interface="wlan0"
outInterface="eth0"
ssid="test1234"
bssid="AA:BB:CC:DD:12:34"
channel=8
wifiVersion="g"
networkPrefix="192.168.1"
dumpfile="captured.pcap"

printf "Using interface: $interface\n"

# writing configuration file for dnsmasq	
printf "Configuring dnsmasq...\n"
echo "interface=$interface
dhcp-range=$networkPrefix.10,$networkPrefix.100,255.255.255.0,8h
dhcp-option=3,$networkPrefix.1
dhcp-option=6,$networkPrefix.1
server=8.8.8.8
log-queries
log-dhcp" > dnsmasq.conf

# writing config file for hostapd
printf "Configuring hostapd...\n"
echo "interface=$interface
driver=nl80211
ssid=$ssid
bssid=$bssid
hw_mode=$wifiVersion
channel=$channel
macaddr_acl=0
ignore_broadcast_ssid=0" > hostapd.conf

# setting up the interface and routing
printf "Configuring $interface...\n"
printf "Changing $interface IP to $networkPrefix.1\n"
sudo ifconfig $interface "$networkPrefix.1" netmask 255.255.255.0
printf "Adding routing table to route traffic to $networkPrefix.1\n"
sudo route add -net "$networkPrefix.0" netmask 255.255.255.0 gw "$networkPrefix.1"

# enabling ip forwarding
sudo iptables -F
sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo sysctl -w net.ipv4.ip_forward=1

# running dnsmasq in the background
printf "Starting dnsmasq...\n"
sudo dnsmasq -C dnsmasq.conf 

# starting tcpdump for sniffing...
printf "Sniffing with tcpdump on $outInterface..."
sudo tcpdump -i $outInterface -w $dumpfile > /dev/null 2>&1 & 

# running hostapd
printf "Starting hostapd...\n"
sudo hostapd hostapd.conf

# cleanup
printf "Cleaning up...\n"
sudo rm dnsmasq.conf hostapd.conf
sudo route del -net "$networkPrefix.0" netmask 255.255.255.0
sudo pkill dnsmasq
sudo pkill tcpdump
sudo iptables -F

printf "Exiting...\n"

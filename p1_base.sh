#!/bin/bash

# Change these to match your requirements
interface="wlan0"
ssid="test1234"
bssid="AA:BB:CC:DD:12:34"
channel=8
wifiVersion="g"
networkPrefix="192.168.1"

printf "Using interface: $interface\n"

# making sure device exists
ifconfig $interface > /dev/null 2>&1
if [ $? -ne 0 ]; then
	printf "Error: Interface $interface does not exist.\n"
	printf "Exiting...\n"
	exit 1
fi

# writing configuration file for dnsmasq	
printf "Configuring dnsmasq...\n"
echo "interface=$interface
dhcp-range=$networkPrefix.10,$networkPrefix.100,255.255.255.0,8h
dhcp-option=3,$networkPrefix.1
dhcp-option=6,$networkPrefix.1
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
sudo ifconfig $interface up
sudo ifconfig $interface "$networkPrefix.1" netmask 255.255.255.0
printf "Adding routing table to route traffic to $networkPrefix.1\n"
sudo route add -net "$networkPrefix.0" netmask 255.255.255.0 gw "$networkPrefix.1"

# running dnsmasq in the background
printf "Starting dnsmasq...\n"
sudo kill $(sudo lsof -i:53 -t) && sudo dnsmasq -C dnsmasq.conf &

# running hostapd
printf "Starting hostapd...\n"
sudo hostapd hostapd.conf

# cleanup
printf "Cleaning up...\n"
sudo rm dnsmasq.conf hostapd.conf
sudo route del -net "$networkPrefix.0" netmask 255.255.255.0
sudo pkill dnsmasq

printf "Exiting...\n"

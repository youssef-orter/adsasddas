#!/bin/bash

#------ Variables -------#
LOG_FILE="/root/install_log.txt"
> "$LOG_FILE"

#------ Update System -------#
echo -e "\033[1;33m# Run ====> apt update & upgrade \033[0m"
sudo apt update -y && sudo apt upgrade -y >> "$LOG_FILE" 2>&1

#------ Install Packages -------#
echo -e "\033[1;33m# Run ====> Installing Python3, pip, socat, udocker, golang-go \033[0m"
sudo apt install -y python3 python3-pip socat udocker golang-go >> "$LOG_FILE" 2>&1

#------ Setup UDPGW -------#
echo -e "\033[1;33m# Run ====> Cloning and building UDPGW \033[0m"
git clone https://github.com/mukswilly/udpgw.git /opt/udpgw > /dev/null 2>&1
cd /opt/udpgw/cmd || exit
go build -o /usr/local/bin/udpgw-server > /dev/null 2>&1

#------ Create Systemd Service for UDPGW -------#
echo -e "\033[1;33m# Run ====> Creating systemd service for UDPGW \033[0m"
cat <<EOF | sudo tee /etc/systemd/system/udpgw.service > /dev/null
[Unit]
Description=UDPGW Server (All UDP Ports)
After=network.target

[Service]
ExecStart=/usr/local/bin/udpgw-server -port 0 run
WorkingDirectory=/opt/udpgw/cmd
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
EOF

#------ Enable & Start Service -------#
sudo systemctl daemon-reexec
sudo systemctl enable udpgw.service
sudo systemctl start udpgw.service

#------ Kernel Tweaks -------#
echo -e "\033[1;33m# Run ====> Applying sysctl tweaks \033[0m"
cat <<EOF | sudo tee /etc/sysctl.conf > /dev/null
fs.file-max = 512000
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.core.somaxconn = 4000
net.core.netdev_max_backlog = 4000
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_max_orphans = 4000
net.ipv4.ip_forward = 1
EOF
sudo sysctl -p >> "$LOG_FILE" 2>&1

#------ Show Server Info -------#
echo -e "\033[1;32m========== Server Info ==========\033[0m"
IP_ADDRESS=$(curl -s https://ipinfo.io/ip)
COUNTRY_CODE=$(curl -s https://ipinfo.io/country)
echo -e "\033[1;33m• IP Address: $IP_ADDRESS \033[0m"
echo -e "\033[1;33m• Country: $COUNTRY_CODE \033[0m"
echo -e "\033[1;32m=================================\033[0m"
echo -e "\033[1;32m UDPGW is now installed as a service and will auto-start on reboot! \033[0m"

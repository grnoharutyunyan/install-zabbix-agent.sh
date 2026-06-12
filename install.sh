#!/bin/bash

set -e

echo "========================================="
echo "     Zabbix Agent Auto Installer"
echo "========================================="
echo

read -p "Enter Zabbix Server Private IP: " ZABBIX_SERVER_IP
read -p "Enter Hostname for this server: " HOSTNAME_VALUE

echo
echo "[1/5] Installing Zabbix Agent..."
apt update -y
apt install -y zabbix-agent

CONFIG_FILE="/etc/zabbix/zabbix_agentd.conf"

echo
echo "[2/5] Backing up configuration..."
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak.$(date +%Y%m%d_%H%M%S)"

echo
echo "[3/5] Updating configuration..."

# Server

if grep -q "^Server=" "$CONFIG_FILE"; then
sed -i "s|^Server=.*|Server=${ZABBIX_SERVER_IP}|" "$CONFIG_FILE"
else
echo "Server=${ZABBIX_SERVER_IP}" >> "$CONFIG_FILE"
fi

# ServerActive

if grep -q "^ServerActive=" "$CONFIG_FILE"; then
sed -i "s|^ServerActive=.*|ServerActive=${ZABBIX_SERVER_IP}|" "$CONFIG_FILE"
else
echo "ServerActive=${ZABBIX_SERVER_IP}" >> "$CONFIG_FILE"
fi

# Remove any existing Hostname entries (commented or active)

sed -i '/^Hostname=/d' "$CONFIG_FILE"

# Add Hostname

echo "Hostname=${HOSTNAME_VALUE}" >> "$CONFIG_FILE"

echo
echo "[4/5] Enabling and restarting agent..."
systemctl enable zabbix-agent
systemctl restart zabbix-agent

echo
echo "[5/5] Validation"
echo "-----------------------------------------"
echo "Server       : $(grep '^Server=' $CONFIG_FILE)"
echo "ServerActive : $(grep '^ServerActive=' $CONFIG_FILE)"
echo "Hostname     : $(grep '^Hostname=' $CONFIG_FILE)"
echo "-----------------------------------------"

echo
echo "Agent status:"
systemctl --no-pager status zabbix-agent | head -15

echo
echo "DONE!"
echo
echo "IMPORTANT:"
echo "Create a host in Zabbix with:"
echo "Host name = ${HOSTNAME_VALUE}"
echo "Agent IP  = $(hostname -I | awk '{print $1}')"
echo "Template  = Linux by Zabbix agent"
echo

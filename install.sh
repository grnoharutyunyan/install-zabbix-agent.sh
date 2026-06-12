#!/bin/bash

set -e

echo "========================================="
echo "     Zabbix Agent Auto Installer"
echo "========================================="
echo

read -p "Enter Zabbix Server Private IP: " ZABBIX_SERVER_IP
read -p "Enter Hostname for this server: " HOSTNAME_VALUE

echo
echo "[1/6] Installing Zabbix Agent..."
apt update -y
apt install -y zabbix-agent

CONFIG_FILE="/etc/zabbix/zabbix_agentd.conf"

echo
echo "[2/6] Backing up configuration..."
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak.$(date +%Y%m%d_%H%M%S)"

echo
echo "[3/6] Updating configuration..."

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

# Remove existing hostname entries

sed -i '/^Hostname=/d' "$CONFIG_FILE"

# Add hostname

echo "Hostname=${HOSTNAME_VALUE}" >> "$CONFIG_FILE"

echo
echo "[4/6] Opening firewall port 10050..."

if command -v ufw >/dev/null 2>&1; then
if ufw status | grep -q "Status: active"; then
ufw allow 10050/tcp
echo "UFW rule added for TCP/10050"
else
echo "UFW installed but not active - skipping firewall rule"
fi
else
echo "UFW not installed - skipping firewall rule"
fi

echo
echo "[5/6] Enabling and restarting agent..."
systemctl enable zabbix-agent
systemctl restart zabbix-agent

echo
echo "[6/6] Validation"
echo "-----------------------------------------"
echo "Server       : $(grep '^Server=' $CONFIG_FILE)"
echo "ServerActive : $(grep '^ServerActive=' $CONFIG_FILE)"
echo "Hostname     : $(grep '^Hostname=' $CONFIG_FILE)"
echo "Agent IP     : $(hostname -I | awk '{print $1}')"
echo "-----------------------------------------"

echo
echo "Listening port:"
ss -tulpn | grep 10050 || true

echo
echo "Agent status:"
systemctl --no-pager status zabbix-agent | head -15

echo
echo "DONE!"
echo
echo "Create host in Zabbix:"
echo "Host name : ${HOSTNAME_VALUE}"
echo "Agent IP  : $(hostname -I | awk '{print $1}')"
echo "Port      : 10050"
echo "Template  : Linux by Zabbix agent"
echo
echo "IMPORTANT:"
echo "Also allow TCP/10050 in your GCP firewall rules if not already allowed."

#!/bin/bash

# Function to validate IP addresses
function validate_ip() {
    local ip=$1
    local valid_ip=$(echo $ip | awk -F'.' '$1 <= 255 && $2 <= 255 && $3 <= 255 && $4 <= 255 {print $0}')
    if [[ -z $valid_ip ]]; then
        echo "Error: Invalid IP address: $ip"
        exit 1
    fi
}

# Default values
DEFAULT_SSID="RpiHotSpot"
DEFAULT_PASSWORD="password"
DEFAULT_HOTSPOT_IP="192.168.50.1"
DEFAULT_DHCP_RANGE_START="192.168.50.2"
DEFAULT_DHCP_RANGE_END="192.168.50.10"
DEFAULT_DHCP_NETMASK="255.255.255.0"

# Input prompts with default values
read -p "Enter the Wi-Fi hotspot SSID [${DEFAULT_SSID}]: " SSID
SSID=${SSID:-$DEFAULT_SSID}
read -s -p "Enter the Wi-Fi hotspot password [${DEFAULT_PASSWORD}]: " PASSWORD
PASSWORD=${PASSWORD:-$DEFAULT_PASSWORD}
echo
read -p "Enter the hotspot IP address (e.g., 192.168.50.1) [${DEFAULT_HOTSPOT_IP}]: " HOTSPOT_IP
HOTSPOT_IP=${HOTSPOT_IP:-$DEFAULT_HOTSPOT_IP}
validate_ip $HOTSPOT_IP
read -p "Enter the DHCP range start (e.g., 192.168.50.2) [${DEFAULT_DHCP_RANGE_START}]: " DHCP_RANGE_START
DHCP_RANGE_START=${DHCP_RANGE_START:-$DEFAULT_DHCP_RANGE_START}
validate_ip $DHCP_RANGE_START
read -p "Enter the DHCP range end (e.g., 192.168.50.20) [${DEFAULT_DHCP_RANGE_END}]: " DHCP_RANGE_END
DHCP_RANGE_END=${DHCP_RANGE_END:-$DEFAULT_DHCP_RANGE_END}
validate_ip $DHCP_RANGE_END
read -p "Enter the DHCP netmask (e.g., 255.255.255.0) [${DEFAULT_DHCP_NETMASK}]: " DHCP_NETMASK
DHCP_NETMASK=${DHCP_NETMASK:-$DEFAULT_DHCP_NETMASK}
validate_ip $DHCP_NETMASK

# Check if NetworkManager is installed
if ! dpkg -s network-manager &>/dev/null; then
    echo "NetworkManager is not installed. Installing..."
    sudo apt update
    if ! sudo apt install -y network-manager uuid-runtime iptables-persistent; then
        echo "Error: Failed to install required packages."
        exit 1
    fi
fi

UUID=$(uuidgen)
if [ $? -ne 0 ]; then
    echo "Error: Failed to generate UUID."
    exit 1
fi

# Configure NetworkManager to manage Wi-Fi
sudo bash -c 'cat << EOF > /etc/NetworkManager/NetworkManager.conf
[main]
plugins=ifupdown,keyfile

[ifupdown]
managed=true
EOF'

# Create the hotspot configuration file
sudo bash -c "cat << EOF > /etc/NetworkManager/system-connections/MyHotspot.nmconnection
[connection]
id=MyHotspot
uuid=$UUID
type=wifi
autoconnect=true

[wifi]
mode=ap
ssid=$SSID

[wifi-security]
key-mgmt=wpa-psk
proto=rsn
pairwise=ccmp
group=ccmp
psk=$PASSWORD

[ipv4]
method=shared
address1=$HOTSPOT_IP/24
dhcp-server=yes

[ipv4-dhcp-server]
dhcp-option=option:router,$HOTSPOT_IP
dhcp-range=$DHCP_RANGE_START,$DHCP_RANGE_END,$DHCP_NETMASK,24h

[ipv6]
method=ignore
EOF"

# Set permissions for the configuration file
sudo chmod 600 /etc/NetworkManager/system-connections/MyHotspot.nmconnection
sudo chown root:root /etc/NetworkManager/system-connections/MyHotspot.nmconnection

# Restart NetworkManager
if ! sudo systemctl restart NetworkManager; then
    echo "Error: Failed to restart NetworkManager."
    exit 1
fi

# Check if the connection was created successfully
if ! nmcli connection load /etc/NetworkManager/system-connections/MyHotspot.nmconnection; then
    echo "Error: Failed to load MyHotspot connection."
    exit 1
fi

# Check device status before activating the hotspot
echo "Device status before activating the hotspot:"
nmcli device status

# Enable the Wi-Fi device
sudo rfkill unblock wifi
sudo ip link set wlan0 up

# Wait a few seconds for changes to take effect
sleep 5

# Check device status after activation
echo "Device status after attempting to activate the Wi-Fi device:"
nmcli device status

# Activate the hotspot
if ! nmcli connection up MyHotspot; then
    echo "Error: Failed to activate the hotspot. Ensure the Wi-Fi device is available and managed by NetworkManager."
    nmcli device status
    exit 1
fi

# Configure NAT and IPv4 forwarding
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    sudo bash -c 'echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf'
    if ! sudo sysctl -p; then
        echo "Error: Failed to configure IPv4 forwarding."
        exit 1
    fi
fi

# Automatically detect the external network interface
EXTERNAL_INTERFACE=$(ip route | grep default | awk '{print $5}')
if [ -z "$EXTERNAL_INTERFACE" ]; then
    echo "Error: Unable to detect external network interface."
    exit 1
fi

# Configure NAT with iptables
sudo iptables -t nat -A POSTROUTING -o "$EXTERNAL_INTERFACE" -j MASQUERADE
if ! sudo sh -c "iptables-save > /etc/iptables/rules.v4"; then
    echo "Error: Failed to save iptables rules."
    exit 1
fi

# Create a systemd unit to restore iptables rules on boot
sudo bash -c 'cat << EOF > /etc/systemd/system/iptables-restore.service
[Unit]
Description=Restore iptables rules
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore < /etc/iptables/rules.v4
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF'

# Reload systemd units and enable the service
sudo systemctl daemon-reload
if ! sudo systemctl enable iptables-restore.service; then
    echo "Error: Failed to enable iptables-restore service."
    exit 1
fi

echo "Wi-Fi hotspot setup complete. The hotspot should be active and persistent across reboots."

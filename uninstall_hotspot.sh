#!/bin/bash

# Function to restore a backup file if it exists
restore_file() {
    local original_file=$1
    local backup_file="${original_file}.backup"

    if [ -f "$backup_file" ]; then
        sudo mv "$backup_file" "$original_file"
        echo "Restored: $original_file"
    else
        echo "No backup found for: $original_file"
    fi
}

# Deactivate and delete the hotspot Wi-Fi connection
if nmcli connection show | grep -q "MyHotspot"; then
    nmcli connection down MyHotspot
    nmcli connection delete MyHotspot
    echo "Deactivated and deleted MyHotspot Wi-Fi connection."
else
    echo "No MyHotspot connection found."
fi

# Restore NetworkManager configuration
restore_file "/etc/NetworkManager/NetworkManager.conf"

# Delete the hotspot configuration file
if [ -f "/etc/NetworkManager/system-connections/MyHotspot.nmconnection" ]; then
    sudo rm /etc/NetworkManager/system-connections/MyHotspot.nmconnection
    echo "Deleted: /etc/NetworkManager/system-connections/MyHotspot.nmconnection"
else
    echo "No MyHotspot.nmconnection file found."
fi

# Restore sysctl.conf file
restore_file "/etc/sysctl.conf"
sudo sysctl -p

# Flush iptables rules and delete saved rules
if [ -f "/etc/iptables/rules.v4" ]; then
    sudo iptables -t nat -F
    sudo rm /etc/iptables/rules.v4
    echo "Restored default iptables rules."
else
    echo "No specific iptables rules found."
fi

# Disable and remove the iptables-restore service
if [ -f "/etc/systemd/system/iptables-restore.service" ]; then
    sudo systemctl disable iptables-restore.service
    sudo rm /etc/systemd/system/iptables-restore.service
    sudo systemctl daemon-reload
    echo "Removed and disabled iptables-restore service."
else
    echo "No iptables-restore service found."
fi

echo "System reset complete. The system should be back to its initial state."

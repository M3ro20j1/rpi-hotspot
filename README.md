# rpi-hotspot
## Wi-Fi Hotspot Configuration Script for Raspberry Pi

This project contains a Bash script that configures a Wi-Fi hotspot on a Raspberry Pi using NetworkManager. The script automatically sets up a secure Wi-Fi network with a defined DHCP range and configures NAT routing to allow devices connected to the hotspot to access the internet.

### Features

- **Automatic Wi-Fi Hotspot Configuration**: The script sets up a secure Wi-Fi network with a user-defined SSID and password.
- **Customizable DHCP Range**: Users can define the range of IP addresses assigned to clients via DHCP.
- **NAT Routing**: The script configures NAT to allow devices connected to the hotspot to access the internet.
- **Default Values**: Default values are used if no input is provided by the user.

### Usage

1. **Download the script**:
    ```bash
    wget https://github.com/meditant/rpi-hotspot/raw/main/setup_hotspot.sh
    chmod +x setup_hotspot.sh
    ```
2. **Run the script**:
    ```bash
    sudo ./setup_hotspot.sh
    ```
### Direct download the Uninstallation Script
1. **Link**:
     **Run the script directly from GitHub using `curl`**:
    ```bash
    sudo bash -c "$(curl -fsSL https://github.com/meditant/rpi-hotspot/raw/main/setup_hotspot.sh)"
    ```
   **Run the script directly from GitHub using `wget`**:
    ```bash
    sudo bash -c "$(wget -qO- https://github.com/meditant/rpi-hotspot/raw/main/setup_hotspot.sh)"
    ```

4. **Enter the required information** or simply press Enter to use the default values.

### Default Values

- **SSID**: RpiHotSpot
- **Password**: password
- **Hotspot IP Address**: 192.168.50.1
- **DHCP Range Start**: 192.168.50.2
- **DHCP Range End**: 192.168.50.10
- **DHCP Netmask**: 255.255.255.0

### Uninstallation Script

To revert to the initial state and remove the configurations created by the setup script, you can use the following uninstallation script:

### Using the Uninstallation Script

1. **Download the uninstallation script**:
    ```bash
    wget https://github.com/meditant/rpi-hotspot/raw/main/uninstall_hotspot.sh
    chmod +x uninstall_hotspot.sh
    ```
2. **Run the uninstallation script**:
    ```bash
    sudo ./uninstall_hotspot.sh
    ```
### Direct download the Uninstallation Script

1. **Run the uninstallation script**:
       
   **Run the script directly from GitHub using `curl`**:
    ```bash
    sudo bash -c "$(curl -fsSL https://github.com/your-username/your-repo/raw/main/uninstall_hotspot.sh)
    ```
   **Run the script directly from GitHub using `wget`**:
    ```bash
    sudo bash -c "$(wget -qO- https://github.com/your-username/your-repo/raw/main/uninstall_hotspot.sh)
    ```

This script will reset your system to its initial state, except for the installed packages, which will remain.

### Notes

- **Administrative privileges**: Both scripts require administrative privileges to make system changes.
- **Tested on Raspberry Pi**: These scripts are specifically designed and tested to work on a Raspberry Pi using NetworkManager.


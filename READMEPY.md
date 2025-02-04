# MAC Manager

**MAC Manager** is a lightweight Python script for managing your network interface’s MAC address. It provides functionality to:
- **Backup** your current (original) MAC address,
- **Restore** the original MAC address,
- **Change** to a user-specified MAC address (with input validation), and
- **Assign** a randomly generated MAC address (ensuring it is locally administered),
- **Scan** your local network to list connected devices with their MAC addresses and vendor details.

---

## Features

- **Backup/Restore:** Saves the current MAC address to a backup file (unique per interface) and restores it on demand.
- **Random MAC Generation:** Generates a valid random MAC address with the locally administered bit set.
- **Custom MAC Change:** Validates user input (using a regular expression) before applying a new MAC address.
- **Network Scan:** Scans the local network to display IP addresses, MAC addresses, and vendor information.
- **Robust Error Handling:** Checks for correct arguments, verifies the network interface’s existence, and confirms that all dependencies are installed.

---

## Dependencies

The script depends on the following:
- **Python V3**

### Installation on VS Code

**Install Python**

### Installation

    Clone this repository (or download the script file):

    git clone https://github.com/yourusername/mac-manager.git

### Change directory into the repository:

    cd mac-manager

### Make the script executable:

    chmod +x mac_manager.sh

### Usage

    Run the script with the following syntax:

    sudo ./mac_manager.sh <command> <interface> [<new_mac>]

    Where <command> can be:

    backup - Save the current MAC address to a backup file.
    restore - Restore the MAC address from the backup.
    random - Generate and assign a random MAC address.
    change - Change to a user-specified MAC address (requires <new_mac>).
    scan - Scan the local network for devices and display their MAC addresses with vendor info.

### Examples

    Backup the current MAC:

    python3 mac_manager.sh backup eth0

    Change to a random MAC:

    python3 mac_manager.sh random eth0

    Change to a specific MAC:

    python3 mac_manager.sh change eth0 00:11:22:33:44:55

    Restore the original MAC:

    python3 mac_manager.sh restore eth0

    Scan the local network:

    python3 mac_manager.sh scan eth0

### Error Handling and Validation

    The script implements several checks to ensure robust operation:

    Argument Validation:
    It checks for the correct number of command-line arguments and displays a usage message if insufficient arguments are provided.

    Interface Verification:
    The script verifies that the provided network interface exists using ip link show.

    MAC Address Format Validation:
    For the change command, the script validates the provided MAC address using a regular expression. It accepts only the formats XX:XX:XX:XX:XX:XX or XX-XX-XX-XX-XX-XX.

    Dependency Checks:
    The scan function checks if arp-scan is installed and exits with an error message if it is missing.

    Command Execution:
    Each critical step (e.g., bringing the interface down, setting the MAC address, bringing it up) is checked for errors, and appropriate error messages are displayed if any step fails.

### Common Troubleshooting Tips

    Check Interface Name:
    Verify your network interface exists with:

    ip link show

    Use the correct interface name (e.g., eth0, wlan0, enp3s31f6).

### Install Dependencies:
    Ensure all dependencies (iproute2, arp-scan) are installed. If the scan command fails, verify installation with:

    sudo apt install arp-scan

### Verify Changes:
    After executing a change, use the command:

    ip link show <interface>

    to verify that the MAC address has been updated.

Persistent Changes:
Note that changes made using this script are temporary. A reboot will revert to the original hardware MAC address unless additional configuration is used to make changes persistent.










[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/tp86o73G)
[![Open in Codespaces](https://classroom.github.com/assets/launch-codespace-2972f46106e565e64193e422d61a12cf1da4916b45550586e14ef0a7c637dd04.svg)](https://classroom.github.com/open-in-codespaces?assignment_repo_id=17802277)

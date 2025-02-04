#!/bin/bash

# Function to validate MAC address format
validate_mac() {
    local mac="$1"
    # Remove any non-alphanumeric characters and convert to uppercase
    local cleaned_mac=$(echo "$mac" | tr -d ':- ' | tr '[:lower:]' '[:upper:]')
    # Check if the cleaned MAC matches the expected format
    if [[ "$cleaned_mac" =~ ^([0-9A-F]{2}){5}[0-9A-F]{2}$ ]]; then
        echo "$cleaned_mac"
        return 0
    else
        echo "Invalid MAC address: $mac" >&2
        return 1
    fi
}

# Function to set a new MAC address
set_mac_address() {
    local interface="$1"
    local new_mac="$2"

    # Check if the interface exists
    if ! ip link show "$interface" &>/dev/null; then
        echo "Error: Network interface $interface does not exist." >&2
        return 1
    fi

    # Bring the interface down
    if ! ip link set dev "$interface" down; then
        echo "Error: Failed to bring $interface down." >&2
        return 1
    fi

    # Set the new MAC address
    if ! ip link set dev "$interface" address "$new_mac"; then
        echo "Error: Failed to set MAC address on $interface." >&2
        ip link set dev "$interface" up &>/dev/null # Attempt to bring interface back up
        return 1
    fi

    # Bring the interface up
    if ! ip link set dev "$interface" up; then
        echo "Error: Failed to bring $interface up." >&2
        return 1
    fi

    echo "Successfully set MAC address of $interface to $new_mac."
}

# Function to scan the network
scan_network() {
    echo "Scanning network for devices..."
    if ! command -v arp-scan &>/dev/null; then
        echo "Error: arp-scan is not installed. Install it with 'sudo apt-get install arp-scan'." >&2
        return 1
    fi

    # Run arp-scan and display results
    sudo arp-scan -l | awk '/^[0-9]/{print $1, $2}'
}

# Main script logic
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <interface> <new-mac> | scan"
    echo "Examples:"
    echo "  Set MAC address: $0 eth0 00:11:22:33:44:55"
    echo "  Scan network:    $0 scan"
    exit 1
fi

if [[ "$1" == "scan" ]]; then
    scan_network
    exit 0
fi

# Validate arguments
if [[ $# -ne 2 ]]; then
    echo "Error: Invalid number of arguments." >&2
    echo "Usage: $0 <interface> <new-mac>" >&2
    exit 1
fi

interface="$1"
new_mac="$2"

# Validate MAC address
valid_mac=$(validate_mac "$new_mac") || exit 1

# Set the new MAC address
set_mac_address "$interface" "$valid_mac"
#!/bin/bash
set -euo pipefail

# Directory and file used for backing up the original MAC address.
BACKUP_DIR="/tmp"
usage() {
    echo "Usage: $0 {backup|restore|random|change|scan} <interface> [<new_mac>]"
    echo
    echo "Commands:"
    echo "  backup   - Save the current MAC address of the interface."
    echo "  restore  - Restore the MAC address from backup."
    echo "  random   - Generate a random MAC address and assign it."
    echo "  change   - Change the MAC address to the provided <new_mac>."
    echo "  scan     - Scan the local network for MAC addresses and vendor info."
    exit 1
}

# Verify argument count.
if [[ $# -lt 2 ]]; then
    echo "Error: Not enough arguments."
    usage
fi

command="$1"
iface="$2"
backup_file="${BACKUP_DIR}/mac_backup_${iface}.txt"

# Verify that the network interface exists.
if ! ip link show "$iface" > /dev/null 2>&1; then
    echo "Error: Network interface '$iface' not found."
    exit 1
fi

# Function: Validate MAC address format (accepts either colon or hyphen as separator).
validate_mac() {
    local mac="$1"
    local mac_regex='^([0-9A-Fa-f]{2}([:-])){5}[0-9A-Fa-f]{2}$'
    if [[ "$mac" =~ $mac_regex ]]; then
        return 0
    else
        echo "Error: Invalid MAC address format. Expected format: XX:XX:XX:XX:XX:XX or XX-XX-XX-XX-XX-XX."
        return 1
    fi
}

# Function: Backup the current MAC address.
backup_mac() {
    local current_mac
    current_mac=$(ip link show "$iface" | awk '/link\/ether/ {print $2}')
    if [[ -z "$current_mac" ]]; then
        echo "Error: Could not retrieve current MAC address."
        exit 1
    fi
    echo "$current_mac" > "$backup_file"
    echo "Backup: Original MAC address for '$iface' ($current_mac) saved to $backup_file."
}

# Function: Restore the MAC address from backup.
restore_mac() {
    if [[ ! -f "$backup_file" ]]; then
        echo "Error: No backup found for interface '$iface'."
        exit 1
    fi
    local original_mac
    original_mac=$(cat "$backup_file")
    echo "Restoring MAC address for '$iface' to $original_mac..."
    sudo ip link set dev "$iface" down
    sudo ip link set dev "$iface" address "$original_mac"
    sudo ip link set dev "$iface" up
    echo "Restore: MAC address for '$iface' is now $original_mac."
}

# Function: Generate a random MAC address.
# The first octet is fixed to "02" to indicate a locally administered address.
generate_random_mac() {
    printf '02:%02X:%02X:%02X:%02X:%02X\n' \
        $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256))
}

# Function: Change the MAC address to a specified value.
change_mac() {
    local new_mac="$1"
    validate_mac "$new_mac" || exit 1
    echo "Changing MAC address for '$iface' to $new_mac..."
    sudo ip link set dev "$iface" down || { echo "Error: Could not bring interface down."; exit 1; }
    sudo ip link set dev "$iface" address "$new_mac" || { echo "Error: Could not set new MAC address."; exit 1; }
    sudo ip link set dev "$iface" up || { echo "Error: Could not bring interface up."; exit 1; }
    echo "Change: MAC address for '$iface' successfully changed to $new_mac."
}

# Function: Scan the local network for devices (requires arp-scan).
scan_network() {
    if ! command -v arp-scan > /dev/null 2>&1; then
        echo "Error: 'arp-scan' is not installed. Install it (e.g., sudo apt install arp-scan) to enable network scanning."
        exit 1
    fi
    echo "Scanning local network for MAC addresses and vendors..."
    sudo arp-scan --localnet | awk 'BEGIN {ignore=1} 
        { if(ignore && $0 ~ /Starting arp-scan/) next; 
          if($0 ~ /Ending arp-scan/) exit; 
          if($0 ~ /Interface/) next; 
          if($0 ~ /^--/) next; 
          print $1, $2, substr($0, index($0,$3)) }'
}

# Main command dispatcher.
case "$command" in
    backup)
        backup_mac
        ;;
    restore)
        restore_mac
        ;;
    random)
        new_mac=$(generate_random_mac)
        echo "Generated random MAC address: $new_mac"
        change_mac "$new_mac"
        ;;
    change)
        if [[ $# -ne 3 ]]; then
            echo "Error: 'change' command requires a MAC address as the third argument."
            usage
        fi
        change_mac "$3"
        ;;
    scan)
        scan_network
        ;;
    *)
        echo "Error: Unknown command '$command'."
        usage
        ;;
esac
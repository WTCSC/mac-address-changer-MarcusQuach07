#!/bin/bash

set -e
BACKUP_MAC="/tmp/mac_backup.txt"

validate_mac(){
    local mac="$1"
    if [[ $mac =~ ^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$ ]]; then
        echo "Valid MAC Address"
        return 0
    else
        echo "Error: Invalid MAC Address"
    fi
}

generate_random_mac(){
    local mac=$(printf '02:%02X:%02X:%02X:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))
    echo $mac
}

backup_mac(){
    local iface="$1"
    local current_mac=$(cat /sys/class/net/"$iface"/address)
    echo "$current_mac" > "$BACKUP_MAC"
    echo "Original MAC Address ($current_mac) has been backed up"
}

restore_mac(){
    local iface="$1"
    if [[ -f "$BACKUP_MAC" ]]; then
        local original_mac=$(cat "$BACKUP_MAC")
        sudo ip link set dev "$iface" down
        sudo ip link set dev "$iface" address "$original_mac"
        sudo ip link set dev "$iface" up
        echo "Original MAC Address ($original_mac) has been restored"
    else
        echo "Error: Backup file not found"
    fi
}

change_mac(){
    local iface="$1"
    local new_mac="$2"

    validate_mac "$new_mac" || exit 1

    sudo ip link set dev "$iface" down
    sudo ip link set dev "$iface" address "$new_mac"
    sudo ip link set dev "$iface" up

    echo "MAC Address has been changed to $new_mac"
}

scan_network(){
    echo "Scanning Network..."
    sudo arp-scan --localnet | awk '{print $1, $2, $3}' 2>/dev/null || echo "Error: Install 'arp-scan' to enable scanning functionality."
}

help(){
    echo "Usage: $0 {change|random|backup|restore|scan} [interface] [MAC address]"
    echo
    echo "Commands:"
    echo "  change <interface> <new_mac>    Change the MAC address."
    echo "  random <interface>              Assign a random MAC address."
    echo "  backup <interface>              Back up the original MAC address."
    echo "  restore <interface>             Restore the original MAC address."
    echo "  scan                            Scan the local network for MAC addresses and vendors."
    exit 1
}

if [[ $# -lt 1 ]]; then
    help
fi

case "$1" in
    change)
        if [[ $# -ne 3 ]]; then help; fi
        change_mac "$2" "$3"
        ;;
    random)
        if [[ $# -ne 2 ]]; then help; fi
        new_mac=$(generate_random_mac)
        change_mac "$2" "$new_mac"
        ;;
    backup)
        if [[ $# -ne 2 ]]; then usage; fi
        backup_mac "$2"
        ;;
    restore)
        if [[ $# -ne 2 ]]; then usage; fi
        restore_mac "$2"
        ;;
    scan)
        scan_network
        ;;
    *)
        usage
        ;;
esac

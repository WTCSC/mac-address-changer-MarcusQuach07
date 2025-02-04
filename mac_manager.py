#!/usr/bin/env python3
# Import library
import os
import re
import subprocess
import sys
import random
# Backup file
BACKUP_DIR = "/tmp"
# Variable to validate mac
def validate_mac(mac):
    """Validates MAC address format."""
    # Verifies if mac address matches format
    mac_regex = r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$'
    # if match return true
    if re.match(mac_regex, mac):
        return True
        #if false return error code
    print("Error: Invalid MAC address format. Expected format: XX:XX:XX:XX:XX:XX or XX-XX-XX-XX-XX-XX.")
    return False

def get_current_mac(interface):
    """Gets the current MAC address of a given network interface."""
    try:
        # Will run ip link show to get current mac
        output = subprocess.check_output(["ip", "link", "show", interface]).decode()
        # Will search for link
        mac = re.search(r'link/ether (\S+)', output).group(1)
        # Returns mac
        return mac
        # Error Code
    except Exception as e:
        print(f"Error retrieving MAC address: {e}")
        sys.exit(1)

def backup_mac(interface):
    """Backs up the current MAC address."""
    # Creates backup txt file in directory
    backup_file = f"{BACKUP_DIR}/mac_backup_{interface}.txt"
    # Gets current mac
    current_mac = get_current_mac(interface)
    #Opens file in write mode
    with open(backup_file, "w") as f:
        #Writes current mac
        f.write(current_mac)
        #Prints message
    print(f"Backup: Original MAC address ({current_mac}) saved to {backup_file}.")

def restore_mac(interface):
    """Restores the MAC address from backup."""
    # Opens mac backup file
    backup_file = f"{BACKUP_DIR}/mac_backup_{interface}.txt"
    # if no backup found then exits
    if not os.path.isfile(backup_file):
        print(f"Error: No backup found for interface '{interface}'.")
        sys.exit(1)
    # if found reads it and strips the mac address
    with open(backup_file, "r") as f:
        original_mac = f.read().strip()
    # changes the mac to original mac
    change_mac(interface, original_mac)
    # Prints message
    print(f"Restored MAC address for '{interface}' to {original_mac}.")
# Generate random mac variable
def generate_random_mac():
    """Generates a random MAC address with the first octet set to '02' (locally administered)."""
    # Goes through a random range of 0 - 255, 5 times and gets the sets of octets
    return "02:" + ":".join(f"{random.randint(0, 255):02X}" for _ in range(5))

def change_mac(interface, new_mac):
    """Changes the MAC address of the specified interface."""
    # if its not a valid address it will exit
    if not validate_mac(new_mac):
        sys.exit(1)
    # Prints message
    print(f"Changing MAC address for '{interface}' to {new_mac}...")
    # Takes interface down
    subprocess.run(["sudo", "ip", "link", "set", "dev", interface, "down"], check=True)
    # Changes mac address
    subprocess.run(["sudo", "ip", "link", "set", "dev", interface, "address", new_mac], check=True)
    # Brings network interface back up
    subprocess.run(["sudo", "ip", "link", "set", "dev", interface, "up"], check=True)
    # Prints success
    print(f"Successfully changed MAC address for '{interface}' to {new_mac}.")

def scan_network():
    """Scans the local network for MAC addresses and vendor information."""
    # if it cant scan them it will exit
    if not subprocess.run(["which", "arp-scan"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
        print("Error: 'arp-scan' is not installed. Install it using 'sudo apt install arp-scan'.")
        sys.exit(1)
    
    print("Scanning local network for MAC addresses and vendors...")
    # Runs arp-scan to scan network
    subprocess.run(["sudo", "arp-scan", "--localnet"], check=True)

def main():
    # Help command
    if len(sys.argv) < 3:
        print("Usage: script.py {backup|restore|random|change|scan} <interface> [<new_mac>]")
        sys.exit(1)

    command, interface = sys.argv[1], sys.argv[2]

    if subprocess.run(["ip", "link", "show", interface], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
        print(f"Error: Network interface '{interface}' not found.")
        sys.exit(1)

    if command == "backup":
        backup_mac(interface)
    elif command == "restore":
        restore_mac(interface)
    elif command == "random":
        new_mac = generate_random_mac()
        print(f"Generated random MAC address: {new_mac}")
        change_mac(interface, new_mac)
    elif command == "change":
        if len(sys.argv) != 4:
            print("Error: 'change' command requires a MAC address as the third argument.")
            sys.exit(1)
        change_mac(interface, sys.argv[3])
    elif command == "scan":
        scan_network()
    else:
        print(f"Error: Unknown command '{command}'.")
        sys.exit(1)

if __name__ == "__main__":
    main()

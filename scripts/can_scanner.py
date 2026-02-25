#!/usr/bin/env python3
import sys
import os
import time

# KATANA CAN SCANNER
# Scans for unconfigured Klipper MCUs on can0 (User must have Katapult/Klipper env)

def scan_can():
    print("  [i] Scanning CAN Bus (can0)...")
    
    # Check if interface exists
    if os.system("ip link show can0 > /dev/null 2>&1") != 0:
        print("  [!] Interface can0 not found. Setup network first.")
        return

    # Helper: We try to use the installed Klipper/Katapult scripts if available
    # because implementing raw CAN query here requires 'can' module which might not be in system python
    
    home = os.path.expanduser("~")
    klipper_lib = os.path.join(home, "klipper/lib/canboot/flash_can.py")
    katapult_lib = os.path.join(home, "katapult/scripts/flashtool.py") # Example path
    
    found_tool = False
    
    # Try Katapult/CanBoot flashtool query
    if os.path.exists(klipper_lib):
         print(f"  [i] Using Klipper/CanBoot tool: {klipper_lib}")
         # Query command
         cmd = f"python3 {klipper_lib} -q"
         os.system(cmd)
         found_tool = True
    elif os.path.exists(katapult_lib):
         print(f"  [i] Using Katapult tool: {katapult_lib}")
         cmd = f"python3 {katapult_lib} -q"
         os.system(cmd)
         found_tool = True
    else:
        print("  [!] No Klipper/Katapult flash tools found.")
        print("      Ensure Klipper is installed to use advanced scanning.")
        # Fallback: simple ip link statistics
        print("  [i] Interface Statistics:")
        os.system("ip -s link show can0")

if __name__ == "__main__":
    scan_can()

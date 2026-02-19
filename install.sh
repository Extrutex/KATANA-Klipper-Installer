#!/bin/bash

# Farben definieren
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}/// KATANA Klipper Installer - Initializing... ///${NC}"

# 1. Prüfen ob Git da ist
if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    sudo apt-get update && sudo apt-get install -y git
fi

# 2. Zielverzeichnis
INSTALL_DIR="$HOME/KATANA-Klipper-Installer"

# 3. Klonen oder Updaten
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${GREEN}Updating KATANA...${NC}"
    cd "$INSTALL_DIR"
    git pull
else
    echo -e "${GREEN}Cloning KATANA...${NC}"
    git clone https://github.com/Extrutex/KATANA-Klipper-Installer.git "$INSTALL_DIR"
fi

# 4. Starten (MIT FIX FÜR TASTATUR)
cd "$INSTALL_DIR"
chmod +x katanaos.sh

# Das hier ist der Zaubertrick: < /dev/tty
# Das zwingt das Skript, wieder auf den Benutzer zu hören statt auf curl.
./katanaos.sh < /dev/tty

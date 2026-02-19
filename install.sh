#!/bin/bash
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}/// KATANA Klipper Installer - Initializing... ///${NC}"

if ! command -v git &> /dev/null; then
    echo "Git installing..."
    sudo apt-get update && sudo apt-get install -y git
fi

INSTALL_DIR="$HOME/KATANA-Klipper-Installer"

if [ -d "$INSTALL_DIR" ]; then
    echo -e "${GREEN}Updating...${NC}"
    cd "$INSTALL_DIR"
    git pull
else
    echo -e "${GREEN}Cloning...${NC}"
    git clone https://github.com/Extrutex/KATANA-Klipper-Installer.git "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"
chmod +x katanaos.sh
./katanaos.sh

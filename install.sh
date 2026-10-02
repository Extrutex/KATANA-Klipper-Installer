#!/bin/bash
# --- KATANA BOOTSTRAP ---
#
# Fetches (or updates) the repository and hands over to katanaos.sh.
#
# Strict mode is on because this file is executed, never sourced, and it is
# short enough to audit line by line:
#   -e  a failed clone or pull must not fall through to running a stale or
#       half-written checkout
#   -u  a typo'd variable must not expand to "" and rm/cd somewhere unintended
#   -o pipefail  no pipeline here may hide a failing producer
set -euo pipefail

# Farben definieren
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}/// KATANA Klipper Installer - Initializing... ///${NC}"

# 1. Prüfen ob Git da ist
if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    sudo apt-get update
    sudo apt-get install -y git
fi

# 2. Zielverzeichnis
INSTALL_DIR="$HOME/KATANA-Klipper-Installer"
REPO_URL="https://github.com/Extrutex/KATANA-Klipper-Installer.git"

# 3. Klonen oder Updaten
if [ -d "$INSTALL_DIR/.git" ]; then
    echo -e "${GREEN}Updating KATANA...${NC}"
    if ! git -C "$INSTALL_DIR" pull --ff-only; then
        echo -e "${RED}Update failed.${NC} $INSTALL_DIR has local changes or a diverged branch." >&2
        echo "Resolve it there, or move the directory aside and re-run this installer." >&2
        exit 1
    fi
elif [ -d "$INSTALL_DIR" ]; then
    echo -e "${RED}$INSTALL_DIR exists but is not a git checkout.${NC}" >&2
    echo "Move it aside and re-run this installer." >&2
    exit 1
else
    echo -e "${GREEN}Cloning KATANA...${NC}"
    if ! git clone "$REPO_URL" "$INSTALL_DIR"; then
        echo -e "${RED}Clone failed.${NC} Check network access to github.com." >&2
        exit 1
    fi
fi

cd "$INSTALL_DIR"
chmod +x katanaos.sh

# 4. Uebergabe an katanaos.sh
#
# Arguments are forwarded. Without this, the documented unattended one-liner
#
#     curl -sSL .../install.sh | bash -s -- install --profile standard --yes
#
# could not work at all: the bootstrap dropped every argument and started the
# interactive menu, which then demanded a TTY and aborted. An invocation WITH
# arguments is by definition unattended, so it gets /dev/null on stdin — that is
# the contract the exit codes are built on, and it must not be able to block on
# a terminal that happens to be attached.
if [ "$#" -gt 0 ]; then
    exec ./katanaos.sh "$@" < /dev/null
fi

# No arguments: interactive menu, which genuinely needs a terminal. When we were
# started through a pipe (curl | bash) stdin is the script itself, so we borrow
# the controlling terminal instead.
if [ -t 0 ]; then
    exec ./katanaos.sh
fi

if [ -e /dev/tty ] && (: < /dev/tty) 2>/dev/null; then
    exec ./katanaos.sh < /dev/tty
fi

echo -e "${RED}Error: No TTY available.${NC} The interactive menu needs a terminal." >&2
echo "For unattended use, pass the install command instead, e.g.:" >&2
echo "  curl -sSL .../install.sh | bash -s -- install --profile standard --yes" >&2
exit 1

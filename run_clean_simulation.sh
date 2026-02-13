#!/bin/bash
# Simulates KATANAOS in a CLEAN Docker container (No Cache)

# Fix Path for macOS Docker Desktop
export PATH=$PATH:/usr/local/bin:/Applications/Docker.app/Contents/Resources/bin

# 0. Check for Docker
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed or not running."
    exit 1
fi

echo "building FRESH simulation container (no-cache)..."
docker build --no-cache -t katanaos-sim -f tests/Dockerfile .

echo "starting simulation..."
echo "------------------------------------------------"
echo "You are now inside a clean Debian container."
echo "KATANAOS will start automatically."
echo "------------------------------------------------"

docker run -it --rm --dns=8.8.8.8 --dns=8.8.4.4 katanaos-sim

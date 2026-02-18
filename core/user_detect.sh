#!/bin/bash
# core/user_detect.sh
# KATANA Core Module: User & Environment Detection
# Provides KLIPPER_USER and KLIPPER_HOME for multi-platform support.
# Works on Raspberry Pi OS, Armbian (Orange Pi, ROCK Pi, Banana Pi),
# and generic Debian/Ubuntu hosts.

# Detect the real user even when running through sudo
if [ -n "$SUDO_USER" ]; then
    KLIPPER_USER="$SUDO_USER"
elif [ -n "$USER" ]; then
    KLIPPER_USER="$USER"
else
    KLIPPER_USER="$(whoami)"
fi

# Resolve the user's home directory (don't rely on $HOME under sudo)
if [ -n "$SUDO_USER" ]; then
    KLIPPER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
fi
if [ -z "$KLIPPER_HOME" ]; then
    KLIPPER_HOME="$HOME"
fi

export KLIPPER_USER
export KLIPPER_HOME

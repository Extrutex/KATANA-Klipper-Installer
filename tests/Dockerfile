FROM debian:bookworm-slim

# 1. Install basic tools to mimic a fresh Pi
# We need sudo because the script expects it
RUN apt-get update && apt-get install -y \
    sudo \
    bash \
    git \
    curl \
    build-essential \
    python3-dev \
    python3-venv \
    virtualenv \
    libffi-dev \
    libncurses-dev \
    libusb-dev \
    avrdude \
    gcc-avr \
    binutils-avr \
    avr-libc \
    stm32flash \
    libnewlib-arm-none-eabi \
    libusb-1.0-0-dev \
    liblmdb-dev \
    libopenjp2-7 \
    libsodium-dev \
    libjpeg-dev \
    packagekit \
    python3-wheel \
    nginx \
    systemd-sysv \
    nano \
    systemd \
    && rm -rf /var/lib/apt/lists/*

# 2. Create a user 'pi' with sudo privileges (passwordless)
RUN useradd -m -s /bin/bash pi && \
    echo "pi ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 3. Set workdir
WORKDIR /home/pi/KATANA

# 4. Copy current directory into the container
# (This simulates 'git clone')
COPY . /home/pi/KATANA
RUN chown -R pi:pi /home/pi/KATANA

# 5. Mock systemctl for simulation
RUN echo '#!/bin/bash\n\
    if [ "$1" == "is-active" ]; then\n\
    if [ "$2" == "--quiet" ]; then shift; fi\n\
    SERVICE=$1\n\
    if [ -f "/tmp/$SERVICE.active" ]; then exit 0; else exit 1; fi\n\
    elif [ "$1" == "start" ] || [ "$1" == "restart" ]; then\n\
    shift\n\
    for SERVICE in "$@"; do touch "/tmp/$SERVICE.active"; echo "Started $SERVICE"; done\n\
    elif [ "$1" == "stop" ]; then\n\
    shift\n\
    for SERVICE in "$@"; do rm -f "/tmp/$SERVICE.active"; echo "Stopped $SERVICE"; done\n\
    elif [ "$1" == "enable" ] || [ "$1" == "daemon-reload" ]; then\n\
    exit 0\n\
    else\n\
    echo "Mock systemctl: $1 not fully implemented"\n\
    fi' > /usr/bin/systemctl && chmod +x /usr/bin/systemctl

# 6. Switch to user
USER pi

# 7. Make script executable
RUN chmod +x katanaos.sh

# 7. Entrypoint
CMD ["./katanaos.sh"]

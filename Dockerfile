# Dockerfile for KATANAOS Testing
FROM debian:bookworm-slim

# Avoid prompts from apt
ENV DEBIAN_FRONTEN=noninteractive

# Install core dependencies and tools needed to simulate the environment
RUN apt-get update && apt-get install -y \
    sudo \
    git \
    curl \
    wget \
    python3 \
    python3-venv \
    python3-pip \
    virtualenv \
    dfu-util \
    rsync \
    make \
    gcc \
    iproute2 \
    iputils-ping \
    systemd \
    systemd-sysv \
    kmod \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user 'pi' to mimic the target environment
RUN useradd -m -s /bin/bash pi && \
    echo "pi:pi" | chpasswd && \
    adduser pi sudo && \
    echo "pi ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set working directory
WORKDIR /home/pi/KATANA_INSTALLER

# Switch to user pi
USER pi

# Keep the container running
CMD ["/bin/bash"]

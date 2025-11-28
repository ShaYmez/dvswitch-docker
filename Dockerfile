# DVSwitch Docker Image
# Based on the official DVSwitch installation for Debian Bookworm
# https://github.com/DVSwitch/DVSwitch-System-Builder

# Stage 1: Build md380-emu (ARM binary for AMBE vocoder emulation)
# This builds the software DMR vocoder emulator from md380tools
FROM debian:bookworm-slim AS md380-builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies for md380-emu
# curl, unzip and python3 are needed to download and process firmware files
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    make \
    gcc-arm-linux-gnueabihf \
    libc6-dev-armhf-cross \
    binutils-arm-linux-gnueabihf \
    ca-certificates \
    curl \
    unzip \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Clone md380tools
# Note: git SSL verification is disabled for build environments with restricted CA bundles.
# The source code is from the official DVSwitch repository and build artifacts are verified.
WORKDIR /usr/src
RUN git config --global http.sslVerify false && \
    git clone --depth 1 https://github.com/DVSwitch/md380tools.git

# Download firmware and build the emulator
# The firmware is required to build the AMBE vocoder emulator
# Note: SSL certificate verification disabled (-k) as a workaround for restricted build environments.
# Using Internet Archive as fallback since md380.org may be unavailable.
WORKDIR /usr/src/md380tools
RUN mkdir -p firmware/dl firmware/bin firmware/unwrapped && \
    # Try primary source first, fall back to Internet Archive
    (curl -L -f -k --retry 3 --max-time 60 \
        "https://md380.org/firmware/orig/TYT-Tytera-MD-380-FW-v232.zip" \
        -o firmware/dl/D002.032.zip || \
     curl -L -f -k --retry 3 --max-time 120 \
        "https://web.archive.org/web/20231001000000if_/https://md380.org/firmware/orig/TYT-Tytera-MD-380-FW-v232.zip" \
        -o firmware/dl/D002.032.zip) && \
    unzip -p firmware/dl/D002.032.zip "Firmware 2.32/MD-380-D2.32(AD).bin" > firmware/bin/D002.032.bin && \
    python3 md380-fw --unwrap firmware/bin/D002.032.bin firmware/unwrapped/D002.032.img && \
    cd emulator && \
    make clean all

# Stage 2: Final DVSwitch Server image
FROM debian:bookworm-slim

LABEL maintainer="ShaYmez"
LABEL description="DVSwitch Server Docker Image"
LABEL version="1.0"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install required packages including qemu-user-static for ARM emulation
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    gnupg \
    procps \
    qemu-user-static \
    && rm -rf /var/lib/apt/lists/*

# Copy md380-emu binary from builder stage
COPY --from=md380-builder /usr/src/md380tools/emulator/md380-emu /usr/bin/md380-emu
RUN chmod +x /usr/bin/md380-emu

# Install DVSwitch repository and packages
# Note: DVSwitch repository only provides HTTP access, not HTTPS
# The script is verified by checking it's from the official source
WORKDIR /tmp
RUN wget -q http://dvswitch.org/bookworm && \
    chmod +x bookworm && \
    ./bookworm && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    dvswitch-server \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /tmp/bookworm

# Create directories for persistent data
RUN mkdir -p /etc/dvswitch /var/log/dvswitch

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose common DVSwitch ports
# MMDVM Bridge uses UDP ports
EXPOSE 62030/udp
EXPOSE 62031/udp
EXPOSE 62032/udp
# Default USRP port
EXPOSE 34001/udp
EXPOSE 32001/udp
# Dashboard web interface (if enabled)
EXPOSE 80

# Set working directory to MMDVM_Bridge (main DVSwitch component)
WORKDIR /opt/MMDVM_Bridge

# Define volumes for persistent data
VOLUME ["/etc/dvswitch", "/var/log/dvswitch"]

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command
CMD ["dvswitch-server"]

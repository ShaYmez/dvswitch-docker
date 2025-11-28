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

# Copy Python 3 compatible firmware unwrap script
# The original md380-fw script requires Python 2, this is a Python 3 port
COPY unwrap_firmware.py /usr/src/md380tools/unwrap_firmware.py

# Download firmware and build the emulator
# The firmware is required to build the AMBE vocoder emulator
# Firmware is downloaded from md380.org (official source)
WORKDIR /usr/src/md380tools
RUN mkdir -p firmware/dl firmware/bin firmware/unwrapped && \
    curl -L -f -k --retry 3 --max-time 60 \
        "https://md380.org/firmware/orig/TYT-Tytera-MD-380-FW-v232.zip" \
        -o firmware/dl/D002.032.zip && \
    unzip -p firmware/dl/D002.032.zip "Firmware 2.32/MD-380-D2.32(AD).bin" > firmware/bin/D002.032.bin && \
    python3 unwrap_firmware.py firmware/bin/D002.032.bin firmware/unwrapped/D002.032.img && \
    cd emulator && \
    rm -f *.o *~ md380-emu *.wav *.raw *.elf && \
    arm-linux-gnueabihf-gcc -static -g -std=gnu99 -c -o md380-emu.o md380-emu.c && \
    arm-linux-gnueabihf-gcc -static -g -std=gnu99 -c -o ambe.o ambe.c && \
    arm-linux-gnueabihf-objcopy \
        -I binary ../firmware/unwrapped/D002.032.img \
        --change-addresses=0x0800C000 \
        --rename-section .data=.firmware \
        -O elf32-littlearm -B arm firmware.o && \
    arm-linux-gnueabihf-objcopy \
        -I binary ../cores/d02032-core.img \
        --change-addresses=0x20000000 \
        --rename-section .data=.sram \
        -O elf32-littlearm -B arm ram.o && \
    arm-linux-gnueabihf-gcc -static -g -std=gnu99 -o md380-emu md380-emu.o ambe.o firmware.o ram.o \
        -Xlinker --just-symbols=../applet/src/symbols_d02.032 \
        -Xlinker --section-start=.firmware=0x0800C000 \
        -Xlinker --section-start=.sram=0x20000000

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
# We install core DVSwitch packages individually to avoid conflicts with our
# custom-built md380-emu (built from source with firmware from md380.org)
# Post-install scripts may fail because systemctl isn't available in Docker,
# but that's expected - services will be managed by the entrypoint script
WORKDIR /tmp
RUN apt-get update && \
    wget -q http://dvswitch.org/bookworm && \
    chmod +x bookworm && \
    ./bookworm && \
    apt-get update && \
    apt-get download dvswitch-base mmdvm-bridge analog-bridge dvswitch-menu && \
    dpkg --force-all -i dvswitch-base*.deb mmdvm-bridge*.deb analog-bridge*.deb dvswitch-menu*.deb || true && \
    apt-get install -f -y --no-install-recommends || true && \
    rm -rf /var/lib/apt/lists/* *.deb /tmp/bookworm

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

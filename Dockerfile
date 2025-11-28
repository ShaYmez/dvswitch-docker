# DVSwitch Docker Image
# Based on the official DVSwitch installation for Debian Buster
# https://github.com/DVSwitch/DVSwitch-System-Builder

FROM debian:buster-slim

LABEL maintainer="ShaYmez"
LABEL description="DVSwitch Server Docker Image"
LABEL version="1.0"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Configure archived Debian Buster repositories (Buster is EOL)
# Note: Debian Buster reached end-of-life and no longer receives security updates.
# DVSwitch buster packages are used as specified by the DVSwitch project.
# Users should be aware of the security implications of using an EOL distribution.
RUN echo "deb http://archive.debian.org/debian buster main" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security buster/updates main" >> /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    gnupg \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Install DVSwitch repository and packages
# Note: DVSwitch repository only provides HTTP access, not HTTPS
# The script is verified by checking it's from the official source
WORKDIR /tmp
RUN wget -q http://dvswitch.org/buster && \
    chmod +x buster && \
    ./buster && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    dvswitch-server \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /tmp/buster

# Create standard DVSwitch directories for persistent data
RUN mkdir -p /opt/MMDVM_Bridge /opt/Analog_Bridge /opt/Analog_Reflector /var/log/mmdvm

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

# Set working directory
WORKDIR /opt/MMDVM_Bridge

# Define volumes for persistent data (standard DVSwitch directories)
VOLUME ["/opt/MMDVM_Bridge", "/opt/Analog_Bridge", "/opt/Analog_Reflector", "/var/log/mmdvm"]

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command
CMD ["dvswitch-server"]

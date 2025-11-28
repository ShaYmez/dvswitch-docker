# DVSwitch Docker Image
# Based on the official DVSwitch installation for Debian Bookworm
# https://github.com/DVSwitch/DVSwitch-System-Builder

FROM debian:bookworm-slim

LABEL maintainer="ShaYmez"
LABEL description="DVSwitch Server Docker Image"
LABEL version="1.0"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    gnupg \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Install DVSwitch repository and packages
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

# Set working directory
WORKDIR /opt/dvswitch

# Define volumes for persistent data
VOLUME ["/etc/dvswitch", "/var/log/dvswitch"]

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command
CMD ["dvswitch-server"]

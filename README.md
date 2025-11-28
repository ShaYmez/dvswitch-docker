# DVSwitch Docker

Docker container for the official [DVSwitch](https://github.com/DVSwitch) Server - a digital voice switching system for amateur radio.

[![Build and Push Docker Image](https://github.com/ShaYmez/dvswitch-docker/actions/workflows/docker-build.yml/badge.svg)](https://github.com/ShaYmez/dvswitch-docker/actions/workflows/docker-build.yml)

## Overview

This repository provides a Docker image for running DVSwitch Server in a containerized environment. DVSwitch Server is a suite of tools for bridging various digital voice modes in amateur radio, including DMR, D-STAR, System Fusion (YSF), P25, and NXDN.

## Features

- Based on Debian Bookworm (slim)
- Installs the complete DVSwitch Server package from the official DVSwitch repository
- Multi-architecture support (amd64, arm64)
- Automated builds via GitHub Actions
- Available on Docker Hub and GitHub Container Registry

## Quick Start

### Using Docker Run

```bash
docker run -d \
  --name dvswitch-server \
  --restart unless-stopped \
  -p 62030:62030/udp \
  -p 62031:62031/udp \
  -p 62032:62032/udp \
  -p 34001:34001/udp \
  -p 32001:32001/udp \
  -v dvswitch-config:/etc/dvswitch \
  -v dvswitch-logs:/var/log/dvswitch \
  shaymez/dvswitch-server:latest
```

### Using Docker Compose

1. Clone this repository:
```bash
git clone https://github.com/ShaYmez/dvswitch-docker.git
cd dvswitch-docker
```

2. Start the container:
```bash
docker-compose up -d
```

3. Access the DVSwitch management interface:
```bash
docker exec -it dvswitch-server /usr/local/dvs/dvs
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TZ` | `UTC` | Container timezone |

### Volumes

| Path | Description |
|------|-------------|
| `/etc/dvswitch` | DVSwitch configuration files |
| `/var/log/dvswitch` | DVSwitch log files |

### Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 62030 | UDP | MMDVM Bridge |
| 62031 | UDP | MMDVM Bridge |
| 62032 | UDP | MMDVM Bridge |
| 34001 | UDP | USRP |
| 32001 | UDP | USRP |
| 80 | TCP | Dashboard (if enabled) |

## Building Locally

```bash
# Build the image
docker build -t dvswitch-server:local .

# Run the container
docker run -d --name dvswitch-test dvswitch-server:local
```

## GitHub Actions Setup

To enable automated builds and pushes to Docker Hub, configure the following secrets in your repository:

1. `DOCKERHUB_USERNAME` - Your Docker Hub username
2. `DOCKERHUB_TOKEN` - Your Docker Hub access token

The workflow will:
- Build on every push to main/master branches
- Build on pull requests (without pushing)
- Create tagged releases when you push version tags (e.g., `v1.0.0`)
- Rebuild weekly to incorporate the latest DVSwitch updates

## Image Registries

The Docker image is available from:

- **Docker Hub**: `shaymez/dvswitch-server`
- **GitHub Container Registry**: `ghcr.io/shaymez/dvswitch-docker`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is provided as-is for the amateur radio community. DVSwitch is developed and maintained by the [DVSwitch project](https://github.com/DVSwitch).

## Acknowledgments

- [DVSwitch Project](https://github.com/DVSwitch) for the excellent digital voice switching software
- The amateur radio community for continued development and support

## Support

For issues related to:
- **This Docker image**: Open an issue in this repository
- **DVSwitch software**: Visit the [DVSwitch GitHub](https://github.com/DVSwitch)
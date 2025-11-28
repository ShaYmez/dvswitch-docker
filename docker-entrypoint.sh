#!/bin/bash
set -e

# DVSwitch Docker Entrypoint Script

echo "=========================================="
echo "DVSwitch Server Docker Container"
echo "=========================================="

# Check if configuration exists
if [ ! -d "/etc/dvswitch" ]; then
    echo "Creating /etc/dvswitch directory..."
    mkdir -p /etc/dvswitch
fi

# Check if log directory exists
if [ ! -d "/var/log/dvswitch" ]; then
    echo "Creating /var/log/dvswitch directory..."
    mkdir -p /var/log/dvswitch
fi

# If the first argument is dvswitch-server or similar, run the DVSwitch services
case "$1" in
    dvswitch-server)
        echo "Starting DVSwitch Server..."
        # Start the DVSwitch services
        # The actual startup command depends on how DVSwitch is configured
        # This is a placeholder - adjust based on actual DVSwitch service management
        if command -v dvs &> /dev/null; then
            echo "DVSwitch management utility (dvs) is available"
            echo "You can configure DVSwitch using: dvs"
        fi
        
        # Keep container running and tail logs
        echo "Container is ready. DVSwitch services can be managed via dvs command."
        echo "Use 'docker exec -it <container> /usr/local/dvs/dvs' to manage DVSwitch"
        
        # Keep the container running
        tail -f /dev/null
        ;;
    *)
        # Run any other command passed to the container
        exec "$@"
        ;;
esac

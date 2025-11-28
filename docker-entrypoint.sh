#!/bin/bash
set -e

# DVSwitch Docker Entrypoint Script

echo "=========================================="
echo "DVSwitch Server Docker Container"
echo "=========================================="

# Check if standard DVSwitch directories exist
if [ ! -d "/opt/MMDVM_Bridge" ]; then
    echo "Creating /opt/MMDVM_Bridge directory..."
    mkdir -p /opt/MMDVM_Bridge
fi

if [ ! -d "/opt/Analog_Bridge" ]; then
    echo "Creating /opt/Analog_Bridge directory..."
    mkdir -p /opt/Analog_Bridge
fi

if [ ! -d "/opt/Analog_Reflector" ]; then
    echo "Creating /opt/Analog_Reflector directory..."
    mkdir -p /opt/Analog_Reflector
fi

# Check if log directory exists
if [ ! -d "/var/log/mmdvm" ]; then
    echo "Creating /var/log/mmdvm directory..."
    mkdir -p /var/log/mmdvm
fi

# If the first argument is dvswitch-server or similar, run the DVSwitch services
case "$1" in
    dvswitch-server)
        echo "Starting DVSwitch Server..."
        
        # Check if DVSwitch management utility is available
        if [ -x "/usr/local/dvs/dvs" ]; then
            echo "DVSwitch management utility (dvs) is available"
            echo "You can configure DVSwitch using: docker exec -it <container> /usr/local/dvs/dvs"
        fi
        
        # Check for MMDVM_Bridge
        if command -v MMDVM_Bridge &> /dev/null; then
            echo "MMDVM_Bridge is available"
        fi
        
        echo ""
        echo "Container is ready. DVSwitch services can be managed via dvs command."
        echo "Use 'docker exec -it <container> /bin/bash' to access the container shell."
        echo ""
        
        # Keep the container running
        # Using sleep in a loop is more graceful than tail -f /dev/null
        # and allows for signal handling
        while true; do
            sleep 3600 &
            wait $!
        done
        ;;
    *)
        # Run any other command passed to the container
        exec "$@"
        ;;
esac

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
        
        # Check if DVSwitch management utility is available
        if [ -x "/usr/local/dvs/dvs" ]; then
            echo "✓ DVSwitch management utility (dvs) is available"
            echo "  You can configure DVSwitch using: docker exec -it <container> /usr/local/dvs/dvs"
        fi
        
        # Check for MMDVM_Bridge
        if [ -x "/opt/MMDVM_Bridge/MMDVM_Bridge" ]; then
            echo "✓ MMDVM_Bridge is available at /opt/MMDVM_Bridge/"
        fi
        
        # Check for Analog_Bridge
        if [ -x "/opt/Analog_Bridge/Analog_Bridge" ]; then
            echo "✓ Analog_Bridge is available at /opt/Analog_Bridge/"
        fi
        
        # Check for dvswitch.sh management script
        if [ -x "/opt/MMDVM_Bridge/dvswitch.sh" ]; then
            echo "✓ dvswitch.sh management script is available"
        fi
        
        # Check for md380-emu (software DMR vocoder emulator)
        if command -v md380-emu &> /dev/null; then
            echo "✓ md380-emu is available at $(which md380-emu)"
            # Verify md380-emu can execute (requires qemu-user-static for ARM emulation)
            # Running md380-emu without arguments shows usage info to stderr
            if md380-emu 2>&1 | grep -q "Usage"; then
                echo "✓ md380-emu is functional"
            else
                echo "! md380-emu found but may require additional configuration"
            fi
        elif [ -x "/opt/md380-emu/md380-emu" ]; then
            echo "✓ md380-emu found at /opt/md380-emu/"
        else
            echo "- md380-emu not found (optional component)"
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

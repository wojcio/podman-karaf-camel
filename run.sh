#!/bin/bash

# Run script for Apache Karaf with Camel 4.6.0
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Disable external compose provider message
export DOCKER_HOST="podman://"

echo "Starting Karaf with Camel 4.6.0..."

# Build the image
echo "Building Docker image..."
podman build -t karaf-camel:latest -f Dockerfile .

# Remove existing container if it exists
if podman ps -a --format '{{.Names}}' | grep -q '^karaf-camel$'; then
    echo "Removing existing container..."
    podman rm -f karaf-camel
fi

# Create network if it doesn't exist
if ! podman network exists karaf-network; then
    echo "Creating network..."
    podman network create karaf-network
fi

# Create volumes if they don't exist
for volume in karaf_data karaf_logs; do
    if ! podman volume exists "$volume"; then
        echo "Creating volume: $volume"
        podman volume create "$volume"
    fi
done

# Start the container bound to localhost
echo "Starting container on localhost..."
podman run -d \
    --name karaf-camel \
    --hostname karaf-camel \
    -p 127.0.0.1:10099:22 \
    -p 127.0.0.1:8101:8101 \
    -p 127.0.0.1:8181:8181 \
    -p 127.0.0.1:44444:44444 \
    -v karaf_data:/opt/karaf/data \
    -v karaf_logs:/opt/karaf/log \
    -e KARAF_HOME=/opt/karaf \
    -e JAVA_MAX_MEM=1G \
    -e JAVA_MIN_MEM=256M \
    --restart unless-stopped \
    karaf-camel:latest

# Wait for Karaf to be ready
echo "Waiting for Karaf to start..."
sleep 10

# Show container status
echo ""
podman ps -a --filter name=karaf-camel

echo ""
echo "Karaf is starting. Access points (Localhost Only):"
echo "  - Karaf SSH Console: ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null karaf@localhost -p 8101"
echo "  - Web Console:       http://127.0.0.1:8181/system/console/http"
echo "  - SSH (Remote):      ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p 10099"
echo ""
echo "To view logs: podman logs -f karaf-camel"
#!/bin/bash

# Run script for Apache Karaf with Camel 4.4.0
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Disable external compose provider message
export DOCKER_HOST="podman://"

echo "Starting Karaf with Camel 4.4.wha0..."

# 1. Build the image
echo "Building Docker image..."
podman build -t karaf-camel:latest -f Dockerfile .

# 2. Cleanup existing container
if podman ps -a --format '{{.Names}}' | grep -q '^karaf-camel$'; then
    echo "Removing existing container..."
    podman rm -f karaf-camel
fi

# 3. Network Setup
if ! podman network exists karaf-network; then
    echo "Creating network..."
    podman network create karaf-network
fi

# 4.1 Delete local directories
echo "Deleting local directories: deploy, data, examples..."
rm -rf "$SCRIPT_DIR/deploy"
rm -rf "$SCRIPT_DIR/data"
rm -rf "$SCRIPT_DIR/examples"


# 4.2 Create local directories
echo "Create local directories deploy,data,examples"
mkdir -p "$SCRIPT_DIR/deploy"
mkdir -p "$SCRIPT_DIR/data"
mkdir -p "$SCRIPT_DIR/examples"

# ==================================================================
# FIX: Pre-populate local folders from the image if they are empty
# ==================================================================
echo "Checking volume initialization..."

init_volume() {
    local host_dir=$1
    local container_path=$2
    
    if [ -z "$(ls -A "$host_dir")" ]; then
        echo "  - Initializing $host_dir from image..."
        id=$(podman create karaf-camel:latest)
        podman cp "$id:$container_path/." "$host_dir/"
        podman rm "$id" > /dev/null
    fi
}

init_volume "$SCRIPT_DIR/deploy" "/opt/karaf/deploy"
init_volume "$SCRIPT_DIR/examples" "/opt/karaf/examples"

# ==================================================================
# FIX: Force permissions (Solves "Permission Denied" / "Bundle Cache")
# ==================================================================
echo "Fixing permissions for bind mounts..."
chmod -R 777 "$SCRIPT_DIR/deploy"
chmod -R 777 "$SCRIPT_DIR/data"
chmod -R 777 "$SCRIPT_DIR/examples"

# 5. Start the container
echo "Starting container on localhost..."
podman run -d \
    --name karaf-camel \
    --hostname karaf-camel \
    -p 127.0.0.1:10099:22 \
    -p 127.0.0.1:8101:8101 \
    -p 127.0.0.1:8181:8181 \
    -p 127.0.0.1:44444:44444 \
    -v "$SCRIPT_DIR/deploy:/opt/karaf/deploy:Z,U" \
    -v "$SCRIPT_DIR/data:/opt/karaf/data:Z,U" \
    -v "$SCRIPT_DIR/examples:/opt/karaf/examples:Z,U" \
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
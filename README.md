# Apache Karaf with Camel on Podman

This project provides a ready-to-use Apache Karaf container with Apache Camel support for running enterprise integration patterns on Podman or Docker.

## Features

- **Apache Karaf 4.4.6** - OSGi-based runtime environment
- **OpenJDK 17 (Alpine)** - Lightweight Java runtime
- **Apache Camel 4.1.0** - Integration features pre-configured (featuresBoot)
- **Web Console (Hawtio)** - Web-based management interface
- **Linux Root SSH** - Full root access via port 22 (password: amiga1200)
- **Karaf SSH** - Karaf console access via port 8101 (karaf/karaf)
- **Non-root User** - Security best practices (karaf/karaf)
- **Persistent Volumes** - Data and logs survive container restarts
- **Network-isolated** - Dedicated podman network for container communication

## Quick Start

### Using the run.sh Script (Recommended)

```bash
# Make script executable if needed
chmod +x run.sh

# Run the container (localhost only)
./run.sh
```

### Using Podman Compose

```bash
# Build and start the container
podman-compose up -d

# View logs
podman-compose logs -f
```

### Manual Run

```bash
# Build the image
podman build -t karaf-camel:latest .

# Run with localhost-only bindings
podman run -d \
  --name karaf-camel \
  --hostname karaf-camel \
  -p 127.0.0.1:10099:22 \
  -p 127.0.0.1:8101:8101 \
  -p 127.0.0.1:8181:8181 \
  -p 127.0.0.1:44444:44444 \
  -v karaf_data:/opt/karaf/data \
  -v karaf_logs:/opt/karaf/log \
  --restart unless-stopped \
  karaf-camel:latest
```

## SSH Access

### Linux Root Access (Port 10099 -> 22)

Full root access to the Alpine container:

```bash
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p 10099
# Password: amiga1200
```

### Karaf SSH Console (Port 8101)

Access the Karaf OSGi console:

```bash
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null karaf@localhost -p 8101
# Password: karaf

# Or as root user (Karaf credentials)
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p 8101
# Password: admin
```

## Web Console

```bash
open http://127.0.0.1:8181/system/console
# Default credentials: karaf/karaf
```

## Exposed Ports

| Host Port | Container Port | Service | Description |
|-----------|----------------|---------|-------------|
| 10099 | 22 | SSH (Linux) | Full root shell access |
| 8101 | 8101 | SSH (Karaf) | Karaf OSGi console |
| 8181 | 8181 | HTTP/Jetty | Web console and REST APIs |
| 44444 | 44444 | RMI Registry | JMX/RMI registry |

## Pre-installed Karaf Features

The following features are installed on startup (see `etc/org.apache.karaf.features.cfg`):
- camel - Core Camel routes
- hawtio - Web-based management console
- bundle, config, feature, service, system - OSGi framework management
- webconsole - Web console with Karaf realm authentication

## Running Commands in Container

```bash
# View container status
podman ps | grep karaf-camel

# Follow logs
podman logs -f karaf-camel

# Enter container shell (as root)
podman exec -it karaf-camel /bin/bash

# Run Karaf client commands
podman exec karaf-camel /opt/karaf/bin/client "feature:list"

# Stop the container
podman stop karaf-camel

# Restart the container
podman restart karaf-camel
```

## Environment Variables

| Variable | Default (Compose) | Default (Script) | Description |
|----------|-------------------|------------------|-------------|
| JAVA_MAX_MEM | 2G | 1G | Maximum heap size |
| JAVA_MIN_MEM | 512M | 256M | Initial heap size |

## Data Persistence

Data and logs are stored in Podman volumes:
- `karaf_data` - Karaf runtime data, deployments, and configuration
- `karaf_logs` - Application and system logs

## Networking

A dedicated podman network named `karaf-network` is created for container communication.

## Stop and Cleanup

```bash
# Stop the container (keeps volumes)
podman stop karaf-camel
# or with compose:
podman-compose down

# Remove container and volumes
podman rm -v karaf-camel
# or with compose:
podman-compose down -v

# Remove the image
podman rmi karaf-camel:latest
```

## Customization

### Adding Camel Routes

Place your Blueprint or Spring XML route files in the `deploy/` directory.

### Installing Additional Features

```bash
# In Karaf console:
karaf@root()> feature:repo-add camel 4.6.0
karaf@root()> feature:install camel-bindy
karaf@root()> feature:install camel-jackson
```

### Modifying Configuration

Edit the configuration files in the mounted `karaf_data` volume or rebuild with custom configurations.

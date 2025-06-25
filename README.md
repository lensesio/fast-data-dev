# Fast Data Dev

[![docker](https://img.shields.io/docker/pulls/lensesio/fast-data-dev.svg?style=flat)](https://hub.docker.com/r/lensesio/fast-data-dev/)
[![](https://images.microbadger.com/badges/image/lensesio/fast-data-dev.svg)](http://microbadger.com/images/lensesio/fast-data-dev)

[Join the Slack Lenses.io Community!](https://launchpass.com/lensesio)

## Overview

[Fast Data Dev](https://hub.docker.com/r/lensesio/fast-data-dev) is an Apache
Kafka development environment packaged as a Docker container. It provides a
Kafka ecosystem including a Kafka Broker, Confluent Schema Registry, and Kafka
Connect with Lenses.io's [Stream
Reactor](https://github.com/lensesio/stream-reactor) open source connectors
(with optional enterprise support) pre-installed. On top of that there are data
generators available, a web interface so you can access the various services
logs and optionally TLS keystores and truststores, and a ton of settings so you
can tailor it to your needs.

## Quick Start

Our recommendation is to combine fast-data-dev with Lenses CE (community
edition) using our docker-compose, available
[here](https://lenses.io/community-edition/). Lenses provides industry-leading
Developer Experience for Apache Kafka and Kafka Connect and among many features,
you may particularly enjoy our SQL Studio that allows you to run SQL queries on
your Kafka topics and the SQL Processors for creating Streaming SQL queries.

Our docker-compose will setup fast-data-dev and Lenses for you.

### Basic Usage

Start a complete Kafka environment with one command:

```bash
docker run --rm \
    -p 9092:9092 \
    -p 8081:8081 \
    -p 8083:8083 \
    -p 3030:3030 \
    lensesio/fast-data-dev
```

Access the web interface at: http://localhost:3030
The Kafka Broker will be accessible at localhost:9092, the Schema Registry at
http://localhost:8081, and Kafka Connect at http://localhost:8083.

### With a Custom Host for Remote Access

```bash
docker run --rm \
    -e ADV_HOST=<YOUR_IP_ADDRESS or DNS name> \
    -p 9092:9092 \
    -p 8081:8081 \
    -p 8083:8083 \
    -p 3030:3030 \
    lensesio/fast-data-dev
```

This setup may require to allow connections to fast-data-dev from itself. For
example if you are running in a Cloud VM, you may need to setup the firewall to
not only accept connections from your computer, but also from the VM itself.

### Within docker-compose

This setup allows for both access from your host and the rest of the
docker-compose services.  The Broker address from your host is `localhost:9092`,
whilst for docker-compose services it is `kafka:19092`.

```yaml
  kafka:
    image: lensesio/fast-data-dev:3.9.0
    hostname: kafka
    environment:
      ADV_HOST: kafka
      RUNNING_SAMPLEDATA: 1
      RUNTESTS: 0
      # The next three variables are required if you want to have Kafka
      # available at the host for local development. They are tailored to KRaft
      # fast-data-dev (3.9.x or later). The broker will be available at localhost:9092.
      KAFKA_LISTENERS: PLAINTEXT://:9092,DOCKERCOMPOSE://:19092,CONTROLLER://:16062
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092,DOCKERCOMPOSE://demo-kafka:19092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: >
        DOCKERCOMPOSE:PLAINTEXT,CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,
        SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL
      # Makes things a little lighter
      DISABLE: debezium-mongodb,debezium-mysql,debezium-postgres,debezium-sqlserver,debezium-jdbc
    # These are the ports for Kafka and Schema Registry. You can disable them if
    # you don't need to access Kafka from your host.
    ports:
      - 9092:9092
      - 8081:8081
      - 8083:8083
      - 3030:3030
    # Optional, to allow to resume work (persistence)
    # volumes:
    #   - kafka-data-volume:/data
```

### SSL/TLS Setup

```bash
# Enable SSL with automatic certificate generation
docker run --rm -p 9092:9092 -p 8081:8081 -p 3030:3030 -p 8083:8083 \
  -e ENABLE_SSL=1 \
  -e SSL_EXTRA_HOSTS=myhost.example.com,192.168.1.100 \
  lensesio/fast-data-dev

# Access certificates at http://localhost:3030/certs/
# Password for keystores: fastdata
```

### No data generators and Kafka Connect
```bash
docker run --rm -p 9092:9092 -p 8081:8081 -p 3030:3030 \
  -e SAMPLEDATA=0 \
  -e RUNTESTS=0 \
  -e CONNECT_PORT=0 \
  lensesio/fast-data-dev
```

### Connector Development
```bash
# Enable specific connectors only
docker run --rm --net=host \
  -e CONNECTORS=file \
  -e CONNECT_HEAP=2G \
  -v /path/to/custom/connector.jar:/connectors/connector.jar \
  lensesio/fast-data-dev
```

## Architecture and Components

Fast Data Dev was first introduced in 2016, back when Kafka was getting traction
but was not yet mainstream. We wanted to make it easy for everyone to get
streaming within a couple minutes. People starting with Kafka and even
experienced engineers hugged our effort and we keep maintaining it since then
with upgrades and new features.

We do use vanilla Apache Kafka built from source, and Confluent's Schema
Registry also built from source.

### Components

The most reliable way to see the current components versions is to check `/build.info`:

```bash
docker run --rm lensesio/fast-data-dev:latest cat /build.info
```

- Apache Kafka 3.9.0
- Confluent Schema Registry 7.7.1
- Stream Reactor Connectors 9.0.2
  - AWS S3
  - Azure Datalake
  - Azure DocumentDB
  - Azure EventHubs
  - Azure ServiceBus
  - Cassandra
  - ElasticSearch
  - FTP
  - Google Cloud Platform PubSub
  - Google Cloud Platform Cloud Storage
  - HTTP
  - JMS
  - MQTT
  - and more
- Debezium Connectors 2.7.4

### Services

Enabled by default services:
- Kafka Broker
  - Default address: `PLAINTEXT://localhost:9092`
  - Setup in KRaft mode
  - JMX available at `localhost:9581`
  - Optional TLS listener with `-e ENABLE_TLS=1`
  - Optional advertised listener with `-e ADV_HOST=[HOST]`. If TLS is enabled,
    `ADV_HOST` will be added to the self-signed certificates. You can also add
    extra hosts with `-e EXTRA_HOSTS=[HOST1],[HOST2],...`
  - Configuration under `/var/run/broker/server.properties`
  - Restart with `supervisorctl restart broker`
- Schema Registry
  - Default address: `http://localhost:8081`
  - Configuration under `/var/run/schema-registry`
  - Restart with `supervisorctl restart schema-registry`
- Kafka Connect
  - Default address: `http://localhost:8083`
  - JMX available at `localhost:9584`
  - Get a list of all available connectors:  
    ```
    docker run --rm lensesio/fast-data-dev:latest \
      find /opt/lensesio/connectors -name "kafka-connect-*" -type d -exec basename '{}' \;
    ```
  - Disable connectors to improve RAM usage or avoid conflicts with user-added
    plugins with `-e DISABLE=aws-s3,debezium-jdbc`
  - Explicitly enable connectors with `-e CONNECTORS=aws-s3,file`
  - Add your own connectors by mounting them under `/connectors`
  - Disable Connect entirely: `-e CONNECT_PORT=0`
  - Configuration under `/var/run/connect/connect-avro-distributed.properties`
  - Restart with `supervisorctl restart connect-distributed`
- Caddy Web Server  
  Serves a web interface where you can see logs, configuration files, and
  download self-signed keystore and truststore files.
  - Default address: http://localhost:3030
  - Disable entirely with `-e WEB_PORT=0`
  - Password protect by setting `-e USER=[USER] -e PASSWORD=[PASSWORD]`
- Data Generators  
  Create a few topics with complex data in both AVRO and JSON formats.
  - By default will run once create and populate the topics, then exit.
  - To keep the generators running (loop over the datasets) set `-e
    RUNNING_SAMPLEDATA=1`
  - To disable them set `-e SAMPLEDATA=0`
  - If enabled, a demo file connector will also be created reading the broker's
    logs and producing them into a topic. To disable set `-e FORWARDLOGS=0`
- Smoke Tests  
  Basic functionality tests to confirm the services started correctly
  - To disable set `-e RUNTESTS=0`

Disabled by default services:
- Web terminal
  - Enable with `-e WEB_TERMINAL_PORT=[PORT]`
  - Default credentials: admin/admin
  - Change credentials with `-e WEB_TERMINAL_CREDS=[USER]:[PASS]`
- Supervisord Web UI
  - Enable with `-e SUPERVISORWEB=1`
  - Default address at http://localhost:9001
  - If the web server is setup with credentials, they will also apply here

### Advanced Configuration

#### Memory Configuration Options

```bash
-e CONNECT_HEAP_OPTS="-Xmx640M -Xms128M"
-e BROKER_HEAP_OPTS="-Xmx320M -Xms320M"
-e CONNECT_HEAP_OPTS="-Xmx256M -Xms128M"
```

#### Security and Authentication Options
```bash
-e USER=admin             # Basic auth username for Web UI (default: kafka)
-e PASSWORD=secret        # Basic auth password for Web UI
-e ENABLE_SSL=1           # Enable SSL/TLS for Broker
-e SSL_EXTRA_HOSTS=host1,host2  # Additional SSL certificate hosts
-e WEB_TERMINAL_CREDS=admin:admin
```

#### Data and Testing
```bash
-e SAMPLEDATA=0           # Disable sample data generation
-e RUNNING_SAMPLEDATA=1   # Enable continuous sample data flow
-e RUNTESTS=0             # Disable integration tests
-e FORWARDLOGS=0          # Disable log forwarding to Kafka topics
```

#### Connector Management
```bash
-e CONNECTORS=jdbc,elastic,hbase     # Enable specific connectors only
-e DISABLE=hbase,mongodb             # Disable specific connectors
```

#### Debug and Development
```bash
-e DEBUG=1                # Enable debug logging
-e RUN_AS_ROOT=1          # Run services as root user
-e BROWSECONFIGS=1        # Expose service configs in web UI
-e SUPERVISORWEB=1        # Enable supervisor web interface (port 9001)
-e WEB_TERMINAL_PORT=9002 # Enable web terminal
```

#### Kafka Component Configuration

Configure any Kafka component by converting properties to environment variables:
- Replace dots with underscores
- Convert to uppercase
- Prefix with service name

Examples:
```bash
# Broker: log.retention.bytes -> KAFKA_LOG_RETENTION_BYTES
-e KAFKA_LOG_RETENTION_BYTES=1073741824

# Schema Registry: kafkastore.topic -> SCHEMA_REGISTRY_KAFKASTORE_TOPIC
-e SCHEMA_REGISTRY_KAFKASTORE_TOPIC=_schemas

# Connect: plugin.path -> CONNECT_PLUGIN_PATH
-e CONNECT_PLUGIN_PATH=/custom/connectors
```

#### Pre/Post Setup Scripts

Execute custom scripts during startup:
```bash
# Inline script
-e PRE_SETUP="echo 'Pre-setup script'"

# Script file
-e PRE_SETUP_FILE="/path/to/script.sh"
-v /local/script.sh:/path/to/script.sh

# Remote script
-e PRE_SETUP_URL="https://example.com/setup.sh"
```

## Working with the Environment

### Command Line Tools

Access Kafka command line tools:
```bash
# Run commands directly
docker run --rm -it --net=host lensesio/fast-data-dev \
  kafka-topics --bootstrap-server localhost:9092 --list

# Enter container for interactive use
docker run --rm -it --net=host lensesio/fast-data-dev bash
```

## Troubleshooting

### Common Issues

1. **Container fails to start with hostname errors**
   - Solution: Add your hostname to `/etc/hosts`: `127.0.0.1 YourHostname localhost`

2. **Services not accessible from other machines**
   - Solution: Use `-e ADV_HOST=<YOUR_IP>` and ensure firewall allows connections

3. **Out of memory errors**
   - Solution: Increase Docker memory limit (minimum 4GB recommended)
   - Adjust heap sizes: `-e CONNECT_HEAP=2G -e BROKER_HEAP_OPTS="-Xmx1G"`

4. **SSL connection issues**
   - Download certificates from http://localhost:3030/certs/
   - Use password `fastdata` for all keystores

### Memory Requirements

- Minimum: 2GB RAM
- Recommended: 4GB+ RAM
- For heavy connector usage: 6GB+ RAM

## Building from Source

### Requirements
- Docker with multi-stage build support
- Optional: Docker buildx for multi-architecture builds

### Build Commands
```bash
# Basic build
docker build -t local/fast-data-dev .

# Multi-architecture build
docker buildx build --platform linux/amd64,linux/arm64 -t local/fast-data-dev .
```

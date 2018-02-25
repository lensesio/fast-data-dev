#!/usr/bin/env bash

set -e
set -u
set -o pipefail

ZK_PORT="${ZK_PORT:-2181}"
BROKER_PORT="${BROKER_PORT:-9092}"
BROKER_SSL_PORT="${BROKER_SSL_PORT:-9093}"
REGISTRY_PORT="${REGISTRY_PORT:-8081}"
REST_PORT="${REST_PORT:-8082}"
CONNECT_PORT="${CONNECT_PORT:-8083}"
WEB_PORT="${WEB_PORT:-3030}"
RUN_AS_ROOT="${RUN_AS_ROOT:-false}"
ZK_JMX_PORT="9585"
BROKER_JMX_PORT="9581"
REGISTRY_JMX_PORT="9582"
REST_JMX_PORT="9583"
CONNECT_JMX_PORT="9584"
DISABLE_JMX="${DISABLE_JMX:-false}"
ENABLE_SSL="${ENABLE_SSL:-false}"
SSL_EXTRA_HOSTS="${SSL_EXTRA_HOSTS:-}"
DEBUG="${DEBUG:-false}"
TOPIC_DELETE="${TOPIC_DELETE:-true}"
SAMPLEDATA="${SAMPLEDATA:-1}"
RUNNING_SAMPLEDATA="${RUNNING_SAMPLEDATA:-0}"
DISABLE="${DISABLE:-}"
CONNECTORS="${CONNECTORS:-}"
ADV_HOST="${ADV_HOST:-}"
CONNECT_HEAP="${CONNECT_HEAP:-}"
WEB_ONLY="${WEB_ONLY:-}"
export ZK_PORT BROKER_PORT BROKER_SSL_PORT REGISTRY_PORT REST_PORT CONNECT_PORT WEB_PORT RUN_AS_ROOT
export ZK_JMX_PORT BROKER_JMX_PORT REGISTRY_JMX_PORT REST_JMX_PORT CONNECT_JMX_PORT DISABLE_JMX
export ENABLE_SSL SSL_EXTRA_HOSTS DEBUG TOPIC_DELETE SAMPLEDATA RUNNING_SAMPLEDATA

PORTS="$ZK_PORT $BROKER_PORT $REGISTRY_PORT $REST_PORT $CONNECT_PORT $WEB_PORT"

# Export versions so envsubst will work
source build.info
export $(cut -d= -f1 /build.info)

# Create run directories for various services and initialize where applicable with configuration files.
mkdir -p \
      /var/run/zookeeper \
      /var/run/broker \
      /var/run/schema-registry \
      /var/run/connect \
      /var/run/connect/connectors/{stream-reactor,third-party} \
      /var/run/rest-proxy \
      /var/run/coyote \
      /var/run/caddy \
      /var/run/other

cp /opt/landoop/kafka/etc/kafka/zookeeper.properties \
   /opt/landoop/kafka/etc/kafka/log4j.properties \
   /var/run/zookeeper/
cp /opt/landoop/kafka/etc/kafka/server.properties \
   /opt/landoop/kafka/etc/kafka/log4j.properties \
   /var/run/broker/
cp /opt/landoop/kafka/etc/schema-registry/schema-registry.properties \
   /opt/landoop/kafka/etc/schema-registry/log4j.properties \
   /var/run/schema-registry/
# # If we want to use only the brokers for schema registry (it can work without zookeeper now):
# sed '/kafkastore.connection.url/d' -i /var/run/schema-registry/schema-registry.properties
# echo "kafkastore.bootstrap.servers=PLAINTEXT://localhost:9092" >> /var/run/schema-registry/schema-registry.properties
cp /opt/landoop/kafka/etc/schema-registry/connect-avro-distributed.properties \
   /opt/landoop/kafka/etc/kafka/connect-log4j.properties \
   /var/run/connect/
cp /opt/landoop/kafka/etc/kafka-rest/kafka-rest.properties \
   /opt/landoop/kafka/etc/kafka-rest/log4j.properties \
   /var/run/rest-proxy/
cp /usr/local/share/landoop/etc/Caddyfile \
   /var/run/caddy/Caddyfile
cp /opt/landoop/tools/share/coyote/examples/simple-integration-tests.yml \
   /var/run/coyote/simple-integration-tests.yml
cp /usr/local/bin/logs-to-kafka.sh \
   /var/run/other/
cat /usr/local/share/landoop/etc/fast-data-dev-ui/env.js \
    | envsubst > /var/www/env.js

echo "plugin.path=/var/run/connect/connectors/stream-reactor,/var/run/connect/connectors/third-party,/connectors" \
      >> /var/run/connect/connect-avro-distributed.properties

cat /usr/local/share/landoop/etc/supervisord.templates.d/*.conf > /etc/supervisord.d/01-fast-data.conf

# Set webserver basicauth username and password
USER="${USER:-kafka}"
PASSWORD="${PASSWORD:-}"
export USER
if [[ ! -z "$PASSWORD" ]]; then
    echo -e "\e[92mEnabling login credentials '\e[96m${USER}\e[34m\e[92m' '\e[96mxxxxxxxx'\e[34m\e[92m.\e[34m"
    echo "basicauth / \"${USER}\" \"${PASSWORD}\"" >> /var/run/caddy/Caddyfile
fi

# Adjust custom ports

## Some basic replacements
sed -e 's/2181/'"$ZK_PORT"'/' -e 's/8081/'"$REGISTRY_PORT"'/' -e 's/9092/'"$BROKER_PORT"'/' -i \
    /var/run/zookeeper/zookeeper.properties \
    /var/run/broker/server.properties \
    /var/run/schema-registry/schema-registry.properties \
    /var/run/connect/connect-avro-distributed.properties

## Broker specific
cat <<EOF >>/var/run/broker/server.properties

listeners=PLAINTEXT://:$BROKER_PORT
EOF

## REST Proxy specific
cat <<EOF >>/var/run/rest-proxy/kafka-rest.properties

listeners=http://0.0.0.0:$REST_PORT
schema.registry.url=http://localhost:$REGISTRY_PORT
zookeeper.connect=localhost:$ZK_PORT
# fix for Kafka REST consumer issues
consumer.request.timeout.ms=20000
consumer.max.poll.interval.ms=18000
EOF

## Schema Registry specific
cat <<EOF >>/var/run/connect/connect-avro-distributed.properties

rest.port=$CONNECT_PORT
EOF

## Other infra specific (caddy, web ui, tests, logs)
sed -e 's/3030/'"$WEB_PORT"'/' -e 's/2181/'"$ZK_PORT"'/' -e 's/9092/'"$BROKER_PORT"'/' \
    -e 's/8081/'"$REGISTRY_PORT"'/' -e 's/8082/'"$REST_PORT"'/' -e 's/8083/'"$CONNECT_PORT"'/' \
    -i /var/run/caddy/Caddyfile \
       /var/www/env.js \
       /var/run/coyote/simple-integration-tests.yml \
       /var/run/other/logs-to-kafka.sh

# Allow for topic deletion by default, unless TOPIC_DELETE is set
if echo "$TOPIC_DELETE" | grep -sqE "true|TRUE|y|Y|yes|YES|1"; then
    cat <<EOF >>/var/run/broker/server.properties
delete.topic.enable=true
EOF
fi

# Disable Connectors
OLD_IFS="$IFS"
IFS=","
if [[ -z "$CONNECTORS" ]] && [[ -z "$DISABLE" ]]; then
    DISABLE="random_string_hope_not_a_connector_name"
fi
if [[ -n "$DISABLE" ]]; then
    DISABLE=" ${DISABLE//,/ } "
    CONNECTOR_LIST="$(find /opt/landoop/connectors/stream-reactor -maxdepth 1 -name "kafka-connect-*" -type d | sed -e 's/.*kafka-connect-//' | tr '\n' ',')"
    for connector in $CONNECTOR_LIST; do
        if [[ "$DISABLE" =~ " $connector " ]]; then
            echo "Skipping connector: kafka-connect-${connector}"
        else
            ln -s /opt/landoop/connectors/stream-reactor/kafka-connect-${connector} /var/run/connect/connectors/stream-reactor/kafka-connect-${connector}
        fi
    done
    CONNECTOR_LIST="$(find /opt/landoop/connectors/third-party -maxdepth 1 -name "kafka-connect-*" -type d | sed -e 's/.*kafka-connect-//' | tr '\n' ',')"
    for connector in $CONNECTOR_LIST; do
        if [[ "$DISABLE" =~ " $connector " ]]; then
            echo "Skipping connector: kafka-connect-${connector}"
        else
            ln -s /opt/landoop/connectors/third-party/kafka-connect-${connector} /var/run/connect/connectors/third-party/kafka-connect-${connector}
        fi
    done
fi
# Enable Connectors
if [[ -n "$CONNECTORS" ]]; then
    CONNECTORS=" ${CONNECTORS//,/ } "
    CONNECTOR_LIST="$(find /opt/landoop/connectors/stream-reactor -maxdepth 1 -name "kafka-connect-*" -type d | sed -e 's/.*kafka-connect-//' | tr '\n' ',')"
    for connector in $CONNECTOR_LIST; do
        if [[ "$CONNECTORS" =~ " $connector " ]]; then
            echo "Enabling connector: kafka-connect-${connector}"
            ln -s /opt/landoop/connectors/stream-reactor/kafka-connect-${connector} /var/run/connect/connectors/stream-reactor/kafka-connect-${connector}
        fi
    done
    CONNECTOR_LIST="$(find /opt/landoop/connectors/third-party -maxdepth 1 -name "kafka-connect-*" -type d | sed -e 's/.*kafka-connect-//' | tr '\n' ',')"
    for connector in $CONNECTOR_LIST; do
        if [[ "$CONNECTORS" =~ " $connector " ]]; then
            echo "Enabling connector: kafka-connect-${connector}"
            ln -s /opt/landoop/connectors/third-party/kafka-connect-${connector} /var/run/connect/connectors/third-party/kafka-connect-${connector}
        fi
    done
fi
IFS="$OLD_IFS"


# Set ADV_HOST if needed
if [[ ! -z "${ADV_HOST}" ]]; then
    echo -e "\e[92mSetting advertised host to \e[96m${ADV_HOST}\e[34m\e[92m.\e[34m"
    echo -e "\nadvertised.listeners=PLAINTEXT://${ADV_HOST}:$BROKER_PORT" \
         >> /var/run/broker/server.properties
    echo -e "\nrest.advertised.host.name=${ADV_HOST}" \
         >> /var/run/connect/connect-avro-distributed.properties
    sed -e 's#localhost#'"${ADV_HOST}"'#g' -i /var/run/coyote/simple-integration-tests.yml /var/www/env.js /etc/supervisord.d/*
fi

# Configure JMX if needed or disable it.
if ! echo "$DISABLE_JMX" | grep -sqE "true|TRUE|y|Y|yes|YES|1"; then
    PORTS="$PORTS $BROKER_JMX_PORT $REGISTRY_JMX_PORT $REST_JMX_PORT $CONNECT_JMX_PORT $ZK_JMX_PORT"
else
    sed -r -e 's/,KAFKA_JMX_OPTS="[^"]*"//' \
        -e 's/,SCHEMA_REGISTRY_JMX_OPTS="[^"]*"//' \
        -e 's/,KAFKAREST_JMX_OPTS="[^"]*"//' \
        -i /etc/supervisord.d/*
    sed -e 's/"jmx"\s*:[^,]*/"jmx"  : ""/' \
        -i /var/www/env.js
fi

# Enable root-mode if needed
if grep -sqE "true|TRUE|y|Y|yes|YES|1" <<<"$RUN_AS_ROOT" ; then
    sed -e 's/user=nobody/;user=nobody/' -i /etc/supervisord.d/*
    echo -e "\e[92mRunning Kafka as root.\e[34m"
fi

# SSL setup
if echo "$ENABLE_SSL" | grep -sqE "true|TRUE|y|Y|yes|YES|1"; then
    PORTS="$PORTS $BROKER_SSL_PORT"
    echo -e "\e[92mTLS enabled.\e[34m"
    if [[ -f /tmp/certs/kafka.jks ]] \
           && [[ -f /tmp/certs/client.jks ]] \
           && [[ -f /tmp/certs/truststore.jks ]]; then
        echo -e "\e[92mOld keystores and truststore found, skipping creation of new ones.\e[34m"
        {
            pushd /tmp/certs
            mkdir -p /var/www/certs/
            cp client.jks truststore.jks /var/www/certs/
            popd
        } >>/var/log/ssl-setup.log 2>&1
    else
        echo -e "\e[92mCreating CA and key-cert pairs.\e[34m"
        {
            mkdir /tmp/certs
            pushd /tmp/certs
            # Create Landoop Fast Data Dev CA
            quickcert -ca -out lfddca. -CN "Landoop's Fast Data Dev Self Signed Certificate Authority"
            SSL_HOSTS="localhost,127.0.0.1,192.168.99.100"
            [[ ! -z "$ADV_HOST" ]] && SSL_HOSTS="$SSL_HOSTS,$ADV_HOST"
            [[ ! -z "$SSL_EXTRA_HOSTS" ]] && SSL_HOSTS="$SSL_HOSTS,$SSL_EXTRA_HOSTS"

            # Create Key-Certificate pairs for Kafka and user
            for cert in kafka client; do
                quickcert -cacert lfddca.crt.pem -cakey lfddca.key.pem -out $cert. -CN "$cert" -hosts "$SSL_HOSTS" -duration 3650

                openssl pkcs12 -export \
                        -in "$cert.crt.pem" \
                        -inkey "$cert.key.pem" \
                        -out "$cert.p12" \
                        -name "$cert" \
                        -passout pass:fastdata

                keytool -importkeystore \
                        -noprompt -v \
                        -srckeystore "$cert.p12" \
                        -srcstoretype PKCS12 \
                        -srcstorepass fastdata \
                        -alias "$cert" \
                        -deststorepass fastdata \
                        -destkeypass fastdata \
                        -destkeystore "$cert.jks"
            done

            keytool -importcert \
                    -noprompt \
                    -keystore truststore.jks \
                    -alias LandoopFastDataDevCA \
                    -file lfddca.crt.pem \
                    -storepass fastdata

            cat <<EOF >>/var/run/broker/server.properties
ssl.client.auth=required
ssl.key.password=fastdata
ssl.keystore.location=$PWD/kafka.jks
ssl.keystore.password=fastdata
ssl.truststore.location=$PWD/truststore.jks
ssl.truststore.password=fastdata
ssl.protocol=TLS
ssl.enabled.protocols=TLSv1.2,TLSv1.1,TLSv1
ssl.keystore.type=JKS
ssl.truststore.type=JKS
EOF
            sed -r -e 's|^(listeners=.*)|\1,SSL://:'"${BROKER_SSL_PORT}"'|' \
                -i /var/run/broker/server.properties
            [[ ! -z "${ADV_HOST}" ]] \
                && sed -r -e 's|^(advertised.listeners=.*)|\1,'"SSL://${ADV_HOST}:${BROKER_SSL_PORT}"'|' \
                       -i /var/run/broker/server.properties

            mkdir -p /var/www/certs/
            cp client.jks truststore.jks /var/www/certs/

            popd
        } >/var/log/ssl-setup.log 2>&1
    fi
    sed -r -e 's|9093|'"${BROKER_SSL_PORT}"'|' \
        -i /var/www/env.js
    sed -e 's/ssl_browse/1/' -i /var/www/env.js
else
    sed -r -e 's|9093||' -i /var/www/env.js
fi

# Set web-only mode if needed
if echo "$WEB_ONLY" | grep -sqE "true|TRUE|y|Y|yes|YES|1"; then
    PORTS="$WEB_PORT"
    echo -e "\e[92mWeb only mode. Kafka services will be disabled.\e[39m"
    rm -rf /etc/supervisord.d/*
    cp /usr/local/share/etc/landoop/supervisord.d/supervisord-web-only.conf /etc/supervisord.d/
    cat /usr/local/share/landoop/etc/fast-data-dev-ui/env-webonly.js \
        | envsubst > /var/www/env.js
    export RUNTESTS="${RUNTESTS:-0}"
fi

# Set supervisord to output all logs to stdout
if echo "$DEBUG" | grep -sqE "true|TRUE|y|Y|yes|YES|1"; then
    sed -e 's/loglevel=info/loglevel=debug/' -i /etc/supervisord.d/*
fi

# Check for port availability
for port in $PORTS; do
    if ! /usr/local/bin/checkport -port "$port"; then
        echo "Could not successfully bind to port $port. Maybe some other service"
        echo "in your system is using it? Please free the port and try again."
        echo "Exiting."
        exit 1
    fi
done

# Check for Container's Memory Limit
MLMB="4096"
if [[ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]]; then
    MLB="$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)"
    MLMB="$(( MLB / 1024 / 1024 ))"
    MLREC=4096
    if [[ "$MLMB" -lt "$MLREC" ]]; then
        echo -e "\e[91mMemory limit for container is \e[93m${MLMB} MiB\e[91m, which is less than the lowest"
        echo -e "recommended of \e[93m${MLREC} MiB\e[91m. You will probably experience instability issues.\e[39m"
    fi
fi

# Check for Available RAM
RAKB="$(grep MemA /proc/meminfo | sed -r -e 's/.* ([0-9]+) kB/\1/')"
if [[ -z "$RAKB" ]]; then
        echo -e "\e[91mCould not detect available RAM, probably due to very old Linux Kernel."
        echo -e "\e[91mPlease make sure you have the recommended minimum of \e[93m4096 MiB\e[91m RAM available for fast-data-dev.\e[39m"
else
    RAMB="$(( RAKB / 1024 ))"
    RAREC=5120
    if [[ "$RAMB" -lt "$RAREC" ]]; then
        echo -e "\e[91mOperating system RAM available is \e[93m${RAMB} MiB\e[91m, which is less than the lowest"
        echo -e "recommended of \e[93m${RAREC} MiB\e[91m. Your system performance may be seriously impacted.\e[39m"
    fi
fi
# Check for Available Disk
DAM="$(df /tmp --output=avail -BM | tail -n1 | sed -r -e 's/M//' -e 's/[ ]*([0-9]+)[ ]*/\1/')"
if [[ -z "$DAM" ]] || ! [[ "$DAM" =~ ^[0-9]+$ ]]; then
    echo -e "\e[91mCould not detect available Disk space."
    echo -e "\e[91mPlease make sure you have the recommended minimum of \e[93m256 MiB\e[91m disk space available for '/tmp' directory.\e[39m"
else
    DAREC=256
    if [[ "$DAM" -lt $DAREC ]]; then
        echo -e "\e[91mDisk space available for the '/tmp' directory is just \e[93m${DAM} MiB\e[91m which is less than the lowest"
        echo -e "recommended of \e[93m${DAREC} MiB\e[91m. The container’s services may fail to start.\e[39m"
    fi
fi

PRINT_HOST="${ADV_HOST:-localhost}"
export PRINT_HOST
# shellcheck disable=SC1091
[[ -f /build.info ]] && source /build.info
echo -e "\e[92mStarting services.\e[39m"
echo -e "\e[92mThis is Landoop’s fast-data-dev. Kafka ${KAFKA_VERSION} (Landoop's Kafka Distribution).\e[39m"
echo -e "\e[34mYou may visit \e[96mhttp://${PRINT_HOST}:${WEB_PORT}\e[34m in about \e[96ma minute\e[34m.\e[39m"

# Set connect heap size if needed
CONNECT_HEAP_OPTS="${CONNECT_HEAP_OPTS:-$CONNECT_HEAP}"
export CONNECT_HEAP_OPTS="${CONNECT_HEAP_OPTS:--Xmx640M -Xms128M}"
export BROKER_HEAP_OPTS="${BROKER_HEAP_OPTS:--Xmx320M -Xms320M}"
export ZOOKEEPER_HEAP_OPTS="${ZOOKEEPER_HEAP_OPTS:--Xmx256M -Xms64M}"
export SCHEMA_REGISTRY_HEAP_OPTS="${SCHEMA_REGISTRY_HEAP_OPTS:--Xmx256M -Xms128M}"
export KAFKA_REST_HEAP_OPTS="${KAFKA_REST_HEAP_OPTS:--Xmx256M -Xms128M}"
#sed -e 's|{{CONNECT_HEAP}}|'"${CONNECT_HEAP}"'|' -i /etc/supervisord.d/*.conf

# Set sample data if needed
if echo "$RUNNING_SAMPLEDATA" | grep -sqE "true|TRUE|y|Y|yes|YES|1" && echo "$SAMPLEDATA" | grep -sqE "true|TRUE|y|Y|yes|YES|1"; then
        cp /usr/local/share/landoop/etc/supervisord.d/99-supervisord-running-sample-data.conf /etc/supervisord.d/
elif echo "$SAMPLEDATA" | grep -sqE "true|TRUE|y|Y|yes|YES|1"; then
    # This should be added only if we don't have running data, because it sets
    # retention period to 10 years (as the data is so few in this case).
    cp /usr/local/share/landoop/etc/supervisord.d/99-supervisord-sample-data.conf /etc/supervisord.d/
else
    # If SAMPLEDATA=0 and FORWARDLOGS connector not explicitly requested
    [[ -z "$FORWARDLOGS" ]] && export FORWARDLOGS=0
fi

exec /usr/bin/supervisord -c /etc/supervisord.conf

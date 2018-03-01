#!/usr/bin/env bash

set -e
set -u
set -o pipefail

TRUE_REG='^([tT][rR][uU][eE]|[yY]|[yY][eE][sS]|1)$'
FALSE_REG='^([fF][aA][lL][sS][eE]|[nN]|[nN][oO]|0)$'

DEBUG_SCRIPT=${DEBUG_SCRIPT:-false}
if [[ $DEBUG_SCRIPT =~ $TRUE_REG ]]; then set -x; fi

# Default values
export ZK_PORT=${ZK_PORT:-2181}
export ZK_JMX_PORT=${ZK_JMX_PORT:-9585}
export BROKER_PORT=${BROKER_PORT:-9092}
export BROKER_JMX_PORT=${BROKER_JMX_PORT:-9581}
export BROKER_SSL_PORT=${BROKER_SSL_PORT:-9093}
export REGISTRY_PORT=${REGISTRY_PORT:-8081}
export REGISTRY_JMX_PORT=${REGISTRY_JMX_PORT:-9582}
export CONNECT_PORT=${CONNECT_PORT:-8083}
export CONNECT_JMX_PORT=${CONNECT_JMX_PORT:-9584}
export REST_PORT=${REST_PORT:-8082}
export REST_JMX_PORT=${REST_JMX_PORT:-9583}
export WEB_PORT=${WEB_PORT:-3030}
RUN_AS_ROOT=${RUN_AS_ROOT:-false}
DISABLE_JMX=${DISABLE_JMX:-false}
ENABLE_SSL=${ENABLE_SSL:-false}
SSL_EXTRA_HOSTS=${SSL_EXTRA_HOSTS:-}
DEBUG=${DEBUG:-false}
export SAMPLEDATA=${SAMPLEDATA:-1}
export RUNNING_SAMPLEDATA=${RUNNING_SAMPLEDATA:-0}
DISABLE=${DISABLE:-}
CONNECTORS=${CONNECTORS:-}
export ADV_HOST=${ADV_HOST:-}
export ADV_HOST_JMX=${ADV_HOST:-localhost}
CONNECT_HEAP=${CONNECT_HEAP:-}
WEB_ONLY=${WEB_ONLY:-0}
export FORWARDLOGS=${FORWARDLOGS:-1}
export RUNTESTS=${RUNTESTS:-1}

# These ports are always used.
PORTS="$ZK_PORT $BROKER_PORT $REGISTRY_PORT $REST_PORT $CONNECT_PORT $WEB_PORT"

# Export versions so envsubst will work
source build.info
# shellcheck disable=SC2046
export $(cut -d= -f1 /build.info)

# Set env vars to configure Kafka
export KAFKA_BROKER_ID=${KAFKA_BROKER_ID:-0}
export KAFKA_NUM_NETWORK_THREADS=${KAFKA_NUM_NETWORK_THREADS:-2}
export KAFKA_NUM_IO_THREADS=${KAFKA_NUM_IO_THREADS:-4}
export KAFKA_LOG_DIRS=${KAFKA_LOG_DIRS:-/data/kafka/logdir}
#export KAFKA_NUM_PARTITIONS=${KAFKA_NUM_PARTITIONS:-1}
export KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=${KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR:-1}
export KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=${KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR:-1}
export KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=${KAFKA_TRANSACTION_STATE_LOG_MIN_ISR:-1}
export KAFKA_LOG_RETENTION_HOURS=${KAFKA_LOG_RETENTION_HOURS:-168}
export KAFKA_LOG_SEGMENT_BYTES=${KAFKA_LOG_SEGMENT_BYTES:-104857600}
export KAFKA_ZOOKEEPER_CONNECT=${KAFKA_ZOOKEEPER_CONNECT:-localhost:$ZK_PORT}
export KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS=${KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS:-1000}
export KAFKA_LISTENERS=${KAFKA_LISTENERS:-PLAINTEXT://:$BROKER_PORT}
export KAFKA_DELETE_TOPIC_ENABLE=${KAFKA_DELETE_TOPIC_ENABLE:-true}

# Set env vars to configure Schema Registry
export SCHEMA_REGISTRY_LISTENERS=${SCHEMA_REGISTRY_LISTENERS:-http://0.0.0.0:$REGISTRY_PORT}
export SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS=${SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS:-PLAINTEXT://:$BROKER_PORT}
export SCHEMA_REGISTRY_ACCESS_CONTROL_ALLOW_METHODS=${SCHEMA_REGISTRY_ACCESS_CONTROL_ALLOW_METHODS:-GET,POST,PUT,DELETE,OPTIONS}
export SCHEMA_REGISTRY_ACCESS_CONTROL_ALLOW_ORIGIN=${SCHEMA_REGISTRY_ACCESS_CONTROL_ALLOW_ORIGIN:-*}

# Set env vars for Kafka Connect Distributed
export CONNECT_BOOTSTRAP_SERVERS=${CONNECT_BOOTSTRAP_SERVERS:-PLAINTEXT://localhost:$BROKER_PORT}
export CONNECT_GROUP_ID=${CONNECT_GROUP_ID:-connect-fast-data}
export CONNECT_KEY_CONVERTER=${CONNECT_KEY_CONVERTER:-io.confluent.connect.avro.AvroConverter}
export CONNECT_KEY_CONVERTER_SCHEMA_REGISTRY_URL=${CONNECT_KEY_CONVERTER_SCHEMA_REGISTRY_URL:-http://localhost:$REGISTRY_PORT}
export CONNECT_VALUE_CONVERTER=${CONNECT_VALUE_CONVERTER:-io.confluent.connect.avro.AvroConverter}
export CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL=${CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL:-http://localhost:$REGISTRY_PORT}
export CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR=${CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR:-1}
export CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR=${CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR:-1}
export CONNECT_STATUS_STORAGE_REPLICATION_FACTOR=${CONNECT_STATUS_STORAGE_REPLICATION_FACTOR:-1}
export CONNECT_ACCESS_CONTROL_ALLOW_METHODS=${CONNECT_ACCESS_CONTROL_ALLOW_METHODS:-GET,POST,PUT,DELETE,OPTIONS}
export CONNECT_ACCESS_CONTROL_ALLOW_ORIGIN=${CONNECT_ACCESS_CONTROL_ALLOW_ORIGIN:-*}
export CONNECT_PLUGIN_PATH=${CONNECT_PLUGIN_PATH:-/var/run/connect/connectors/stream-reactor,/var/run/connect/connectors/third-party,/connectors}
export CONNECT_REST_PORT=${CONNECT_REST_PORT:-$CONNECT_PORT}
export CONNECT_INTERNAL_KEY_CONVERTER=${CONNECT_INTERNAL_KEY_CONVERTER:-org.apache.kafka.connect.json.JsonConverter}
export CONNECT_INTERNAL_KEY_CONVERTER_SCHEMAS_ENABLE=${CONNECT_INTERNAL_KEY_CONVERTER_SCHEMAS_ENABLE:-false}
export CONNECT_INTERNAL_VALUE_CONVERTER=${CONNECT_INTERNAL_VALUE_CONVERTER:-org.apache.kafka.connect.json.JsonConverter}
export CONNECT_INTERNAL_VALUE_CONVERTER_SCHEMAS_ENABLE=${CONNECT_INTERNAL_VALUE_CONVERTER_SCHEMAS_ENABLE:-false}
export CONNECT_CONFIG_STORAGE_TOPIC=${CONNECT_CONFIG_STORAGE_TOPIC:-connect-configs}
export CONNECT_OFFSET_STORAGE_TOPIC=${CONNECT_OFFSET_STORAGE_TOPIC:-connect-offsets}
export CONNECT_STATUS_STORAGE_TOPIC=${CONNECT_STATUS_STORAGE_TOPIC:-connect-statuses}

# Set env vars for REST Proxy
export KAFKA_REST_BOOTSTRAP_SERVERS=${KAFKA_REST_BOOTSTRAP_SERVERS:-PLAINTEXT://localhost:$BROKER_PORT}
export KAFKA_REST_ACCESS_CONTROL_ALLOW_METHODS=${KAFKA_REST_ACCESS_CONTROL_ALLOW_METHODS:-GET,POST,PUT,DELETE,OPTIONS}
export KAFKA_REST_ACCESS_CONTROL_ALLOW_ORIGIN=${KAFKA_REST_ACCESS_CONTROL_ALLOW_ORIGIN:-*}
export KAFKA_REST_LISTENERS=${KAFKA_REST_LISTENERS:-http://0.0.0.0:$REST_PORT}
export KAFKA_REST_SCHEMA_REGISTRY_URL=${KAFKA_REST_SCHEMA_REGISTRY_URL:-http://localhost:$REGISTRY_PORT}
# Next two lines are a fix for REST Proxy
export KAFKA_REST_CONSUMER_REQUEST_TIMEOUT_MS=${KAFKA_REST_CONSUMER_REQUEST_TIMEOUT_MS:-20000}
export KAFKA_REST_CONSUMER_MAX_POLL_INTERVAL_MS=${KAFKA_REST_CONSUMER_MAX_POLL_INTERVAL_MS:-18000}
export KAFKA_REST_ZOOKEEPER_CONNECT=${KAFKA_REST_ZOOKEEPER_CONNECT:-localhost:$ZK_PORT}

# Set env vars for ZOOKEEPER
export ZOOKEEPER_dataDir=${ZOOKEEPER_dataDir:-/data/zookeeper}
export ZOOKEEPER_clientPort=${ZOOKEEPER_clientPort:-$ZK_PORT}
export ZOOKEEPER_maxClientCnxns=${ZOOKEEPER_maxClientCnxnxs:-0}

# Set memory limits
# Set connect heap size if needed
CONNECT_HEAP_OPTS=${CONNECT_HEAP_OPTS:-$CONNECT_HEAP}
export CONNECT_HEAP_OPTS=${CONNECT_HEAP_OPTS:--Xmx640M -Xms128M}
export BROKER_HEAP_OPTS=${BROKER_HEAP_OPTS:--Xmx320M -Xms320M}
export ZOOKEEPER_HEAP_OPTS=${ZOOKEEPER_HEAP_OPTS:--Xmx256M -Xms64M}
export SCHEMA_REGISTRY_HEAP_OPTS=${SCHEMA_REGISTRY_HEAP_OPTS:--Xmx256M -Xms128M}
export KAFKA_REST_HEAP_OPTS=${KAFKA_REST_HEAP_OPTS:--Xmx256M -Xms128M}

# Configure JMX if needed or disable it.
if [[ ! $DISABLE_JMX =~ $TRUE_REG ]]; then
    # If JMX is not disabled, we should check for port availability
    PORTS="$PORTS $BROKER_JMX_PORT $REGISTRY_JMX_PORT $REST_JMX_PORT $CONNECT_JMX_PORT $ZK_JMX_PORT"
else
    # This does not really disable JMX, but each service will start JMX
    # in an ephemeral port, so it won't cause issues to the process.
    export ZK_JMX_PORT=0
    export BROKER_JMX_PORT=0
    export REGISTRY_JMX_PORT=0
    export CONNECT_JMX_PORT=0
    export REST_JMX_PORT=0
fi

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
      /var/run/other \
      /data/{zookeeper,kafka}
chmod 777 /data/{zookeeper,kafka}

# Copy log4j files
cp /opt/landoop/kafka/etc/kafka/log4j.properties \
   /var/run/zookeeper/
cp /opt/landoop/kafka/etc/kafka/log4j.properties \
   /var/run/broker/
cp /opt/landoop/kafka/etc/schema-registry/log4j.properties \
   /var/run/schema-registry/
cp /opt/landoop/kafka/etc/kafka/connect-log4j.properties \
   /var/run/connect/
cp /opt/landoop/kafka/etc/kafka-rest/log4j.properties \
   /var/run/rest-proxy/

# Copy tests
# This differs in that we need to adjust it later
cp /opt/landoop/tools/share/coyote/examples/simple-integration-tests.yml \
   /var/run/coyote/simple-integration-tests.yml
## Fix ports for integration-tests
sed -e "s/3030/$WEB_PORT/" \
    -e "s/2181/$ZK_PORT/" \
    -e "s/9092/$BROKER_PORT/" \
    -e "s/8081/$REGISTRY_PORT/" \
    -e "s/8082/$REST_PORT/" \
    -e "s/8083/$CONNECT_PORT/" \
    -i /var/run/coyote/simple-integration-tests.yml

# Copy other templated files (caddy, logs-to-kafka, env.js)
envsubst < /usr/local/share/landoop/etc/Caddyfile               > /var/run/caddy/Caddyfile
envsubst < /usr/local/bin/logs-to-kafka.sh                      > /var/run/other/logs-to-kafka.sh
envsubst < /usr/local/share/landoop/etc/fast-data-dev-ui/env.js > /var/www/env.js

# Set ADV_HOST if needed
if [[ ! -z ${ADV_HOST} ]]; then
    echo -e "\e[92mSetting advertised host to \e[96m${ADV_HOST}\e[34m\e[92m.\e[34m"
    export KAFKA_CONNECT_ADVERTISED_LISTENERS="PLAINTEXT://${ADV_HOST}:$BROKER_PORT"
    export CONNECT_REST_ADVERTISED_HOST_NAME=${ADV_HOST}
    sed -e "s#localhost#${ADV_HOST}#g" -i /var/run/coyote/simple-integration-tests.yml /var/www/env.js
fi

# setup Kafka (and components)
source /usr/local/share/landoop/config_kafka.sh

# setup supervisord
for service in /usr/local/share/landoop/etc/supervisord.templates.d/*.conf; do
    # shellcheck disable=SC2094
    envsubst < "$service" > /etc/supervisord.d/"$(basename "$service")"
done
# Disable services if asked
if [[ $ZK_PORT == 0 ]];       then rm /etc/supervisord.d/*zookeeper.conf; fi
if [[ $BROKER_PORT == 0 ]];   then rm /etc/supervisord.d/*broker.conf; fi
if [[ $REGISTRY_PORT == 0 ]]; then rm /etc/supervisord.d/*schema-registry.conf; fi
if [[ $CONNECT_PORT == 0 ]];  then rm /etc/supervisord.d/*connect-distributed.conf; fi
if [[ $REST_PORT == 0 ]];     then rm /etc/supervisord.d/*rest-proxy.conf; fi
if [[ $WEB_PORT == 0 ]];      then rm /etc/supervisord.d/*rest-proxy.conf; fi
if [[ $FORWARDLOGS =~ $FALSE_REG ]]; then rm /etc/supervisord.d/*logs-to-kafka.conf; fi
if [[ $RUNTESTS =~ $FALSE_REG ]]; then
    rm /etc/supervisord.d/*smoke-tests.conf
    cat <<EOF > /var/www/coyote-tests/results
{
  "passed": -1,
  "failed": 0
}
EOF
fi

# Set webserver basicauth username and password
USER=${USER:-kafka}
PASSWORD=${PASSWORD:-}
export USER
if [[ ! -z $PASSWORD ]]; then
    echo -e "\e[92mEnabling login credentials '\e[96m${USER}\e[34m\e[92m' '\e[96mxxxxxxxx'\e[34m\e[92m.\e[34m"
    echo "basicauth / \"${USER}\" \"${PASSWORD}\"" >> /var/run/caddy/Caddyfile
fi

# Disable Connectors
OLD_IFS=$IFS
IFS=,
if [[ -z $CONNECTORS ]] && [[ -z $DISABLE ]]; then
    DISABLE="random_string_hope_not_a_connector_name"
fi
if [[ -n $DISABLE ]]; then
    DISABLE=" ${DISABLE//,/ } "
    CONNECTOR_LIST="$(find /opt/landoop/connectors/stream-reactor -maxdepth 1 -name "kafka-connect-*" -type d | sed -e 's/.*kafka-connect-//' | tr '\n' ',')"
    for connector in $CONNECTOR_LIST; do
        connectorTest=" $connector "
        if [[ $DISABLE =~ $connectorTest ]]; then
            echo "Skipping connector: kafka-connect-${connector}"
        else
            ln -s /opt/landoop/connectors/stream-reactor/kafka-connect-"${connector}" \
               /var/run/connect/connectors/stream-reactor/kafka-connect-"${connector}"
        fi
    done
    CONNECTOR_LIST="$(find /opt/landoop/connectors/third-party -maxdepth 1 -name "kafka-connect-*" -type d | sed -e 's/.*kafka-connect-//' | tr '\n' ',')"
    for connector in $CONNECTOR_LIST; do
        connectorTest=" $connector "
        if [[ $DISABLE =~ $connectorTest ]]; then
            echo "Skipping connector: kafka-connect-${connector}"
        else
            ln -s /opt/landoop/connectors/third-party/kafka-connect-"${connector}" \
               /var/run/connect/connectors/third-party/kafka-connect-"${connector}"
        fi
    done
fi
# Enable Connectors
if [[ -n $CONNECTORS ]]; then
    CONNECTORS=" ${CONNECTORS//,/ } "
    CONNECTOR_LIST="$(find /opt/landoop/connectors/stream-reactor -maxdepth 1 -name "kafka-connect-*" -type d | sed -e 's/.*kafka-connect-//' | tr '\n' ',')"
    for connector in $CONNECTOR_LIST; do
        connectorTest=" $connector "
        if [[ $CONNECTORS =~ $connectorTest ]]; then
            echo "Enabling connector: kafka-connect-${connector}"
            ln -s /opt/landoop/connectors/stream-reactor/kafka-connect-"${connector}" \
               /var/run/connect/connectors/stream-reactor/kafka-connect-"${connector}"
        fi
    done
    CONNECTOR_LIST="$(find /opt/landoop/connectors/third-party -maxdepth 1 -name "kafka-connect-*" -type d | sed -e 's/.*kafka-connect-//' | tr '\n' ',')"
    for connector in $CONNECTOR_LIST; do
        connectorTest=" $connector "
        if [[ $CONNECTORS =~ $connectorTest ]]; then
            echo "Enabling connector: kafka-connect-${connector}"
            ln -s /opt/landoop/connectors/third-party/kafka-connect-"${connector}" \
               /var/run/connect/connectors/third-party/kafka-connect-"${connector}"
        fi
    done
fi
IFS="$OLD_IFS"

# Enable root-mode if needed
if [[ $RUN_AS_ROOT =~ $TRUE_REG ]]; then
    sed -e 's/user=nobody/;user=nobody/' -i /etc/supervisord.d/*
    echo -e "\e[92mRunning Kafka as root.\e[34m"
fi

# SSL setup
if [[ $ENABLE_SSL =~ $TRUE_REG ]]; then
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
            if [[ ! -z $ADV_HOST ]]; then SSL_HOSTS="$SSL_HOSTS,$ADV_HOST"; fi
            if [[ ! -z $SSL_EXTRA_HOSTS ]]; then SSL_HOSTS="$SSL_HOSTS,$SSL_EXTRA_HOSTS"; fi

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
            sed -r -e "s|^(listeners=.*)|\1,SSL://:${BROKER_SSL_PORT}|" \
                -i /var/run/broker/server.properties
            if [[ ! -z ${ADV_HOST} ]]; then
                sed -r \
                    -e "s|^(advertised.listeners=.*)|\1,SSL://${ADV_HOST}:${BROKER_SSL_PORT}|" \
                    -i /var/run/broker/server.properties
            fi

            mkdir -p /var/www/certs/
            cp client.jks truststore.jks /var/www/certs/

            popd
        } >/var/log/ssl-setup.log 2>&1
    fi
    sed -e 's/ssl_browse/1/' -i /var/www/env.js
else
    sed -r -e "s|$BROKER_SSL_PORT||" -i /var/www/env.js
fi

# Set web-only mode if needed
if [[ $WEB_ONLY =~ $TRUE_REG ]]; then
    PORTS="$WEB_PORT"
    echo -e "\e[92mWeb only mode. Kafka services will be disabled.\e[39m"
    rm -rf /etc/supervisord.d/*
    cp /usr/local/share/etc/landoop/supervisord.d/supervisord-web-only.conf /etc/supervisord.d/
    envsubst < /usr/local/share/landoop/etc/fast-data-dev-ui/env-webonly.js > /var/www/env.js
    export RUNTESTS="${RUNTESTS:-0}"
fi

# Set supervisord to output all logs to stdout
if [[ $DEBUG =~ $TRUE_REG ]]; then
    sed -e 's/loglevel=info/loglevel=debug/' -i /etc/supervisord.d/*
fi

# Check for port availability
for port in $PORTS; do
    if [[ $port == 0 ]]; then
        continue
    elif ! /usr/local/bin/checkport -port "$port"; then
        echo "Could not successfully bind to port $port. Maybe some other service"
        echo "in your system is using it? Please free the port and try again."
        echo "Exiting."
        exit 1
    fi
done

# Check for Container's Memory Limit
if [[ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]]; then
    MLB="$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)"
    MLMB="$(( MLB / 1024 / 1024 ))"
    MLREC=3584
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
    RAREC=4096
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

PRINT_HOST=${ADV_HOST:-localhost}
export PRINT_HOST
# shellcheck disable=SC1091
[[ -f /build.info ]] && source /build.info
echo -e "\e[92mStarting services.\e[39m"
echo -e "\e[92mThis is Landoop’s fast-data-dev. Kafka ${FDD_KAFKA_VERSION} (Landoop's Kafka Distribution).\e[39m"
echo -e "\e[34mYou may visit \e[96mhttp://${PRINT_HOST}:${WEB_PORT}\e[34m in about \e[96ma minute\e[34m.\e[39m"

# Set sample data if needed
if [[ $RUNNING_SAMPLEDATA =~ $TRUE_REG ]] && [[ $SAMPLEDATA =~ $TRUE_REG ]]; then
    cp /usr/local/share/landoop/etc/supervisord.d/99-supervisord-running-sample-data.conf /etc/supervisord.d/
elif [[ $SAMPLEDATA =~ $TRUE_REG ]]; then
    # This should be added only if we don't have running data, because it sets
    # retention period to 10 years (as the data is so few in this case).
    cp /usr/local/share/landoop/etc/supervisord.d/99-supervisord-sample-data.conf /etc/supervisord.d/
else
    # If SAMPLEDATA=0 and FORWARDLOGS connector not explicitly requested
    export FORWARDLOGS=0
fi

exec /usr/bin/supervisord -c /etc/supervisord.conf

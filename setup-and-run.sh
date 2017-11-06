#!/usr/bin/env bash

ZK_PORT="${ZK_PORT:-2181}"
BROKER_PORT="${BROKER_PORT:-9092}"
BROKER_SSL_PORT="${BROKER_SSL_PORT:-9093}"
REGISTRY_PORT="${REGISTRY_PORT:-8081}"
REST_PORT="${REST_PORT:-8082}"
CONNECT_PORT="${CONNECT_PORT:-8083}"
WEB_PORT="${WEB_PORT:-3030}"
#KAFKA_MANAGER_PORT="3031"
RUN_AS_ROOT="${RUN_AS_ROOT:false}"
ZK_JMX_PORT="9585"
BROKER_JMX_PORT="9581"
REGISTRY_JMX_PORT="9582"
REST_JMX_PORT="9583"
CONNECT_JMX_PORT="9584"
DISABLE_JMX="${DISABLE_JMX:false}"
ENABLE_SSL="${ENABLE_SSL:false}"
SSL_EXTRA_HOSTS="${SSL_EXTRA_HOSTS:-}"
DEBUG="${DEBUG:-false}"
TOPIC_DELETE="${TOPIC_DELETE:-true}"
SAMPLEDATA="${SAMPLEDATA:-1}"
RUNNING_SAMPLEDATA="${RUNNING_SAMPLEDATA:-0}"

PORTS="$ZK_PORT $BROKER_PORT $REGISTRY_PORT $REST_PORT $CONNECT_PORT $WEB_PORT $KAFKA_MANAGER_PORT"

# Set webserver basicauth username and password
USER="${USER:-kafka}"
if [[ ! -z "$PASSWORD" ]]; then
    echo -e "\e[92mEnabling login credentials '\e[96m${USER}\e[34m\e[92m' '\e[96m${PASSWORD}'\e[34m\e[92m.\e[34m"
    echo "basicauth / \"${USER}\" \"${PASSWORD}\"" >> /usr/share/landoop/Caddyfile
fi

# Adjust custom ports

## Some basic replacements
sed -e 's/2181/'"$ZK_PORT"'/' -e 's/8081/'"$REGISTRY_PORT"'/' -e 's/9092/'"$BROKER_PORT"'/' -i \
    /opt/confluent/etc/kafka/zookeeper.properties \
    /opt/confluent/etc/kafka/server.properties \
    /opt/confluent/etc/schema-registry/schema-registry.properties \
    /opt/confluent/etc/schema-registry/connect-avro-distributed.properties

## Broker specific
cat <<EOF >>/opt/confluent/etc/kafka/server.properties

listeners=PLAINTEXT://:$BROKER_PORT
confluent.support.metrics.enable=false
EOF

## Disabled because the basic replacements catch it
# cat <<EOF >>/opt/confluent/etc/schema-registry/schema-registry.properties

# listeners=http://0.0.0.0:$REGISTRY_PORT
# EOF

## REST Proxy specific
cat <<EOF >>/opt/confluent/etc/kafka-rest/kafka-rest.properties

listeners=http://0.0.0.0:$REST_PORT
schema.registry.url=http://localhost:$REGISTRY_PORT
zookeeper.connect=localhost:$ZK_PORT
# fix for Kafka REST consumer issues
consumer.request.timeout.ms=30000
EOF

## Schema Registry specific
cat <<EOF >>/opt/confluent/etc/schema-registry/connect-avro-distributed.properties

rest.port=$CONNECT_PORT
EOF

## Other infra specific (caddy, web ui, tests, logs)
sed -e 's/3030/'"$WEB_PORT"'/' -e 's/2181/'"$ZK_PORT"'/' -e 's/9092/'"$BROKER_PORT"'/' \
    -e 's/8081/'"$REGISTRY_PORT"'/' -e 's/8082/'"$REST_PORT"'/' -e 's/8083/'"$CONNECT_PORT"'/' \
    -i /usr/share/landoop/Caddyfile \
       /var/www/env.js \
       /usr/share/landoop/kafka-tests.yml \
       /usr/local/bin/logs-to-kafka.sh

# Allow for topic deletion by default, unless TOPIC_DELETE is set
if echo "$TOPIC_DELETE" | grep -sqE "true|TRUE|y|Y|yes|YES|1"; then
    cat <<EOF >>/opt/confluent/etc/kafka/server.properties
delete.topic.enable=true
EOF
fi

## TODO: deprecate
# Remove ElasticSearch if needed
PREFER_HBASE="${PREFER_HBASE:-false}"
if echo "$PREFER_HBASE" | grep -sqE "true|TRUE|y|Y|yes|YES|1"; then
    rm -rf /extra-connect-jars/* /opt/confluent-*/share/java/kafka-connect-elastic*
    echo -e "\e[92mFixing HBase connector: Removing ElasticSearch and Twitter connector.\e[39m"
fi

# Disable Connectors
OLD_IFS="$IFS"
IFS=","
for connector in $DISABLE; do
    echo "Disabling connector: kafka-connect-${connector}"
    rm -rf "/opt/confluent/share/java/kafka-connect-${connector}"
    [[ "elastic" == "$connector" ]] && rm -rf /extra-connect-jars/*
done
IFS="$OLD_IFS"

# Set ADV_HOST if needed
if [[ ! -z "${ADV_HOST}" ]]; then
    echo -e "\e[92mSetting advertised host to \e[96m${ADV_HOST}\e[34m\e[92m.\e[34m"
    echo -e "\nadvertised.listeners=PLAINTEXT://${ADV_HOST}:$BROKER_PORT" \
         >> /opt/confluent/etc/kafka/server.properties
    echo -e "\nrest.advertised.host.name=${ADV_HOST}" \
         >> /opt/confluent/etc/schema-registry/connect-avro-distributed.properties
    sed -e 's#localhost#'"${ADV_HOST}"'#g' -i /usr/share/landoop/kafka-tests.yml /var/www/env.js /etc/supervisord.d/*
fi

# Configure JMX if needed or disable it.
if ! echo "$DISABLE_JMX" | grep -sqE "true|TRUE|y|Y|yes|YES|1"; then
    PORTS="$PORTS $BROKER_JMX_PORT $REGISTRY_JMX_PORT $REST_JMX_PORT $CONNECT_JMX_PORT $ZK_JMX_PORT"
    sed -r -e 's/^;(environment=JMX_PORT)/\1/' \
        -e 's/^environment=VCON=1,KAFKA_HEAP_OPTS/environment=JMX_PORT='"$CONNECT_JMX_PORT"',KAFKA_HEAP_OPTS/' \
        -i /etc/supervisord.d/*
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
    echo -e "\e[92mTLS enabled. Creating CA and key-cert pairs.\e[34m"
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

        cat <<EOF >>/opt/confluent/etc/kafka/server.properties
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
            -i /opt/confluent/etc/kafka/server.properties
        [[ ! -z "${ADV_HOST}" ]] \
            && sed -r -e 's|^(advertised.listeners=.*)|\1,'"SSL://${ADV_HOST}:${BROKER_SSL_PORT}"'|' \
                   -i /opt/confluent/etc/kafka/server.properties

        mkdir /var/www/certs/
        cp client.jks truststore.jks /var/www/certs/

        popd
    } >/var/log/ssl-setup.log 2>&1
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
    cp /usr/share/landoop/supervisord-web-only.conf /etc/supervisord.d/*
    cp /var/www/env-webonly.js /var/www/env.js
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
# shellcheck disable=SC1091
[[ -f /build.info ]] && source /build.info
echo -e "\e[92mStarting services.\e[39m"
echo -e "\e[92mThis is landoop’s fast-data-dev. Kafka $KAFKA_VERSION, Confluent OSS $CP_VERSION.\e[39m"
echo -e "\e[34mYou may visit \e[96mhttp://${PRINT_HOST}:${WEB_PORT}\e[34m in about \e[96ma minute\e[34m.\e[39m"

# Set connect heap size if needed
CONNECT_HEAP="${CONNECT_HEAP:-1G}"
sed -e 's|{{CONNECT_HEAP}}|'"${CONNECT_HEAP}"'|' -i /etc/supervisord.d/*.conf

# Set sample data if needed
if echo "$RUNNING_SAMPLEDATA" | grep -sqE "true|TRUE|y|Y|yes|YES|1"; then
    if echo "$SAMPLEDATA" | grep -sqE "true|TRUE|y|Y|yes|YES|1"; then
        cp /usr/share/landoop/99-supervisord-running-sample-data.conf /etc/supervisord.d/
    fi
elif echo "$SAMPLEDATA" | grep -sqE "true|TRUE|y|Y|yes|YES|1"; then
    # This should be added only if we don't have running data, because it sets
    # retention period to 10 years (as the data is so few in this case).
    cp /usr/share/landoop/99-supervisord-sample-data.conf /etc/supervisord.d/
else
    # If SAMPLEDATA=0 and FORWARDLOGS connector not explicitly requested
    [[ -z "$FORWARDLOGS" ]] && export FORWARDLOGS=0
fi

exec /usr/bin/supervisord -c /etc/supervisord.conf

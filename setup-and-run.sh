#!/usr/bin/env bash

ZK_PORT="${ZK_PORT:-2181}"
BROKER_PORT="${BROKER_PORT:-9092}"
REGISTRY_PORT="${REGISTRY_PORT:-8081}"
REST_PORT="${REST_PORT:-8082}"
CONNECT_PORT="${CONNECT_PORT:-8083}"
WEB_PORT="${WEB_PORT:-3030}"
#KAFKA_MANAGER_PORT="3031"
RUN_AS_ROOT="${RUN_AS_ROOT:false}"

PORTS="$ZK_PORT $BROKER_PORT $REGISTRY_PORT $REST_PORT $CONNECT_PORT $WEB_PORT $KAFKA_MANAGER_PORT"

if echo $WEB_ONLY | egrep -sq "true|TRUE|y|Y|yes|YES|1"; then
    PORTS="$WEB_PORT"
fi

# Check for port availability
for port in $PORTS; do
    if ! /usr/local/bin/checkport -port $port; then
        echo "Could not successfully bind to port $port. Maybe some other service"
        echo "in your system is using it? Please free the port and try again."
        echo "Exiting."
        exit 1
    fi
done

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

# Remove ElasticSearch if needed
PREFER_HBASE="${PREFER_HBASE:-false}"
if echo $PREFER_HBASE | egrep -sq "true|TRUE|y|Y|yes|YES|1"; then
    rm -rf /extra-connect-jars/* /opt/confluent-*/share/java/kafka-connect-elastic*
    echo -e "\e[92mFixing HBase connector: Removing ElasticSearch and Twitter connector.\e[39m"
fi

# Disable Connectors
OLD_IFS="$IFS"
IFS=","
for connector in $DISABLE; do
    echo "Disabling connector: kafka-connect-${connector}"
    rm -rf "/opt/confluent/share/java/kafka-connect-${connector}"
    [[ "elastic" == $connector ]] && rm -rf /extra-connect-jars/*
done
IFS="$OLD_IFS"

# Set ADV_HOST if needed
if [[ ! -z "${ADV_HOST}" ]]; then
    echo -e "\e[92mSetting advertised host to \e[96m${ADV_HOST}\e[34m\e[92m.\e[34m"
    echo -e "\nadvertised.listeners=PLAINTEXT://${ADV_HOST}:$BROKER_PORT" \
         >> /opt/confluent/etc/kafka/server.properties
    echo -e "\nrest.advertised.host.name=${ADV_HOST}" \
         >> /opt/confluent/etc/kafka/connect-distributed.properties
    sed -e 's#localhost#'"${ADV_HOST}"'#g' -i /usr/share/landoop/kafka-tests.yml /var/www/env.js
fi

# Enable root-mode if needed
if egrep -sq "true|TRUE|y|Y|yes|YES|1" <<<"$RUN_AS_ROOT" ; then
    sed -e 's/user=nobody/;user=nobody/' -i /etc/supervisord.conf
    echo -e "\e[92mRunning Kafka as root.\e[34m"
fi

# Set web-only mode if needed
if echo $WEB_ONLY | egrep -sq "true|TRUE|y|Y|yes|YES|1"; then
    echo -e "\e[92mWeb only mode. Kafka services will be disabled.\e[39m"
    cp /usr/share/landoop/supervisord-web-only.conf /etc/supervisord.conf
    cp /var/www/env-webonly.js /var/www/env.js
fi

PRINT_HOST="${ADV_HOST:-localhost}"
echo -e "\e[92mStarting services.\e[39m"
echo -e "\e[34mYou may visit \e[96mhttp://${PRINT_HOST}:${WEB_PORT}\e[34m in about a minute.\e[39m"

# Set connect heap size if needed
CONNECT_HEAP="${CONNECT_HEAP:-1G}"
sed -e 's|{{CONNECT_HEAP}}|'"${CONNECT_HEAP}"'|' -i /etc/supervisord.conf

exec /usr/bin/supervisord -c /etc/supervisord.conf

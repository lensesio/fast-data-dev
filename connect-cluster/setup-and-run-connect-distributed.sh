#!/usr/bin/env bash

ID="${ID:-fast-data-dev-default}"
BS="${BS:-localhost:9092}"
ZK="${ZK:-localhost:2181}"
SR="${SR:-http://localhost:8081}"
CONNECT_HEAP="${CONNECT_HEAP:-1024M}"

# Set-up ID, bootstrap server, zookeeper connect and schema registry
sed -r \
    -e 's|bootstrap\.servers=.*|bootstrap.servers='"$BS"'|' \
    -e 's|(group\.id=.*)|\1-'"$ID"'|' \
    -e 's%(config|offset|status)(\.storage\.topic=.*)%\1\2-'"$ID"'%' \
    -e 's%(key|value)(\.converter\.schema\.registry\.url=).*%\1\2'"$SR"'%' \
    -i /opt/confluent/etc/schema-registry/connect-avro-distributed.properties
cat <<EOF>>/opt/confluent/etc/schema-registry/connect-avro-distributed.properties
zookeeper.connect=%ZK%
key.converter.schemas.enable=true
value.converter.schemas.enable=true
EOF

# Set-up advertised host name if set
if [[ ! -z "$HOST" ]]; then
    echo "rest.advertised.host.name=$HOST" \
        | tee -a /opt/confluent/etc/schema-registry/connect-avro-distributed.properties
    sed -e 's|localhost|'"$HOST"'|' -i /etc/supervisord.conf
fi

# Set-up port if set
[[ ! -z "$PORT" ]] && echo "rest.port=$PORT" \
        | tee -a /opt/confluent/etc/schema-registry/connect-avro-distributed.properties

PORT="${PORT:-8083}"
if ! /usr/local/bin/checkport -port "$PORT"; then
    echo "Could not succesfully bind to port $PORT. Maybe some other service"
    echo "in your system is using it? Please free the port and try again."
    echo "Exiting."
    exit 1
fi

JMX_PORT=9584
if ! /usr/local/bin/checkport -port "$JMX_PORT"; then
    echo "Could not succesfully bind to JMX port $JMX_PORT. Maybe some other service"
    echo "in your system is using it? Please free the port and try again."
    echo "Exiting."
    exit 1
fi

sed -e 's/{{CONNECT_HEAP}}/'"$CONNECT_HEAP"'/' -i /etc/supervisord.conf

exec /usr/bin/supervisord -c /etc/supervisord.conf

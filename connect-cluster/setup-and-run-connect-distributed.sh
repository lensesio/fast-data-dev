#!/usr/bin/env bash

ID="${ID:-fast-data-dev-default}"
BS="${BS:-localhost:9092}"
ZK="${ZK:-localhost:2181}"
SR="${SR:-http://localhost:8081}"

# Set-up ID, bootstrap server, zookeeper connect and schema registry
sed -e 's|%ID%|'"$ID"'|g' \
    -e 's|%BS%|'"$BS"'|g' \
    -e 's|%ZK%|'"$ZK"'|g' \
    -e 's|%SR%|'"$SR"'|g' \
    -i /usr/share/landoop/connect-distributed.properties

# Set-up advertised host name if set
[[ ! -z "$HOST" ]] && echo "rest.advertised.host.name=$HOST" | tee -a /usr/share/landoop/connect-distributed.properties
# Set-up port if set
[[ ! -z "$PORT" ]] && echo "rest.port=$PORT" | tee -a /usr/share/landoop/connect-distributed.properties

PORT="${PORT:-8083}"
if ! /usr/local/bin/checkport -port "$PORT"; then
    echo "Could not succesfully bind to port $port. Maybe some other service"
    echo "in your system is using it? Please free the port and try again."
    echo "Exiting."
    exit 1
fi

exec /opt/confluent-3.1.2/bin/connect-distributed /usr/share/landoop/connect-distributed.properties

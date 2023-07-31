#!/bin/bash

CONNECT_PORT=${CONNECT_PORT:-8083}
ELASTICSEARCH_TRANSPORT_PORT=${ELASTICSEARCH_TRANSPORT_PORT:-9300}
ELASTIC_SHIPS="${ELASTIC_SHIPS:-1}"
W_ELASTIC_ADDRESS=${W_ELASTIC_ADDRESS:-localhost}
W_ELASTIC_PORT=${W_ELASTIC_PORT:-$ELASTICSEARCH_PORT}
W_LENSES_ADDRESS=${W_LENSES_ADDRESS:-localhost}
W_LENSES_PORT=${W_LENSES_PORT:-$LENSES_PORT}

TRUE_REG='^([tT][rR][uU][eE]|[yY]|[yY][eE][sS]|1)$'
FALSE_REG='^([fF][aA][lL][sS][eE]|[nN]|[nN][oO]|0)$'

if [[ $ELASTIC_SHIPS =~ $FALSE_REG ]] \
       || [[ $CONNECT_PORT == 0 ]] \
       || [[ $ELASTICSEARCH_TRANSPORT_PORT == 0 ]] \
       || [[ $ELASTICSEARCH_PORT == 0 ]]; then
    echo "Skipping elastic-ships connector."
    exit 0
fi

LENSES_URL="http://$W_LENSES_ADDRESS:$W_LENSES_PORT$LENSES_ROOT_PATH"

# Create index and map geo_point value
curl -XPUT "http://${W_ELASTIC_ADDRESS}:${W_ELASTIC_PORT}/sea-vessel-position-reports?pretty" \
     -H 'Content-Type: application/json' \
     -d'
{
  "settings" : {
    "index" : {
       "number_of_shards" : 3,
       "number_of_replicas" : 1
    }
  }
}'
curl -X POST "http://${W_ELASTIC_ADDRESS}:${W_ELASTIC_PORT}/sea-vessel-position-reports/sea-vessel-position-reports/_mapping" \
     -H 'Content-Type: application/json' \
     -d '{
   "sea-vessel-position-reports" : {
   "properties" : {
       "location" : { "type" : "geo_point"}
   }}
}'

sleep 1;

# Create connector
cat <<EOF >/tmp/connector-elastic-ships
{
  "name": "elastic-ships",
  "config": {
    "connector.class": "com.datamountaineer.streamreactor.connect.elastic6.ElasticSinkConnector",
    "topics": "sea_vessel_position_reports",
    "connect.elastic.protocol": "http",
    "connect.elastic.hosts": "localhost",
    "connect.elastic.port": "$ELASTICSEARCH_PORT",
    "connect.elastic.kcql": "INSERT INTO sea-vessel-position-reports SELECT * FROM sea_vessel_position_reports",
    "connect.elastic.cluster.name": "lenses-box"
  }
}
EOF

# We can create the connector only if the Elasticsearch 6 plugin is loaded
if curl "http://localhost:$CONNECT_PORT/connector-plugins" | grep -sq "elastic6"; then
    curl -vs --stderr - -X POST -H "Content-Type: application/json" \
         --data @/tmp/connector-elastic-ships "http://localhost:$CONNECT_PORT/connectors"
fi

rm -f /tmp/connector-elastic-ships

# Create ES connection
curl \
    -H "Content-Type:application/json" \
    -H "x-kafka-lenses-token:$(curl -H "Content-Type:application/json" -X POST -d '{"user":"admin",  "password":"admin"}' http://$W_LENSES_ADDRESS:$W_LENSES_PORT/api/login --compressed -s)" \
    "$LENSES_URL/api/v1/connection/connections" \
    -XPOST -d "{\"name\":\"ES-1\",\"templateName\":\"Elasticsearch\",\"configuration\":[{\"key\":\"nodes\",\"value\":[\"http://${W_ELASTIC_ADDRESS}:${W_ELASTIC_PORT}\"]}],\"tags\":[\"preview\"]}"


USER=${USER:-admin}
PASSWORD=${PASSWORD:-admin}
sleep 20
lenses-cli \
    --user "${USER}" --pass "${PASSWORD}" --host "$LENSES_URL" \
    dataset update-tags --connection=ES-1 --name=sea-vessel-position-reports \
    --tag transport --tag external --tag filtered

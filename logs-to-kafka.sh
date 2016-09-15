#!/bin/bash

LOGS=(broker schema-registry rest-proxy connect-distributed zookeeper)

for (( i=0; i<=4; i++)); do
cat <<EOF >/tmp/connector
{
  "name": "logs-${LOGS[$i]}",
  "config": {
    "connector.class": "org.apache.kafka.connect.file.FileStreamSourceConnector",
    "tasks.max": "1",
    "topic": "logs-${LOGS[$i]}",
    "file":"/var/log/${LOGS[$i]}.log"
  }
}
EOF

    curl -vs --stderr - -X POST -H "Content-Type: application/json" \
         --data @/tmp/connector "http://localhost:8083/connectors"
done

rm /tmp/connector


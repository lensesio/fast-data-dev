#!/bin/bash

NULLSINK="${NULLSINK:-1}"
# Only topics of the same type (AVRO) below.
TOPICS="nyc_yellow_taxi_trip_data,reddit_posts,sea_vessel_position_reports,telecom_italia_data"

if [[ "$NULLSINK" == "0" ]]; then
    echo "Skipping nullsink connector."
    exit 0
fi

cat <<EOF >/tmp/connector-nullsink
{
  "name": "nullsink",
  "config": {
    "connector.class": "org.apache.kafka.connect.file.FileStreamSinkConnector",
    "tasks.max": "4",
    "topics": "$TOPICS",
    "file":"/dev/null"
  }
}
EOF

curl -vs --stderr - -X POST -H "Content-Type: application/json" \
     --data @/tmp/connector-nullsink "http://localhost:8083/connectors"

rm /tmp/connector-nullsink



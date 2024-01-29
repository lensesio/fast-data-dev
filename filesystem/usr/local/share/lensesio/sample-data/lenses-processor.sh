#!/usr/bin/env bash

set -o pipefail

USER=${USER:-admin}
PASSWORD=${PASSWORD:-admin}

SRC_TP="sea_vessel_position_reports"
PROC_SQL="SET defaults.topic.autocreate=true;

INSERT INTO fast_vessel_processor
    SELECT STREAM MMSI, Speed, Longitude AS Long, Latitude AS Lat, \`Timestamp\`
    FROM ${SRC_TP}
    WHERE Speed > 10;"

if [[ "${LENSES_PORT}" == "0" ]]; then
    echo "Lenses is disabled. Skipping processor."
    exit 0
fi

# Wait for Lenses to get up if needed and see the topic
for ((i=0;i<60;i++)); do
    sleep 5
    if lenses-cli --timeout 3s --user "${USER}" --pass "${PASSWORD}" --host "http://${GENERATOR_LENSES}" topics \
            | grep ${SRC_TP} | grep -E "AVRO\s*AVRO"; then
        sleep 30
        break
    fi
done

_PROCESSOR_NAME=filter_fast_vessels

lenses-cli \
    --user "${USER}" --pass "${PASSWORD}" --host "http://${GENERATOR_LENSES}" \
    processor \
    create \
    --name="$_PROCESSOR_NAME" \
    --sql="${PROC_SQL}"

lenses-cli \
    --user "${USER}" --pass "${PASSWORD}" --host "http://${GENERATOR_LENSES}" \
    processor \
    start \
    --name="$_PROCESSOR_NAME"


sleep 3
lenses-cli \
    --user "${USER}" --pass "${PASSWORD}" --host "http://${GENERATOR_LENSES}" \
    dataset update-tags --connection=kafka --name=fast_vessel_processor \
    --tag transport

#!/usr/bin/env bash

USER=${USER:-admin}
PASSWORD=${PASSWORD:-admin}

SRC_TP="sea_vessel_position_reports"
PROC_SQL="SET autocreate=true;

INSERT INTO fast_vessel_processor
    SELECT MMSI, Speed, Longitude AS Long, Latitude AS Lat, \`Timestamp\`
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
            | grep ${SRC_TP} | grep -sqE "AVRO\s*AVRO"; then
        sleep 5
        break
    fi
done

lenses-cli \
    --user "${USER}" --pass "${PASSWORD}" --host "http://${GENERATOR_LENSES}" \
    processor \
    create \
    --name=filter_fast_vessels \
    --sql="${PROC_SQL}"

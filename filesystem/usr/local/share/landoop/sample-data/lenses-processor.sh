#!/usr/bin/env bash

LENSES_PORT=${LENSES_PORT:-9991}
USER=${USER:-admin}
PASSWORD=${PASSWORD:-admin}

LEN_HOST="http://localhost"
SRC_TP="sea_vessel_position_reports"
PROC_SQL="SET autocreate=true;
INSERT INTO fast_vessel_processor
SELECT MMSI, Speed, Longitude AS Long, Latitude AS Lat, \`Timestamp\`
FROM ${SRC_TP}
WHERE Speed > 10 AND _ktype=AVRO AND _vtype=AVRO"

if [[ "${LENSES_PORT}" -ne '0' ]]; then
  # Wait for Lenses to get up if needed and see the topic
  for ((i=0;i<60;i++)); do
    sleep 5
    if lenses-cli --timeout 3s --user "$USER" --pass "$PASSWORD" --host "${LEN_HOST}:$LENSES_PORT" topics | grep -sq "${SRC_TP}"; then
      _col1="$(lenses-cli --timeout 3s --user "${USER}" --pass "${PASSWORD}" --host "${LEN_HOST}:$LENSES_PORT" topics \
      | grep ${SRC_TP} | awk -F ' ' '{print $2}')"

      _col2="$(lenses-cli --timeout 3s --user "${USER}" --pass "${PASSWORD}" --host "${LEN_HOST}:$LENSES_PORT" topics \
      | grep ${SRC_TP} | awk -F ' ' '{print $3}')"

      if [[ "${_col1}" == "${_col2}" ]]; then
        unset _col1 _col2
        sleep 5; break
      fi
    fi
  done
  lenses-cli --user "${USER}" --pass "${PASSWORD}" --host "${LEN_HOST}:3030" processor create --name=filter_fast_vessels --sql="${PROC_SQL}"
fi

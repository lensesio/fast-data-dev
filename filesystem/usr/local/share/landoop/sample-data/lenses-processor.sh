#!/usr/bin/env bash

LENSES_PORT=${LENSES_PORT:-9991}
USER=${USER:-admin}
PASSWORD=${PASSWORD:-admin}

# Wait for Lenses to get up if needed and see the topic
for ((i=0;i<30;i++)); do
   sleep 5
   lenses-cli --timeout 3s --user "$USER" --pass "$PASSWORD" --host http://127.0.0.1:$LENSES_PORT topics \
   | grep -sq "sea_vessel_position_reports" && { sleep 2; break; };
done

lenses-cli --user admin --pass admin --host http://localhost:3030 processor create --name=filter_fast_vessels --sql="SET autocreate=true;
       INSERT INTO fast_vessel_processor
       SELECT MMSI, Speed, Longitude AS Long, Latitude AS Lat, \`Timestamp\`
       FROM sea_vessel_position_reports
       WHERE Speed > 10 AND _ktype=AVRO AND _vtype=AVRO"

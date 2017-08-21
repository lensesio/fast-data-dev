#!/usr/bin/env bash

pushd /usr/share/landoop/sample-data

TOPICS=(sea_vessel_position_reports reddit_posts nyc_yellow_taxi_trip_data)
PARTITIONS=(3 5 1)
DATA=(ais.txt.gz reddit.may2015.30k.wkey.json.xz yellow_tripdata_2016-Jan_May.100k.json.xz)
VALUES=(classAPositionReportSchema.json reddit.value.json nyc_trip_records_yellow.value.json)
KEYS=(classAPositionReportSchemaKey.json reddit.key.json)
COMPRESSION=(uncompressed lz4 gzip)
RATES=(50 75 100)
JITTER=(5 50 25)
PERIOD=(10s 20s 25s)

# Create Topics
for key in 1; do
    # Create topic with x partitions and a retention size of 50MB, log segment
    # size of 20MB and compression type y.
    kafka-topics \
        --zookeeper localhost:2181 \
        --topic ${TOPICS[key]} \
        --partitions ${PARTITIONS[key]} \
        --replication-factor 1 \
        --config retention.bytes=52428800 \
        --config compression.type=${COMPRESSION[key]} \
        --config segment.bytes=20971520 \
        --create
done

# Insert data with key
for key in 1; do
    /usr/local/bin/normcat -r ${RATES[key]} -j ${JITTER[key]} -p ${PERIOD[key]} -c -v ${DATA[key]} | \
        kafka-avro-console-producer \
            --broker-list localhost:9092 \
            --topic ${TOPICS[key]} \
            --property parse.key=true \
            --property key.schema="$(cat ${KEYS[key]})" \
            --property value.schema="$(cat ${VALUES[key]})" \
            --property schema.registry.url=http://localhost:8081
done

popd

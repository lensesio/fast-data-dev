#!/usr/bin/env bash
SAMPLEDATA="${SAMPLEDATA:-1}"

if echo "$SAMPLEDATA" | egrep -sq "true|TRUE|y|Y|yes|YES|1"; then
    pushd /usr/share/landoop/sample-data

    TOPICS=(sea_vessel_position_reports reddit_posts nyc_yellow_taxi_trip_data)
    PARTITIONS=(3 5 1)
    DATA=(ais.txt.gz reddit.may2015.30k.wkey.json.xz yellow_tripdata_2016-Jan_May.100k.json.xz)
    VALUES=(classAPositionReportSchema.json reddit.value.json nyc_trip_records_yellow.value.json)
    KEYS=(classAPositionReportSchemaKey.json reddit.key.json)

    # Create Topics
    for key in 0 1 2; do
        # Create topic with x partitions and a retention time of 10 years.
        kafka-topics \
            --zookeeper localhost:2181 \
            --topic ${TOPICS[key]} \
            --partitions ${PARTITIONS[key]} \
            --replication-factor 1 \
            --config retention.ms=315576000000 \
            --create
    done

    # Insert data with keys
    for key in 0 1; do
        /usr/local/bin/normcat ${DATA[key]} | \
            kafka-avro-console-producer \
                --broker-list localhost:9092 \
                --topic ${TOPICS[key]} \
                --property parse.key=true \
                --property key.schema="$(cat ${KEYS[key]})" \
                --property value.schema="$(cat ${VALUES[key]})" \
                --property schema.registry.url=http://localhost:8081
    done

    # Insert data without keys
    for key in 2; do
        /usr/local/bin/normcat ${DATA[key]} | \
            kafka-avro-console-producer \
                --broker-list localhost:9092 \
                --topic ${TOPICS[key]} \
                --property value.schema="$(cat ${VALUES[key]})" \
                --property schema.registry.url=http://localhost:8081
    done

    popd
fi

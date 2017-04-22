#!/usr/bin/env bash
SAMPLEDATA="${SAMPLEDATA:-1}"

if echo "$SAMPLEDATA" | egrep -sq "true|TRUE|y|Y|yes|YES|1"; then
    pushd /usr/share/landoop/sample-data

    # Create topic with 5 partitions and a retention time of 10 years.
    kafka-topics \
        --zookeeper localhost:2181 \
        --topic position-reports \
        --partition 5 \
        --replication 1 \
        --config retention.ms=315576000000 \
        --create

    zcat ais.txt.gz | \
        kafka-avro-console-producer \
            --broker-list localhost:9092 \
            --topic position-reports \
            --property parse.key=true \
            --property key.schema="$(cat classAPositionReportSchemaKey.json)" \
            --property value.schema="$(cat classAPositionReportSchema.json)"

    # # Without key
    # zcat ais-nokey.txt.gz | \
    #     kafka-avro-console-producer \
    #         --broker-list localhost:9092 \
    #         --topic position-reports-nokey \
    #         --property value.schema="$(cat classAPositionReportSchema.json)"

    popd
fi

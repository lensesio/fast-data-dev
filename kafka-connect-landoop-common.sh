#!/usr/bin/env bash

for file in $(find /opt/landoop/connectors -maxdepth 2 -type f -exec basename {} \; | sort | uniq -c | grep -E "^\s+20 " | awk '{print $2}' );
do
    cp /opt/landoop/connectors/kafka-connect-elastic/$file /opt/landoop/kafka/share/java/landoop-common/
    rm -f /opt/landoop/connectors/kafka-connect-*/$file
done

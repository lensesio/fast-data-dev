function process_variable {
    local var="$1"
    local prefix="$2"
    local config_file="$3"

    # Try to detect some envs set by kubernetes and/or docker link and skip them.
    if [[ "$var" =~ [^=]+TCP_(PORT|ADDR).* ]] \
           || [[ "$var" =~ [^=]+_[0-9]{1,5}_(TCP|UDP).* ]] \
           || [[ "$var" =~ [^=]+_SERVICE_PORT.* ]]; then
        echo "Skipping variable probably set by container supervisor: $var"
        continue
    fi

    # If _OPTS, export them
    if [[ "$var" =~ ^(KAFKA|CONNECT|SCHEMA_REGISTRY|KAFKA_REST|ZOOKEEPER)_(OPTS|HEAP_OPTS|JMX_OPTS|LOG4J_OPTS|PERFORMANCE_OPTS)$ ]]; then
        export "${var}"="${!var}"
        continue
    fi

    # Start to process configuration options
    # echo "Processing $var for $prefix"

    # Remove prefix from var name
    conf="${var#$prefix}"
    # Convert var name to lowercase
    if [[ "$prefix" != "ZOOKEEPER_" ]]; then
        conf="${conf,,}"
    fi
    # Convert underscores in var name to stops
    conf="${conf//_/.}"

    echo "${conf}=${!var}" >> "$config_file"
    return 0
}


# Setup Kafka
CONFIG="/var/run/broker/server.properties"
if [[ ! -f "$CONFIG" ]]; then
    printenv \
        | grep -E "^KAFKA_" \
        | grep -vE "^KAFKA_(REST|CONNECT)_" \
        | sed -e 's/=.*//' \
        | while read var
    do
        process_variable "$var" "KAFKA_" "$CONFIG"
    done
else
    echo "Broker config found at '$CONFIG'. We won't process variables."
fi
# Setup Connect
CONFIG="/var/run/connect/connect-avro-distributed.properties"
if [[ ! -f "$CONFIG" ]]; then
    printenv \
        | grep -E "^CONNECT_" \
        | sed -e 's/=.*//' \
        | while read var
    do
        process_variable "$var" "CONNECT_" "$CONFIG"
    done
else
    echo "Connect worker config found at '$CONFIG'. We won't process variables."
fi
# Setup Schema Registry
CONFIG="/var/run/schema-registry/schema-registry.properties"
if [[ ! -f "$CONFIG" ]]; then
    printenv \
        | grep -E "^SCHEMA_REGISTRY_" \
        | sed -e 's/=.*//' \
        | while read var
    do
        process_variable "$var" "SCHEMA_REGISTRY_" "$CONFIG"
    done
else
    echo "Schema registry config found at '$CONFIG'. We won't process variables."
fi
# Setup REST Proxy
CONFIG="/var/run/rest-proxy/kafka-rest.properties"
if [[ ! -f "$CONFIG" ]]; then
    printenv \
        | grep -E "^KAFKA_REST_" \
        | sed -e 's/=.*//' \
        | while read var
    do
        process_variable "$var" "KAFKA_REST_" "$CONFIG"
    done
else
    echo "REST Proxy config found at '$CONFIG'. We won't process variables."
fi

# Setup Zookeeper
CONFIG="/var/run/zookeeper/zookeeper.properties"
if [[ ! -f "$CONFIG" ]]; then
    printenv \
        | grep -E "^ZOOKEEPER_" \
        | sed -e 's/=.*//' \
        | while read var
    do
        process_variable "$var" "ZOOKEEPER_" "$CONFIG"
    done
else
    echo "Zookeeper config found at '$CONFIG'. We won't process variables."
fi

# cat <<EOF > /var/run/zookeeper/zookeeper.properties
# dataDir=/tmp/zookeeper
# clientPort=$ZK_PORT
# maxClientCnxns=0
# EOF

# cat <<EOF > /var/run/broker/broker.properties
# broker.id=0
# num.network.threads=2
# num.io.threads=4
# #socket.send.buffer.bytes=102400
# #socket.receive.buffer.bytes=102400
# #socket.request.max.bytes=104857600
# log.dirs=/tmp/kafka-logs
# num.partitions=1
# num.recovery.threads.per.data.dir=2
# offsets.topic.replication.factor=1
# transaction.state.log.replication.factor=1
# transaction.state.log.min.isr=1
# log.retention.hours=168
# log.segment.bytes=1073741824
# #log.retention.check.interval.ms=300000
# zookeeper.connect=localhost:2181
# zookeeper.connection.timeout.ms=6000
# group.initial.rebalance.delay.ms=1000
# listeners=PLAINTEXT://:9092
# delete.topic.enable=true
# EOF

# cat <<EOF > /var/run/schema-registry/schema-registry.properties
# listeners=http://0.0.0.0:8081
# #kafkastore.connection.url=localhost:2181
# kafkastore.bootstrap.servers=PLAINTEXT://localhost:9092
# #kafkastore.topic=_schemas
# #debug=false
# access.control.allow.methods=GET,POST,PUT,DELETE,OPTIONS
# access.control.allow.origin=*
# EOF

# cat <<EOF > /var/run/connect/connect-avro-distributed.properties
# bootstrap.servers=PLAINTEXT://localhost:9092
# group.id=connect-cluster
# key.converter=io.confluent.connect.avro.AvroConverter
# key.converter.schema.registry.url=http://localhost:8081
# value.converter=io.confluent.connect.avro.AvroConverter
# value.converter.schema.registry.url=http://localhost:8081
# config.storage.topic=connect-configs
# offset.storage.topic=connect-offsets
# status.storage.topic=connect-statuses
# config.storage.replication.factor=1
# offset.storage.replication.factor=1
# status.storage.replication.factor=1
# internal.key.converter=org.apache.kafka.connect.json.JsonConverter
# internal.value.converter=org.apache.kafka.connect.json.JsonConverter
# internal.key.converter.schemas.enable=false
# internal.value.converter.schemas.enable=false
# access.control.allow.methods=GET,POST,PUT,DELETE,OPTIONS
# access.control.allow.origin=*
# plugin.path=/opt/landoop/connectors/stream-reactor,/opt/landoop/connectors/third-party
# plugin.path=/var/run/connect/connectors/stream-reactor,/var/run/connect/connectors/third-party,/connectors
# rest.port=8083
# EOF

# cat <<EOF > /var/run/rest-proxy/kafka-rest.properties
# bootstrap.servers=PLAINTEXT://localhost:9092
# access.control.allow.methods=GET,POST,PUT,DELETE,OPTIONS
# access.control.allow.origin=*
# listeners=http://0.0.0.0:8082
# schema.registry.url=http://localhost:8081
# #zookeeper.connect=localhost:2181
# consumer.request.timeout.ms=20000
# consumer.max.poll.interval.ms=18000
# EOF


function process_variable {
    local var="$1"
    local prefix="$2"
    local config_file="$3"

    # Try to detect some envs set by kubernetes and/or docker link and skip them.
    if [[ $var =~ [^=]+TCP_(PORT|ADDR).* ]] \
           || [[ $var =~ [^=]+_[0-9]{1,5}_(TCP|UDP).* ]] \
           || [[ $var =~ [^=]+_SERVICE_(PORT|HOST).* ]]; then
        echo "Skipping variable probably set by container supervisor: $var"
        return
    fi

    # If _OPTS they are already exported, so continue
    if [[ $var =~ ^(KAFKA|CONNECT|SCHEMA_REGISTRY|KAFKA_REST|ZOOKEEPER)_(OPTS|HEAP_OPTS|JMX_OPTS|LOG4J_OPTS|PERFORMANCE_OPTS)$ ]]; then
        # export "${var}"="${!var}"
        return
    fi

    # A special clause for zookeeper multi-server setups, in order to create myid.
    if [[ $var == ZOOKEEPER_myid ]]; then
        echo "${!var}" >> "$ZOOKEEPER_dataDir/myid"
        return 0
    fi

    # Start to process configuration options

    # Remove prefix from var name
    conf="${var#$prefix}"
    # Convert var name to lowercase except for zookeeper vars.
    if [[ $prefix != ZOOKEEPER_ ]]; then
        conf="${conf,,}"
    fi
    # Convert underscores in var name to stops
    conf="${conf//_/.}"
    # Convert double underscores in var name to dashes
    conf="${conf//../-}"


    echo "${conf}=${!var}" >> "$config_file"
    return 0
}


# Setup Kafka
CONFIG="/var/run/broker/server.properties"
if [[ ! -f "$CONFIG" ]]; then
    printenv \
        | grep -E "^KAFKA_" \
        | grep -vE "^KAFKA_(REST|CONNECT)_" \
        | grep -vE "KAFKA_PORT" \
        | sed -e 's/=.*//' \
        | while read var
    do
        process_variable "$var" "KAFKA_" "$CONFIG"
    done
    # Clean empty variables
    sed -r -e '/^[^=]*=\s*$/d' -i "$CONFIG"
    # Allow empty variables
    sed -r -e 's/(^[^=]*=)#(NULL|EMPTY)#$/\1/' -i "$CONFIG"
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
    # Clean empty variables
    sed -r -e '/^[^=]*=\s*$/d' -i "$CONFIG"
    # Allow empty variables
    sed -r -e 's/(^[^=]*=)#(NULL|EMPTY)#$/\1/' -i "$CONFIG"
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
    # Clean empty variables
    sed -r -e '/^[^=]*=\s*$/d' -i "$CONFIG"
    # Allow empty variables
    sed -r -e 's/(^[^=]*=)#(NULL|EMPTY)#$/\1/' -i "$CONFIG"
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
    # Clean empty variables
    sed -r -e '/^[^=]*=\s*$/d' -i "$CONFIG"
    # Allow empty variables
    sed -r -e 's/(^[^=]*=)#(NULL|EMPTY)#$/\1/' -i "$CONFIG"
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
    # Clean empty variables
    sed -r -e '/^[^=]*=\s*$/d' -i "$CONFIG"
    # Allow empty variables
    sed -r -e 's/(^[^=]*=)#(NULL|EMPTY)#$/\1/' -i "$CONFIG"
else
    echo "Zookeeper config found at '$CONFIG'. We won't process variables."
fi

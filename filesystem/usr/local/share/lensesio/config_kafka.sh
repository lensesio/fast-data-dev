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
    if [[ $var =~ ^(KAFKA|CONNECT|SCHEMA_REGISTRY)_(OPTS|HEAP_OPTS|JMX_OPTS|LOG4J_OPTS|PERFORMANCE_OPTS)$ ]]; then
        # export "${var}"="${!var}"
        return
    fi

    # Start to process configuration options

    # Remove prefix from var name
    conf="${var#$prefix}"
    # Convert var name to lowercase
    conf="${conf,,}"
    # Convert underscores in var name to stops
    conf="${conf//_/.}"
    # Convert triple underscores in var name to dashes
    conf="${conf//.../-}"
    # Convert double underscores in var name to underscores
    conf="${conf//../_}"


    echo "${conf}=${!var}" >> "$config_file"
    return 0
}


# Setup Kafka
CONFIG="/var/run/broker/server.properties"
if [[ ! -f "$CONFIG" ]]; then
    printenv \
        | grep -E "^KAFKA_" \
        | grep -vE "^KAFKA_CONNECT_" \
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

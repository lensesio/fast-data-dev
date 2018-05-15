function process_variable {
    local var="$1"
    local prefix="$2"
    local config_file="$3"

    # Try to detect some envs set by kubernetes and/or docker link and skip them.
    if [[ $var =~ [^=]+TCP_(PORT|ADDR).* ]] \
           || [[ $var =~ [^=]+_[0-9]{1,5}_(TCP|UDP).* ]] \
           || [[ $var =~ [^=]+_SERVICE_PORT.* ]]; then
        echo "Skipping variable probably set by container supervisor: $var"
        return
    fi

    # If _OPTS, export them
    if [[ $var =~ ^(KAFKA|CONNECT|SCHEMA_REGISTRY|KAFKA_REST|ZOOKEEPER)_(OPTS|HEAP_OPTS|JMX_OPTS|LOG4J_OPTS|PERFORMANCE_OPTS)$ ]]; then
        export "${var}"="${!var}"
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


    echo "${conf}=${!var}" >> "$config_file"
    return 0
}

# This function is taken directly from Lenses docker
# https://github.com/Landoop/lenses-docker/blob/master/setup.sh
# We just add the configuration envs from setup.sh inside this.
function process_lenses_variable {
    #### not originally part of the function
    local OPTS_JVM="LENSES_OPTS LENSES_HEAP_OPTS LENSES_JMX_OPTS LENSES_LOG4J_OPTS LENSES_PERFORMANCE_OPTS"
    local OPTS_NEEDQUOTE="LENSES_LICENSE_FILE LENSES_KAFKA_BROKERS"
    local OPTS_NEEDQUOTE="$OPTS_NEEDQUOTE LENSES_GRAFANA LENSES_JMX_BROKERS LENSES_JMX_SCHEMA_REGISTRY LENSES_JMX_ZOOKEEPERS"
    local OPTS_NEEDQUOTE="$OPTS_NEEDQUOTE LENSES_ACCESS_CONTROL_ALLOW_METHODS LENSES_ACCESS_CONTROL_ALLOW_ORIGIN"
    local OPTS_NEEDQUOTE="$OPTS_NEEDQUOTE LENSES_VERSION LENSES_SECURITY_LDAP_URL LENSES_SECURITY_LDAP_BASE"
    local OPTS_NEEDQUOTE="$OPTS_NEEDQUOTE LENSES_SECURITY_LDAP_USER LENSES_SECURITY_LDAP_PASSWORD"
    local OPTS_NEEDQUOTE="$OPTS_NEEDQUOTE LENSES_SECURITY_LDAP_LOGIN_FILTER LENSES_SECURITY_LDAP_MEMBEROF_KEY"
    local OPTS_NEEDQUOTE="$OPTS_NEEDQUOTE LENSES_SECURITY_MEMBEROF_KEY LENSES_SECURITY_LDAP_GROUP_EXTRACT_REGEX"
    local OPTS_NEEDQUOTE="$OPTS_NEEDQUOTE LENSES_TOPICS_ALERTS_STORAGE LENSES_ZOOKEEPER_CHROOT LENSES_ALERT_MANAGER_ENDPOINTS LENSES_ALERT_MANAGER_SOURCE"
    # We started with expicit setting conf options that need quoting (OPTS_NEEDQUOTE) but k8s (and docker linking)
    # can create settings that we process (env vars that start with 'LENSES_') and put into the conf file. Although
    # lenses will ignore these settings, they usually include characters that need quotes, so now we also need to
    # set explicitly which fields do not need quotes. For the settings that do not much either of OPTS_NEEDQUOTE
    # or OPTS_NEEDNOQUOTE we try to autodetect if quotes are needed.
    local OPTS_NEEDNOQUOTE="LENSES_CONNECT LENSES_CONNECT_CLUSTERS LENSES_JMX_CONNECT LENSES_SECURITY_USERS"
    local OPTS_NEEDNOQUOTE="$OPTS_NEEDNOQUOTE LENSES_UI_CONFIG_DISPLAY LENSES_KAFKA_TOPICS LENSES_SQL_CONNECT_CLUSTERS"
    local OPTS_NEEDNOQUOTE="$OPTS_NEEDNOQUOTE LENSES_ZOOKEEPER_HOSTS LENSES_SCHEMA_REGISTRY_URLS LENSES_SECURITY_GROUPS"
    local OPTS_SENSITIVE="LENSES_SECURITY_USERS LENSES_SECURITY_LDAP_USER LENSES_SECURITY_LDAP_PASSWORD LICENSE LICENSE_URL LENSES_SECURITY_GROUPS"

    # Add prefix and suffix spaces, so our regexp check below will work.
    local OPTS_JVM=" $OPTS_JVM "
    local OPTS_NEEDQUOTE=" $OPTS_NEEDQUOTE "
    local OPTS_NEEDNOQUOTE=" $OPTS_NEEDNOQUOTE "
    local OPTS_SENSITIVE=" $OPTS_SENSITIVE "
    #### /not originally part of the function

    local var="$1"
    local config_file="$2"

    # Convert var name to lowercase
    conf="${var,,}"
    # Convert underscores in var name to stops
    conf="${conf//_/.}"

    # If setting needs to be quoted, write with quotes
    if [[ "$OPTS_NEEDQUOTE" =~ " $var " ]]; then
        echo "${conf}=\"${!var}\"" >> "$config_file"
        # if [[ "$OPTS_SENSITIVE" =~ " $var " ]]; then
        #     echo "${conf}=********"
        #     unset "${var}"
        # else
        #     echo "${conf}=\"${!var}\""
        # fi
        return 0
    fi

    # If settings must not have quotes, write without quotes
    if [[ "$OPTS_NEEDNOQUOTE" =~ " $var " ]]; then
        echo "${conf}=${!var}" >> "$config_file"
        # if [[ "$OPTS_SENSITIVE" =~ " $var " ]]; then
        #     echo "${conf}=********"
        #     unset "${var}"
        # else
        #     echo "${conf}=${!var}"
        # fi
        return 0
    fi

    # Else try to detect if we need quotes
    if [[ "${!var}" =~ .*[?:,()*/].* ]]; then
        # echo -n "[Variable needed quotes] "
        echo "${conf}=\"${!var}\"" >> "$config_file"
    else
        echo "${conf}=${!var}" >> "$config_file"
    fi
    if [[ "$OPTS_SENSITIVE" =~ " $var " ]]; then
        # echo "${conf}=********"
        unset "${var}"
    else
        # echo "${conf}=${!var}"
        echo -n
    fi
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
    # Clean empty variables
    sed -e '/^[^=]*=$/d' -i "$CONFIG"
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
    sed -e '/^[^=]*=$/d' -i "$CONFIG"
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
    sed -e '/^[^=]*=$/d' -i "$CONFIG"
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
    sed -e '/^[^=]*=$/d' -i "$CONFIG"
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
    sed -e '/^[^=]*=$/d' -i "$CONFIG"
else
    echo "Zookeeper config found at '$CONFIG'. We won't process variables."
fi

# Setup Lenses
CONFIG="/var/run/lenses/lenses.conf"
if [[ ! -f "$CONFIG" ]]; then
    printenv \
        | grep -E "^LENSES_" \
        | grep -vE "^LENSES_SECURITY_" \
        | sed -e 's/=.*//' \
        | while read var
    do
        process_lenses_variable "$var" "$CONFIG"
    done
    # Clean empty variables
    sed -e '/^[^=]*=$/d' -i "$CONFIG"
else
    echo "Lenses conf config found at '$CONFIG'. We won't process variables."
fi
CONFIG="/var/run/lenses/security.conf"
if [[ ! -f "$CONFIG" ]]; then
    printenv \
        | grep -E "^LENSES_SECURITY_" \
        | sed -e 's/=.*//' \
        | while read var
    do
        process_lenses_variable "$var" "$CONFIG"
    done
    # Clean empty variables
    sed -e '/^[^=]*=$/d' -i "$CONFIG"
else
    echo "Lenses security conf config found at '$CONFIG'. We won't process variables."
fi

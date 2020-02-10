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
    if [[ $var =~ ^(KAFKA|CONNECT|SCHEMA_REGISTRY|KAFKA_REST|ZOOKEEPER|LENSES)_(OPTS|HEAP_OPTS|JMX_OPTS|LOG4J_OPTS|PERFORMANCE_OPTS)$ ]]; then
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


    echo "${conf}=${!var}" >> "$config_file"
    return 0
}

# This function is taken directly from Lenses docker
# https://github.com/Landoop/lenses-docker/blob/master/setup.sh
# We just add the configuration envs from setup.sh inside this.
function process_lenses_variable {
    #### not originally part of the function
    OPTS_JVM="LENSES_OPTS LENSES_HEAP_OPTS LENSES_JMX_OPTS LENSES_LOG4J_OPTS LENSES_PERFORMANCE_OPTS LENSES_SERDE_CLASSPATH_OPTS LENSES_PLUGINS_CLASSPATH_OPTS"
    OPTS_NEEDQUOTE="LENSES_LICENSE_FILE LENSES_KAFKA_BROKERS"
    OPTS_NEEDQUOTE="$OPTS_NEEDQUOTE LENSES_GRAFANA LENSES_JMX_SCHEMA_REGISTRY LENSES_JMX_ZOOKEEPERS"
    OPTS_NEEDQUOTE="$OPTS_NEEDQUOTE LENSES_ACCESS_CONTROL_ALLOW_METHODS LENSES_ACCESS_CONTROL_ALLOW_ORIGIN"
    OPTS_NEEDQUOTE="$OPTS_NEEDQUOTE LENSES_VERSION LENSES_SECURITY_LDAP_URL LENSES_SECURITY_LDAP_BASE"
    OPTS_NEEDQUOTE="$OPTS_NEEDQUOTE LENSES_SECURITY_LDAP_USER LENSES_SECURITY_LDAP_PASSWORD"
    OPTS_NEEDQUOTE="$OPTS_NEEDQUOTE LENSES_SECURITY_LDAP_LOGIN_FILTER LENSES_SECURITY_LDAP_MEMBEROF_KEY"
    OPTS_NEEDQUOTE="$OPTS_NEEDQUOTE LENSES_SECURITY_MEMBEROF_KEY LENSES_SECURITY_LDAP_GROUP_EXTRACT_REGEX"
    OPTS_NEEDQUOTE="$OPTS_NEEDQUOTE LENSES_TOPICS_ALERTS_STORAGE LENSES_ZOOKEEPER_CHROOT"
    OPTS_NEEDQUOTE="$OPTS_NEEDQUOTE LENSES_KUBERNETES_PROCESSOR_JAAS LENSES_ALERTING_PLUGIN_CONFIG_ICON_URL"
    OPTS_NEEDQUOTE="$OPTS_NEEDQUOTE LENSES_ALERT_MANAGER_SOURCE LENSES_ALERT_MANAGER_ENDPOINTS" # Deprecated settings. We keep them to avoid breaking Lenses for people who forget to remove them.

    # We started with expicit setting conf options that need quoting (OPTS_NEEDQUOTE) but k8s (and docker linking)
    # can create settings that we process (env vars that start with 'LENSES_') and put into the conf file. Although
    # lenses will ignore these settings, they usually include characters that need quotes, so now we also need to
    # set explicitly which fields do not need quotes. For the settings that do not much either of OPTS_NEEDQUOTE
    # or OPTS_NEEDNOQUOTE we try to autodetect if quotes are needed.
    OPTS_NEEDNOQUOTE="LENSES_CONNECT LENSES_CONNECT_CLUSTERS LENSES_JMX_CONNECT"
    OPTS_NEEDNOQUOTE="$OPTS_NEEDNOQUOTE LENSES_UI_CONFIG_DISPLAY LENSES_KAFKA_TOPICS LENSES_SQL_CONNECT_CLUSTERS"
    OPTS_NEEDNOQUOTE="$OPTS_NEEDNOQUOTE LENSES_ZOOKEEPER_HOSTS LENSES_SCHEMA_REGISTRY_URLS"
    OPTS_NEEDNOQUOTE="$OPTS_NEEDNOQUOTE LENSES_JMX_BROKERS"
    OPTS_NEEDNOQUOTE="$OPTS_NEEDNOQUOTE LENSES_KAFKA_CONTROL_TOPICS LENSES_KAFKA LENSES_KAFKA_METRICS LENSES_KAFKA LENSES_KAFKA_METRICS"
    OPTS_NEEDNOQUOTE="$OPTS_NEEDNOQUOTE LENSES_KAFKA_METRICS_PORT LENSES_KAFKA_CONNECT_CLUSTERS LENSES_CONNECTORS_INFO"
    OPTS_NEEDNOQUOTE="$OPTS_NEEDNOQUOTE LENSES_ALERT_PLUGINS"
    OPTS_NEEDNOQUOTE="$OPTS_NEEDNOQUOTE LENSES_SECURITY_USERS LENSES_SECURITY_GROUPS LENSES_SECURITY_SERVICE_ACCOUNTS LENSES_SECURITY_MAPPINGS" # These are deprecated but keep them so we protect users from suboptimal upgrades.

    OPTS_SENSITIVE="LENSES_SECURITY_USER LENSES_SECURITY_PASSWORD LENSES_SECURITY_LDAP_USER LENSES_SECURITY_LDAP_PASSWORD LICENSE LICENSE_URL"
    OPTS_SENSITIVE="$OPTS_SENSITIVE LENSES_SECURITY_USERS LENSES_SECURITY_GROUPS LENSES_SECURITY_SERVICE_ACCOUNTS" # These are deprecated but keep them so we protect users from suboptimal upgrades.
    OPTS_SENSITIVE="$OPTS_SENSITIVE LENSES_KAFKA_SETTINGS_CONSUMER_SSL_KEYSTORE_PASSWORD LENSES_KAFKA_SETTINGS_CONSUMER_SSL_KEY_PASSWORD LENSES_KAFKA_SETTINGS_CONSUMER_SSL_TRUSTSTORE_PASSWORD"
    OPTS_SENSITIVE="$OPTS_SENSITIVE LENSES_KAFKA_SETTINGS_PRODUCER_SSL_KEYSTORE_PASSWORD LENSES_KAFKA_SETTINGS_PRODUCER_SSL_KEY_PASSWORD LENSES_KAFKA_SETTINGS_PRODUCER_SSL_TRUSTSTORE_PASSWORD"
    OPTS_SENSITIVE="$OPTS_SENSITIVE LENSES_KAFKA_SETTINGS_KSTREAM_SSL_KEYSTORE_PASSWORD LENSES_KAFKA_SETTINGS_KSTREAM_SSL_KEY_PASSWORD LENSES_KAFKA_SETTINGS_KSTREAM_SSL_TRUSTSTORE_PASSWORD"
    OPTS_SENSITIVE="$OPTS_SENSITIVE LENSES_SCHEMA_REGISTRY_PASSWORD LENSES_KAFKA_SETTINGS_PRODUCER_BASIC_AUTH_USER_INFO"
    OPTS_SENSITIVE="$OPTS_SENSITIVE LENSES_KAFKA_SETTINGS_CONSUMER_BASIC_AUTH_USER_INFO LENSES_KUBERNETES_PROCESSOR_KAFKA_SETTINGS_BASIC_AUTH_USER_INFO"
    OPTS_SENSITIVE="$OPTS_SENSITIVE LENSES_KUBERNETES_PROCESSOR_SCHEMA_REGISTRY_SETTINGS_BASIC_AUTH_USER_INFO LENSES_KAFKA_METRICS_USER LENSES_KAFKA_METRICS_PASSWORD"
    OPTS_SENSITIVE="$OPTS_SENSITIVE LENSES_ALERTING_PLUGIN_CONFIG_WEBHOOK_URL LENSES_ALERTING_PLUGIN_CONFIG_USERNAME "

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

    # If _OPTS, they are already exported, so continue
    if [[ "OPTS_JVM" =~ " $var " ]]; then
        # export "${var}"="${!var}"
        return 0
    fi

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
    if [[ "${!var}" =~ .*[?:,()*/#|!].* ]]; then
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
    sed -r -e '/^[^=]*=\s*$/d' -i "$CONFIG"
    # Allow empty variables
    sed -r -e 's/(^[^=]*=)#(NULL|EMPTY)#$/\1/' -i "$CONFIG"
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
    sed -r -e '/^[^=]*=\s*$/d' -i "$CONFIG"

    # If we didn't found any variables, create an empty security.conf
    # so Lenses can start (it is configured to load the security file)
    if [[ ! -f $CONFIG ]]; then
        touch "$CONFIG"
    fi
else
    echo "Lenses security conf config found at '$CONFIG'. We won't process variables."
fi

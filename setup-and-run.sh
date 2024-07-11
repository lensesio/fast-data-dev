#!/usr/bin/env bash

TRUE_REG='^([tT][rR][uU][eE]|[yY]|[yY][eE][sS]|1)$'
FALSE_REG='^([fF][aA][lL][sS][eE]|[nN]|[nN][oO]|0)$'

DEBUG_SCRIPT=${DEBUG_SCRIPT:-false}
if [[ $DEBUG_SCRIPT =~ $TRUE_REG ]]; then
    set -o xtrace
    printenv
fi

STRICT_SCRIPT=${STRICT_SCRIPT:-true}
if [[ $STRICT_SCRIPT =~ $TRUE_REG ]]; then
    set -o errexit
    set -o nounset
    set -o pipefail
fi

source /build.info
export LT_PACKAGE=${LT_PACKAGE:-box}
export LT_PACKAGE_VERSION=${LT_PACKAGE_VERSION:-$BUILD_COMMIT}

# Run pre-setup user provided scripts.
export PRE_SETUP=${PRE_SETUP:-}
export PRE_SETUP_FILE=${PRE_SETUP_FILE:-}
export PRE_SETUP_URL=${PRE_SETUP_URL:-}
if [[ -n "$PRE_SETUP" ]]; then
    $PRE_SETUP
fi
if [[ -n "$PRE_SETUP_FILE" ]]; then
    if [[ ! -f "$PRE_SETUP_FILE" ]]; then
        echo "Although PRE_SETUP_FILE is set, I cannot find the file."
    fi
    source $PRE_SETUP_FILE
fi
if [[ -n "$PRE_SETUP_URL" ]]; then
    curl "$PRE_SETUP_URL" --silent --show-error --fail --output /tmp/PRE_SETUP_URL
    source /tmp/PRE_SETUP_URL
    rm /tmp/PRE_SETUP_URL
fi

# Default values
export ZK_PORT=${ZK_PORT:-2181}
export ZK_JMX_PORT=${ZK_JMX_PORT:-9585}
export BROKER_PORT=${BROKER_PORT:-9092}
export BROKER_JMX_PORT=${BROKER_JMX_PORT:-9581}
export BROKER_SSL_PORT=${BROKER_SSL_PORT:-9093}
export REGISTRY_PORT=${REGISTRY_PORT:-8081}
export REGISTRY_JMX_PORT=${REGISTRY_JMX_PORT:-9582}
export CONNECT_PORT=${CONNECT_PORT:-8083}
export CONNECT_JMX_PORT=${CONNECT_JMX_PORT:-9584}
export REST_PORT=${REST_PORT:-0}
export REST_JMX_PORT=${REST_JMX_PORT:-9583}
export WEB_PORT=${WEB_PORT:-3030}
export LENSES_PORT=${LENSES_PORT:-9991}
export LENSES_JMX_PORT=${LENSES_JMX_PORT:-9586}
PROVISION_LENSES=${PROVISION_LENSES:-true}
export ELASTICSEARCH_PORT=${ELASTICSEARCH_PORT:-0} # Disable until CVE-2021-44228 is addressed
export ELASTICSEARCH_TRASNPORT_PORT=${ELASTICSEARCH_TRANSPORT_PORT:-9300}
export FDD_PORT=${FDD_PORT:-28371}
RUN_AS_ROOT=${RUN_AS_ROOT:-false}
DISABLE_JMX=${DISABLE_JMX:-false}
ENABLE_SSL=${ENABLE_SSL:-false}
SSL_EXTRA_HOSTS=${SSL_EXTRA_HOSTS:-}
DEBUG=${DEBUG:-false}
export SAMPLEDATA=${SAMPLEDATA:-1}
export RUNNING_SAMPLEDATA=${RUNNING_SAMPLEDATA:-1}
DISABLE=${DISABLE:-}
CONNECTORS=${CONNECTORS:-}
export ADV_HOST=${ADV_HOST:-}
export ADV_HOST_JMX=${ADV_HOST_JMX:-${ADV_HOST}}
export ADV_HOST_JMX=${ADV_HOST_JMX:-127.0.0.1}
CONNECT_HEAP=${CONNECT_HEAP:-}
WEB_ONLY=${WEB_ONLY:-0}
export FORWARDLOGS=${FORWARDLOGS:-1}
export RUNTESTS=${RUNTESTS:-0}
export BROWSECONFIGS=${BROWSECONFIGS:-1}
export SUPERVISORWEB=${SUPERVISORWEB:-0}
export SUPERVISORWEB_PORT=${SUPERVISORWEB_PORT:-9001}
export TELEMETRY=${TELEMETRY:-}
export USER=${USER:-admin}
export WEB_TERMINAL_PORT=${WEB_TERMINAL_PORT:-0}
export DEBUG_AUTH=${DEBUG_AUTH:-0}
# These are the scripts that we will use before we start each app, so the
# WAIT_SCRIPT_BROKER is what we run before we start the broker.
export WAIT_SCRIPT_BROKER=${WAIT_SCRIPT_BROKER:-/usr/local/share/lensesio/wait-scripts/wait-for-zookeeper.sh}
export WAIT_SCRIPT_REGISTRY=${WAIT_SCRIPT_REGISTRY:-/usr/local/share/lensesio/wait-scripts/wait-for-kafka.sh}
export WAIT_SCRIPT_CONNECT=${WAIT_SCRIPT_CONNECT:-/usr/local/share/lensesio/wait-scripts/wait-for-registry.sh}
export WAIT_SCRIPT_RESTPROXY=${WAIT_SCRIPT_RESTPROXY:-/usr/local/share/lensesio/wait-scripts/wait-for-registry.sh}
export WAIT_SCRIPT_LENSES=${WAIT_SCRIPT_LENSES:-/usr/local/share/lensesio/wait-scripts/wait-for-registry.sh}

# These ports are always used.
PORTS="$ZK_PORT $BROKER_PORT $REGISTRY_PORT $REST_PORT $CONNECT_PORT $WEB_PORT $LENSES_PORT $ELASTICSEARCH_PORT $ELASTICSEARCH_TRASNPORT_PORT"

# Export versions so envsubst will work
source build.info
# shellcheck disable=SC2046
export $(cut -d= -f1 /build.info)

# Set env vars to configure Kafka
export KAFKA_BROKER_ID=${KAFKA_BROKER_ID:-101}
export KAFKA_NUM_NETWORK_THREADS=${KAFKA_NUM_NETWORK_THREADS:-2}
export KAFKA_NUM_IO_THREADS=${KAFKA_NUM_IO_THREADS:-4}
export KAFKA_LOG_DIRS=${KAFKA_LOG_DIRS:-/data/kafka/logdir}
#export KAFKA_NUM_PARTITIONS=${KAFKA_NUM_PARTITIONS:-1}
export KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=${KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR:-1}
export KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=${KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR:-1}
export KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=${KAFKA_TRANSACTION_STATE_LOG_MIN_ISR:-1}
export KAFKA_LOG_RETENTION_HOURS=${KAFKA_LOG_RETENTION_HOURS:-168}
export KAFKA_LOG_SEGMENT_BYTES=${KAFKA_LOG_SEGMENT_BYTES:-104857600}
export KAFKA_ZOOKEEPER_CONNECT=${KAFKA_ZOOKEEPER_CONNECT:-127.0.0.1:$ZK_PORT}
export KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS=${KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS:-1000}
export KAFKA_LISTENERS=${KAFKA_LISTENERS:-PLAINTEXT://:$BROKER_PORT}
export KAFKA_DELETE_TOPIC_ENABLE=${KAFKA_DELETE_TOPIC_ENABLE:-true}
export KAFKA_ADVERTISED_LISTENERS=${KAFKA_ADVERTISED_LISTENERS:-}
export BROKER_JMX_OPTS=${BROKER_JMX_OPTS:--Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.local.only=false -Djava.rmi.server.hostname=$ADV_HOST_JMX -Dcom.sun.management.jmxremote.rmi.port=$BROKER_JMX_PORT}
export BROKER_LOG4J_OPTS=${BROKER_LOG4J_OPTS:--Dlog4j.configuration=file:/var/run/broker/log4j.properties}

# Set env vars to configure Schema Registry
export SCHEMA_REGISTRY_LISTENERS=${SCHEMA_REGISTRY_LISTENERS:-http://0.0.0.0:$REGISTRY_PORT}
export SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS=${SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS:-PLAINTEXT://:$BROKER_PORT}
export SCHEMA_REGISTRY_ACCESS_CONTROL_ALLOW_METHODS=${SCHEMA_REGISTRY_ACCESS_CONTROL_ALLOW_METHODS:-GET,POST,PUT,DELETE,OPTIONS}
export SCHEMA_REGISTRY_ACCESS_CONTROL_ALLOW_ORIGIN=${SCHEMA_REGISTRY_ACCESS_CONTROL_ALLOW_ORIGIN:-*}
export SCHEMA_REGISTRY_JMX_OPTS=${SCHEMA_REGISTRY_JMX_OPTS:--Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.local.only=false -Djava.rmi.server.hostname=$ADV_HOST_JMX -Dcom.sun.management.jmxremote.rmi.port=$REGISTRY_JMX_PORT}
export SCHEMA_REGISTRY_LOG4J_OPTS=${SCHEMA_REGISTRY_JMX_OPTS:--Dlog4j.configuration=file:/var/run/schema-registry/log4j.properties}

# Set env vars for Kafka Connect Distributed
export CONNECT_BOOTSTRAP_SERVERS=${CONNECT_BOOTSTRAP_SERVERS:-PLAINTEXT://127.0.0.1:$BROKER_PORT}
export CONNECT_GROUP_ID=${CONNECT_GROUP_ID:-connect-fast-data}
export CONNECT_KEY_CONVERTER=${CONNECT_KEY_CONVERTER:-io.confluent.connect.avro.AvroConverter}
export CONNECT_KEY_CONVERTER_SCHEMA_REGISTRY_URL=${CONNECT_KEY_CONVERTER_SCHEMA_REGISTRY_URL:-http://127.0.0.1:$REGISTRY_PORT}
export CONNECT_VALUE_CONVERTER=${CONNECT_VALUE_CONVERTER:-io.confluent.connect.avro.AvroConverter}
export CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL=${CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL:-http://127.0.0.1:$REGISTRY_PORT}
export CONNECT_CONFIG_STORAGE_TOPIC=${CONNECT_CONFIG_STORAGE_TOPIC:-connect-configs}
export CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR=${CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR:-1}
export CONNECT_CONFIG_STORAGE_PARTITIONS=1
export CONNECT_OFFSET_STORAGE_TOPIC=${CONNECT_OFFSET_STORAGE_TOPIC:-connect-offsets}
export CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR=${CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR:-1}
export CONNECT_OFFSET_STORAGE_PARTITIONS=${CONNECT_OFFSET_STORAGE_PARTITIONS:-5}
export CONNECT_STATUS_STORAGE_TOPIC=${CONNECT_STATUS_STORAGE_TOPIC:-connect-statuses}
export CONNECT_STATUS_STORAGE_REPLICATION_FACTOR=${CONNECT_STATUS_STORAGE_REPLICATION_FACTOR:-1}
export CONNECT_STATUS_STORAGE_PARTITIONS=${CONNECT_STATUS_STORAGE_PARTITIONS:-3}
export CONNECT_ACCESS_CONTROL_ALLOW_METHODS=${CONNECT_ACCESS_CONTROL_ALLOW_METHODS:-GET,POST,PUT,DELETE,OPTIONS}
export CONNECT_ACCESS_CONTROL_ALLOW_ORIGIN=${CONNECT_ACCESS_CONTROL_ALLOW_ORIGIN:-*}
export CONNECT_PLUGIN_PATH=${CONNECT_PLUGIN_PATH:-/var/run/connect/connectors/stream-reactor,/var/run/connect/connectors/third-party,/connectors}
export CONNECT_REST_PORT=${CONNECT_REST_PORT:-$CONNECT_PORT}
export CONNECT_REST_ADVERTISED_HOST_NAME=${CONNECT_REST_ADVERTISED_HOST_NAME:-}
export CONNECT_CONFIG_PROVIDERS=${CONNECT_CONFIG_PROVIDERS:-aes256}
export CONNECT_CONFIG_PROVIDERS_AES256_CLASS=${CONNECT_CONFIG_PROVIDERS_AES256_CLASS:-io.lenses.connect.secrets.providers.Aes256DecodingProvider}
export CONNECT_CONFIG_PROVIDERS_AES256_PARAM_AES256_KEY=${CONNECT_CONFIG_PROVIDERS_AES256_PARAM_AES256_KEY:-0123456789abcdef0123456789abcdef}
export CONNECT_CONFIG_PROVIDERS_AES256_PARAM_FILE_DIR=${CONNECT_CONFIG_PROVIDERS_AES256_PARAM_FILE_DIR:-/tmp/connect-secrets}
export CONNECT_JMX_OPTS=${CONNECT_JMX_OPTS:--Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.local.only=false -Djava.rmi.server.hostname=$ADV_HOST_JMX -Dcom.sun.management.jmxremote.rmi.port=$CONNECT_JMX_PORT}
export CONNECT_LOG4J_OPTS=${CONNECT_LOG4J_OPTS:--Dlog4j.configuration=file:/var/run/connect/connect-log4j.properties}

# Set env vars for REST Proxy
export KAFKA_REST_BOOTSTRAP_SERVERS=${KAFKA_REST_BOOTSTRAP_SERVERS:-PLAINTEXT://127.0.0.1:$BROKER_PORT}
export KAFKA_REST_ACCESS_CONTROL_ALLOW_METHODS=${KAFKA_REST_ACCESS_CONTROL_ALLOW_METHODS:-GET,POST,PUT,DELETE,OPTIONS}
export KAFKA_REST_ACCESS_CONTROL_ALLOW_ORIGIN=${KAFKA_REST_ACCESS_CONTROL_ALLOW_ORIGIN:-*}
export KAFKA_REST_LISTENERS=${KAFKA_REST_LISTENERS:-http://0.0.0.0:$REST_PORT}
export KAFKA_REST_SCHEMA_REGISTRY_URL=${KAFKA_REST_SCHEMA_REGISTRY_URL:-http://127.0.0.1:$REGISTRY_PORT}
# Next two lines are a fix for REST Proxy
export KAFKA_REST_CONSUMER_REQUEST_TIMEOUT_MS=${KAFKA_REST_CONSUMER_REQUEST_TIMEOUT_MS:-20000}
export KAFKA_REST_CONSUMER_MAX_POLL_INTERVAL_MS=${KAFKA_REST_CONSUMER_MAX_POLL_INTERVAL_MS:-18000}
export KAFKA_REST_ZOOKEEPER_CONNECT=${KAFKA_REST_ZOOKEEPER_CONNECT:-127.0.0.1:$ZK_PORT}
export KAFKAREST_JMX_OPTS=${KAFKA_REST_JMX_OPTS:-}
export KAFKAREST_JMX_OPTS=${KAFKAREST_JMX_OPTS:--Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.local.only=false -Djava.rmi.server.hostname=$ADV_HOST_JMX -Dcom.sun.management.jmxremote.rmi.port=$REST_JMX_PORT}
export KAFKAREST_LOG4J_OPTS=${KAFKA_REST_LOG4J_OPTS:-}
export KAFKAREST_LOG4J_OPTS=${KAFKAREST_LOG4J_OPTS:--Dlog4j.configuration=file:/var/run/rest-proxy/log4j.properties}

# Set env vars for ZOOKEEPER
export ZOOKEEPER_dataDir=${ZOOKEEPER_dataDir:-/data/zookeeper}
export ZOOKEEPER_clientPort=${ZOOKEEPER_clientPort:-$ZK_PORT}
export ZOOKEEPER_maxClientCnxns=${ZOOKEEPER_maxClientCnxnxs:-0}
ZOOKEEPER_OPTS=${ZOOKEEPER_OPTS:-}
export ZOOKEEPER_OPTS="${ZOOKEEPER_OPTS} -Dzookeeper.4lw.commands.whitelist=ruok,dump"
export ZOOKEEPER_LOG4J_OPTS=${ZOOKEEPER_LOG4J_OPTS:--Dlog4j.configuration=file:/var/run/zookeeper/log4j.properties}
export ZOOKEEPER_JMX_OPTS=${ZOOKEEPER_JMX_OPTS:--Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.local.only=false -Djava.rmi.server.hostname=$ADV_HOST_JMX -Dcom.sun.management.jmxremote.rmi.port=$ZK_JMX_PORT}

# Set env var for Lenses
#export LENSES_PORT=${LENSES_PORT:-9991}
## These settings are deprecated with Lenses 5.0 and will prevent the software
## from booting, but now we use them for provisioning.yaml
export LENSES_ZOOKEEPER_HOSTS=[${LENSES_ZOOKEEPER_HOSTS:-0.0.0.0:$ZK_PORT}]
export LENSES_KAFKA_BROKERS=[${LENSES_KAFKA_BROKERS:-PLAINTEXT://0.0.0.0:$BROKER_PORT}]
export LENSES_SCHEMA_REGISTRY_URLS=[${LENSES_SCHEMA_REGISTRY_URLS:-http://0.0.0.0:$REGISTRY_PORT}]
export LENSES_KAFKA_CONNECT_CLUSTERS=[${LENSES_KAFKA_CONNECT_CLUSTERS:-http://0.0.0.0:$CONNECT_PORT}]
export LENSES_LICENSE_FILE=${LENSES_LICENSE_FILE:-/var/run/lenses/provision/license.json}
##
export LENSES_SECRET_FILE=${LENSES_SECRET_FILE:-/var/run/lenses/security.conf}
LEN_USER=${USER:-admin}
export LENSES_SECURITY_USER=${LENSES_SECURITY_USER:-$LEN_USER}
LEN_PASSWORD=${PASSWORD:-admin}
export LENSES_SECURITY_PASSWORD=${LENSES_SECURITY_PASSWORD:-$LEN_PASSWORD}
export LENSES_TELEMETRY_ENABLE=${LENSES_TELEMETRY_ENABLE:-$TELEMETRY}
export LENSES_BOX=${LENSES_BOX:-true}
export LENSES_SQL_STATE_DIR=${LENSES_SQL_STATE_DIR:-/data/lsql-state-dir}
export LENSES_STORAGE_DIRECTORY=${LENSES_STORAGE_DIRECTORY:-/data/lenses}
export LENSES_PLUGINS_CLASSPATH_OPTS=${LENSES_PLUGINS_CLASSPATH_OPTS:-/plugins}
LENSES_ROOT_PATH=${LENSES_ROOT_PATH:-}
export LENSES_ROOT_PATH=${LENSES_ROOT_PATH%/}
if [[ $PROVISION_LENSES =~ $TRUE_REG ]]; then
    export LENSES_PROVISIONING_PATH=${LENSES_PROVISIONING_PATH:-/var/run/lenses/provision}
fi

# Set env vars for generator (also used in provision unit)
export GENERATOR_BROKER=${GENERATOR_BROKER:-127.0.0.1:$BROKER_PORT}
export GENERATOR_ZK_HOST=${GENERATOR_ZK_HOST:-127.0.0.1}
export GENERATOR_SCHEMA_REGISTRY_URL=${GENERATOR_SCHEMA_REGISTRY_URL:-http://127.0.0.1:$REGISTRY_PORT}
export GENERATOR_LENSES=${GENERATOR_LENSES:-127.0.0.1:$LENSES_PORT$LENSES_ROOT_PATH}
if [[ "$GENERATOR_BROKER" != *"127.0.0.1"* ]]; then
    sed -e "/^brokers/ s#0\.0\.0\.0:9092#${GENERATOR_BROKER}#" \
        -e "/^schema\.registry/ s#http://0\.0\.0\.0:8081#${GENERATOR_SCHEMA_REGISTRY_URL}#" \
        -i /opt/generator/lenses.conf
fi

# Set env vars for ElasticSearch
export ES_CLUSTER_NAME=${ES_CLUSTER_NAME:-lenses-box}
export ES_NODE_NAME=${ES_NODE_NAME:-box-1}
export ES_PATH_DATA=${ES_PATH_DATA:-/data/elasticsearch}
export ES_PATH_LOGS=${ES_PATH_LOGS:-/var/run/elasticsearch}
export ES_BOOTSTRAP_MEMORY__LOCK=${ES_BOOTSTRAP_MEMORY__LOCK:-false}
export ES_HTTP_HOST=${ES_HTTP_HOST:-0.0.0.0}
export ES_HTTP_PORT=${ES_HTTP_PORT:-$ELASTICSEARCH_PORT}
export ES_ACTION_DESTRUCTIVE__REQUIRES__NAME=${ES_ACTION_DESTRUCTIVE__REQUIRES__NAME:-true}

# Set memory limits
# Set connect heap size if needed
if [[ -n $CONNECT_HEAP ]]; then CONNECT_HEAP="-Xmx$CONNECT_HEAP"; fi
CONNECT_HEAP_OPTS=${CONNECT_HEAP_OPTS:-$CONNECT_HEAP}
export CONNECT_HEAP_OPTS=${CONNECT_HEAP_OPTS:--Xmx640M -Xms128M}
export BROKER_HEAP_OPTS=${BROKER_HEAP_OPTS:--Xmx256M -Xms256M}
export ZOOKEEPER_HEAP_OPTS=${ZOOKEEPER_HEAP_OPTS:--Xmx192M -Xms64M}
export SCHEMA_REGISTRY_HEAP_OPTS=${SCHEMA_REGISTRY_HEAP_OPTS:--Xmx192M -Xms128M}
export KAFKA_REST_HEAP_OPTS=${KAFKA_REST_HEAP_OPTS:--Xmx192M -Xms128M}
export LENSES_HEAP_OPTS=${LENSES_HEAP_OPTS:--Xmx1024M -Xms320M}
export ES_HEAP_OPTS=${ES_HEAP_OPTS:--Xmx192M -Xms128M}
ES_JAVA_OPTS=${ES_JAVA_OPTS:-}
export ES_JAVA_OPTS="${ES_JAVA_OPTS} ${ES_HEAP_OPTS}"

# Configure JMX if needed or disable it.
if [[ ! $DISABLE_JMX =~ $TRUE_REG ]]; then
    # If JMX is not disabled, we should check for port availability
    PORTS="$PORTS $BROKER_JMX_PORT $REGISTRY_JMX_PORT $REST_JMX_PORT $CONNECT_JMX_PORT $ZK_JMX_PORT $LENSES_JMX_PORT"
else
    # This does not really disable JMX, but each service will start JMX
    # in an ephemeral port, so it won't cause issues to the process.
    export ZK_JMX_PORT=0
    export BROKER_JMX_PORT=0
    export REGISTRY_JMX_PORT=0
    export CONNECT_JMX_PORT=0
    export REST_JMX_PORT=0
    export LENSES_JMX_PORT=0
fi

if [[ $LENSES_JMX_PORT == 0 ]]; then
    # Lenses do not support setting lenses.jmx.port=0
    unset LENSES_JMX_PORT
fi

# Create run directories for various services and initialize where applicable with configuration files.
mkdir -p \
      /var/run/zookeeper \
      /var/run/broker \
      /var/run/schema-registry \
      /var/run/connect \
      /var/run/connect/connectors/{stream-reactor,third-party} \
      /var/run/rest-proxy \
      /var/run/coyote \
      /var/run/caddy \
      /data/{zookeeper,kafka,lsql-state-dir,lenses,elasticsearch} \
      /var/run/lenses \
      /var/run/lenses/provision \
      /var/run/elasticsearch/logs
chmod 777 /data/{zookeeper,kafka,lsql-state-dir,lenses,elasticsearch} /var/run/elasticsearch /var/run/elasticsearch/logs

# Copy log4j files
cp /opt/lensesio/kafka/etc/kafka/log4j.properties \
   /var/run/zookeeper/
cp /opt/lensesio/kafka/etc/kafka/log4j.properties \
   /var/run/broker/
cp /opt/lensesio/kafka/etc/schema-registry/log4j.properties \
   /var/run/schema-registry/
cp /opt/lensesio/kafka/etc/kafka/connect-log4j.properties \
   /var/run/connect/
cp /opt/lensesio/kafka/etc/kafka-rest/log4j.properties \
   /var/run/rest-proxy/
cp /opt/lenses/logback.xml \
   /var/run/lenses/
# Disable until CVE-2021-44228 is addressed
# cp /opt/elasticsearch/config/{log4j2.properties,jvm.options} /var/run/elasticsearch
# sed -e 's|file=logs/gc.log|file=/var/run/elasticsearch/logs/gc.log|' \
#     -i /var/run/elasticsearch/jvm.options

# Copy tests
# This differs in that we need to adjust it later
cp /opt/lensesio/tools/share/coyote/examples/simple-integration-tests.yml \
   /var/run/coyote/simple-integration-tests.yml
## Fix ports for integration-tests
sed -e "s/3030/$WEB_PORT/" \
    -e "s/2181/$ZK_PORT/" \
    -e "s/9092/$BROKER_PORT/" \
    -e "s/8081/$REGISTRY_PORT/" \
    -e "s/8082/$REST_PORT/" \
    -e "s/8083/$CONNECT_PORT/" \
    -i /var/run/coyote/simple-integration-tests.yml

# Copy other templated files (caddy, logs-to-kafka, env.js)
envsubst < /usr/local/share/lensesio/etc/Caddyfile                   > /var/run/caddy/Caddyfile
envsubst < /usr/local/share/lensesio/etc/fast-data-dev-ui/env.js     > /var/www/env.js

# Set ADV_HOST if needed
if [[ -n ${ADV_HOST} ]]; then
    echo -e "\e[92mSetting advertised host to \e[96m${ADV_HOST}\e[34m\e[92m.\e[34m"
    if [[ -z ${KAFKA_ADVERTISED_LISTENERS} ]]; then
        export KAFKA_ADVERTISED_LISTENERS="PLAINTEXT://${ADV_HOST}:${BROKER_PORT}"
        # If SSL is enabled we need to know if we should update the advertised.listeners
        TMP_ADV_LISTENERS_SET=true
    else
        TMP_ADV_LISTENERS_SET=false
    fi
    if [[ -z $CONNECT_REST_ADVERTISED_HOST_NAME ]]; then
        export CONNECT_REST_ADVERTISED_HOST_NAME=${ADV_HOST}
    fi
    sed -e "s#127.0.0.1#${ADV_HOST}#g" -i /var/run/coyote/simple-integration-tests.yml /var/www/env.js
fi

# setup Kafka (and components) and Lenses
source /usr/local/share/lensesio/config_kafka.sh

# setup supervisord
for service in /usr/local/share/lensesio/etc/supervisord.templates.d/*.conf; do
    # shellcheck disable=SC2094
    envsubst < "$service" > /etc/supervisord.d/"$(basename "$service")"
done
# Disable services if asked
if [[ $ZK_PORT == 0 ]] || [[ $GENERATOR_ZK_HOST != "127.0.0.1" ]];       then rm /etc/supervisord.d/*zookeeper.conf; fi
if [[ $BROKER_PORT == 0 ]];   then rm /etc/supervisord.d/*broker.conf; fi
if [[ $REGISTRY_PORT == 0 ]]; then rm /etc/supervisord.d/*schema-registry.conf; fi
if [[ $CONNECT_PORT == 0 ]];  then rm /etc/supervisord.d/*connect-distributed.conf; fi
if [[ $REST_PORT == 0 ]];     then rm /etc/supervisord.d/*rest-proxy.conf; fi
if [[ $WEB_PORT == 0 ]];      then rm /etc/supervisord.d/*caddy.conf; fi
if [[ $LENSES_PORT == 0 ]];   then rm /etc/supervisord.d/*lenses.conf; fi
if [[ $ELASTICSEARCH_PORT == 0 ]]; then rm /etc/supervisord.d/*elasticsearch.conf; fi
if [[ $WEB_TERMINAL_PORT == 0 ]];      then rm /etc/supervisord.d/*gotty-web-terminal.conf; fi
if [[ $FORWARDLOGS =~ $FALSE_REG ]]; then rm /etc/supervisord.d/*logs-to-kafka.conf; fi
if [[ $RUNTESTS =~ $FALSE_REG ]]; then
    rm /etc/supervisord.d/*smoke-tests.conf
    cat <<EOF > /var/www/coyote-tests/results
{
  "passed": -1,
  "failed": 0
}
EOF
fi

# Set webserver basicauth username and password
USER="${USER:-admin}"
PASSWORD="${PASSWORD:-}"
export USER
if [[ ! -z $PASSWORD ]]; then
    echo -e "\e[92mEnabling login credentials '\e[96m${USER}\e[34m\e[92m' '\e[96mxxxxxxxx'\e[34m\e[92m.\e[34m"
    echo "basicauth / \"${USER}\" \"${PASSWORD}\"" >> /var/run/caddy/Caddyfile
fi
# If BROWSECONFIGS, expose configs under /config
if [[ $BROWSECONFIGS =~ $TRUE_REG ]]; then
    rm -f /var/www/config
    ln -s /var/run /var/www/config
    echo "browse /fdd/config" >> /var/run/caddy/Caddyfile
    sed -e 's/browseconfigs/"enabled" : true/' -i /var/www/env.js
else
    sed -e 's/browseconfigs/"enabled" : false/' -i /var/www/env.js
fi
# If SUPERVISORWEB, enable supervisor control and proxy it
if [[ $SUPERVISORWEB =~ $TRUE_REG ]]; then
    cat <<EOF > /etc/supervisord.d/99-supervisorctl.conf
[inet_http_server]
port=*:$SUPERVISORWEB_PORT
EOF
    PORTS="$PORTS $SUPERVISORWEB_PORT"
    if [[ ! -z $PASSWORD ]]; then
        echo -e "\e[92Adding login credentials to supervisor '\e[96m${USER}\e[34m\e[92m' '\e[96mxxxxxxxx'\e[34m\e[92m.\e[34m"
        echo "username=$USER" >> /etc/supervisord.d/99-supervisorctl.conf
        echo "password=$PASSWORD" >> /etc/supervisord.d/99-supervisorctl.conf
    fi

    # These does not work, because supervisor server
    # can only live under webroot.
#     cat <<EOF >> /var/run/caddy/Caddyfile
# proxy /control 0.0.0.0:$SUPERVISORWEB_PORT {
#     without /control
# }
# EOF
    sed -e 's/supervisorweb/"enabled" : true/' -i  /var/www/env.js
else
    sed -e 's/supervisorweb/"enabled" : false/' -i  /var/www/env.js
fi

# Cleanup previous starts
rm -f /var/run/connect/connectors/{stream-reactor,third-party}/*
# Disable Connectors
OLD_IFS=$IFS
IFS=,
if [[ -z $CONNECTORS ]] && [[ -z $DISABLE ]]; then
    DISABLE="random_string_hope_not_a_connector_name"
fi
if [[ -n $DISABLE ]]; then
    DISABLE=" ${DISABLE//,/ } "
    CONNECTOR_LIST="$(find /opt/lensesio/connectors/stream-reactor -maxdepth 1 -name "kafka-connect-*" -type d | sed -e 's/.*kafka-connect-//' | tr '\n' ',')"
    for connector in $CONNECTOR_LIST; do
        connectorTest=" $connector "
        if [[ $DISABLE =~ $connectorTest ]]; then
            echo "Skipping connector: kafka-connect-${connector}"
        else
            ln -s /opt/lensesio/connectors/stream-reactor/kafka-connect-"${connector}" \
               /var/run/connect/connectors/stream-reactor/kafka-connect-"${connector}"
        fi
    done
    CONNECTOR_LIST="$(find /opt/lensesio/connectors/third-party -maxdepth 1 -name "kafka-connect-*" -type d | sed -e 's/.*kafka-connect-//' | tr '\n' ',')"
    for connector in $CONNECTOR_LIST; do
        connectorTest=" $connector "
        if [[ $DISABLE =~ $connectorTest ]]; then
            echo "Skipping connector: kafka-connect-${connector}"
        else
            ln -s /opt/lensesio/connectors/third-party/kafka-connect-"${connector}" \
               /var/run/connect/connectors/third-party/kafka-connect-"${connector}"
        fi
    done
fi
# Enable Connectors
if [[ -n $CONNECTORS ]]; then
    CONNECTORS=" ${CONNECTORS//,/ } "
    CONNECTOR_LIST="$(find /opt/lensesio/connectors/stream-reactor -maxdepth 1 -name "kafka-connect-*" -type d | sed -e 's/.*kafka-connect-//' | tr '\n' ',')"
    for connector in $CONNECTOR_LIST; do
        connectorTest=" $connector "
        if [[ $CONNECTORS =~ $connectorTest ]]; then
            echo "Enabling connector: kafka-connect-${connector}"
            ln -s /opt/lensesio/connectors/stream-reactor/kafka-connect-"${connector}" \
               /var/run/connect/connectors/stream-reactor/kafka-connect-"${connector}"
        fi
    done
    CONNECTOR_LIST="$(find /opt/lensesio/connectors/third-party -maxdepth 1 -name "kafka-connect-*" -type d | sed -e 's/.*kafka-connect-//' | tr '\n' ',')"
    for connector in $CONNECTOR_LIST; do
        connectorTest=" $connector "
        if [[ $CONNECTORS =~ $connectorTest ]]; then
            echo "Enabling connector: kafka-connect-${connector}"
            ln -s /opt/lensesio/connectors/third-party/kafka-connect-"${connector}" \
               /var/run/connect/connectors/third-party/kafka-connect-"${connector}"
        fi
    done
fi
IFS="$OLD_IFS"

# Enable root-mode if needed
if [[ $RUN_AS_ROOT =~ $TRUE_REG ]]; then
    sed -e 's/user=nobody/;user=nobody/' -i /etc/supervisord.d/*
    echo -e "\e[92mRunning Kafka as root.\e[34m"
fi

# SSL setup
if [[ $ENABLE_SSL =~ $TRUE_REG ]]; then
    PORTS="$PORTS $BROKER_SSL_PORT"
    echo -e "\e[92mTLS enabled.\e[34m"
    if [[ -f /tmp/certs/kafka.jks ]] \
           && [[ -f /tmp/certs/client.jks ]] \
           && [[ -f /tmp/certs/truststore.jks ]]; then
        echo -e "\e[92mOld keystores and truststore found, skipping creation of new ones.\e[34m"
        {
            pushd /tmp/certs
            mkdir -p /var/www/certs/
            cp client.jks truststore.jks /var/www/certs/
            popd
        } >>/var/log/ssl-setup.log 2>&1
    else
        echo -e "\e[92mCreating CA and key-cert pairs.\e[34m"
        {
            mkdir -p /tmp/certs
            pushd /tmp/certs
            # Create Lenses.io Fast Data Dev CA
            quickcert -ca -out lfddca. -CN "Lenses.io's Fast Data Dev Self Signed Certificate Authority"
            SSL_HOSTS="localhost,127.0.0.1,192.168.99.100"
            HOSTNAME=${HOSTNAME:-} # This come from the container, so let's not permit it be unbound
            if [[ ! -z $HOSTNAME ]]; then SSL_HOSTS="$SSL_HOSTS,$HOSTNAME"; fi
            if [[ ! -z $ADV_HOST ]]; then SSL_HOSTS="$SSL_HOSTS,$ADV_HOST"; fi
            if [[ ! -z $SSL_EXTRA_HOSTS ]]; then SSL_HOSTS="$SSL_HOSTS,$SSL_EXTRA_HOSTS"; fi

            # Create Key-Certificate pairs for Kafka and user
            for cert in kafka client clientA clientB; do
                quickcert -cacert lfddca.crt.pem -cakey lfddca.key.pem -out $cert. -CN "$cert" -hosts "$SSL_HOSTS" -duration 3650

                openssl pkcs12 -export \
                        -in "$cert.crt.pem" \
                        -inkey "$cert.key.pem" \
                        -out "$cert.p12" \
                        -name "$cert" \
                        -passout pass:fastdata

                keytool -importkeystore \
                        -noprompt -v \
                        -srckeystore "$cert.p12" \
                        -srcstoretype PKCS12 \
                        -srcstorepass fastdata \
                        -alias "$cert" \
                        -deststorepass fastdata \
                        -destkeypass fastdata \
                        -destkeystore "$cert.jks" \
                        -deststoretype JKS
            done

            keytool -importcert \
                    -noprompt \
                    -keystore truststore.jks \
                    -alias LensesioFastDataDevCA \
                    -file lfddca.crt.pem \
                    -storepass fastdata \
                    -storetype JKS

            mkdir -p /var/www/certs/
            cp client.jks clientA.jks clientB.jks truststore.jks /var/www/certs/

            popd
        } >/var/log/ssl-setup.log 2>&1
    fi
    # Setup the broker with SSL
    cat <<EOF >>/var/run/broker/server.properties
ssl.client.auth=required
ssl.key.password=fastdata
ssl.keystore.location=/tmp/certs/kafka.jks
ssl.keystore.password=fastdata
ssl.truststore.location=/tmp/certs/truststore.jks
ssl.truststore.password=fastdata
ssl.protocol=TLS
ssl.enabled.protocols=TLSv1.2,TLSv1.1,TLSv1
ssl.keystore.type=JKS
ssl.truststore.type=JKS
EOF
    sed -r -e "s|^(listeners=.*)|\1,SSL://:${BROKER_SSL_PORT}|" \
        -i /var/run/broker/server.properties
    if [[ -n ${ADV_HOST} ]] && [[ $TMP_ADV_LISTENERS_SET =~ $TRUE_REG ]]; then
        sed -r \
            -e "s|^(advertised.listeners=.*)|\1,SSL://${ADV_HOST}:${BROKER_SSL_PORT}|" \
            -i /var/run/broker/server.properties
    fi

    # Log authorization requests
    if [[ $DEBUG_AUTH =~ $TRUE_REG ]]; then
        touch /var/log/kafka-authorizer.log
        chmod 666 /var/log/kafka-authorizer.log
        cat <<EOF >> /var/run/broker/log4j.properties
log4j.appender.authorizerAppender=org.apache.log4j.DailyRollingFileAppender
log4j.appender.authorizerAppender.DatePattern='.'yyyy-MM-dd-HH
log4j.appender.authorizerAppender.File=/var/log/kafka-authorizer.log
log4j.appender.authorizerAppender.layout=org.apache.log4j.PatternLayout
log4j.appender.authorizerAppender.layout.ConversionPattern=[%d] %p %m (%c)%n
log4j.logger.kafka.authorizer.logger=INFO, authorizerAppender
log4j.additivity.kafka.authorizer.logger=false
EOF
    fi

    sed -e 's/ssl_browse/"enabled" : true/' -i /var/www/env.js
else
    sed -r -e "s|$BROKER_SSL_PORT||" -i /var/www/env.js
    sed -e 's/ssl_browse/"enabled" : false/' -i /var/www/env.js
fi

# Set web-only mode if needed
if [[ $WEB_ONLY =~ $TRUE_REG ]]; then
    PORTS="$WEB_PORT"
    echo -e "\e[92mWeb only mode. Kafka services will be disabled.\e[39m"
    rm -rf /etc/supervisord.d/*
    cp /usr/local/share/etc/lensesio/supervisord.d/supervisord-web-only.conf /etc/supervisord.d/
    envsubst < /usr/local/share/lensesio/etc/fast-data-dev-ui/env-webonly.js > /var/www/env.js
    export RUNTESTS="${RUNTESTS:-0}"
fi

# Enable userlane if needed
USERLANE=${USERLANE:-false}
if [[ $USERLANE =~ $TRUE_REG ]]; then
    cat <<EOF >> /var/www/env.js

// load Userlane
(function (i, s, o, g, r, a, m) {
  i['UserlaneCommandObject'] = r;
  i[r] =
    i[r] ||
    function () {
      (i[r].q = i[r].q || []).push(arguments);
    };
  (a = s.createElement(o)), (m = s.getElementsByTagName(o)[0]);
  a.async = 1;
  a.src = g;
  m.parentNode.insertBefore(a, m);
})(window, document, 'script', 'https://cdn.userlane.com/userlane.js', 'Userlane');
// initialize Userlane with your Property ID
Userlane('init', 'q2mmy');
EOF
fi

# Set supervisord to output all logs to stdout
if [[ $DEBUG =~ $TRUE_REG ]]; then
    sed -e 's/loglevel=info/loglevel=debug/' -i /etc/supervisord.d/*
fi

# Check for port availability
for port in $PORTS; do
    if [[ $port == 0 ]]; then
        continue
    elif ! /usr/local/bin/checkport -port "$port"; then
        echo "Could not successfully bind to port $port. Maybe some other service"
        echo "in your system is using it? Please free the port and try again."
        echo "Exiting."
        exit 1
    fi
done

# Check for Container's Memory Limit
if [[ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]]; then
    MLB="$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)"
    MLMB="$(( MLB / 1024 / 1024 ))"
    MLREC=3584
    if [[ "$MLMB" -lt "$MLREC" ]]; then
        echo -e "\e[91mMemory limit for container is \e[93m${MLMB} MiB\e[91m, which is less than the lowest"
        echo -e "recommended of \e[93m${MLREC} MiB\e[91m. You will probably experience instability issues.\e[39m"
    fi
fi

# Check for Available RAM
set +o errexit
RAKB="$(grep MemA /proc/meminfo | sed -r -e 's/.* ([0-9]+) kB/\1/')"
if [[ $STRICT_SCRIPT =~ $TRUE_REG ]]; then set -o errexit; fi
if [[ -z "$RAKB" ]]; then
        echo -e "\e[91mCould not detect available RAM, probably due to very old Linux Kernel."
        echo -e "\e[91mPlease make sure you have the recommended minimum of \e[93m4096 MiB\e[91m RAM available for fast-data-dev.\e[39m"
else
    RAMB="$(( RAKB / 1024 ))"
    RAREC=4096
    if [[ "$RAMB" -lt "$RAREC" ]]; then
        echo -e "\e[91mOperating system RAM available is \e[93m${RAMB} MiB\e[91m, which is less than the lowest"
        echo -e "recommended of \e[93m${RAREC} MiB\e[91m. Your system performance may be seriously impacted.\e[39m"
    fi
fi
# Check for Available Disk
DAM="$(df /tmp --output=avail -BM | tail -n1 | sed -r -e 's/M//' -e 's/[ ]*([0-9]+)[ ]*/\1/')"
if [[ -z "$DAM" ]] || ! [[ "$DAM" =~ ^[0-9]+$ ]]; then
    echo -e "\e[91mCould not detect available Disk space."
    echo -e "\e[91mPlease make sure you have the recommended minimum of \e[93m256 MiB\e[91m disk space available for '/tmp' directory.\e[39m"
else
    DAREC=256
    if [[ "$DAM" -lt $DAREC ]]; then
        echo -e "\e[91mDisk space available for the '/tmp' directory is just \e[93m${DAM} MiB\e[91m which is less than the lowest"
        echo -e "recommended of \e[93m${DAREC} MiB\e[91m. The container’s services may fail to start.\e[39m"
    fi
fi

PRINT_HOST=${ADV_HOST:-127.0.0.1}
export PRINT_HOST
WEB_TERMINAL_CREDS=${WEB_TERMINAL_CREDS:-admin:admin}
export WEB_TERMINAL_CREDS
# shellcheck disable=SC1091
[[ -f /build.info ]] && source /build.info
echo -e "\e[92mStarting services.\e[39m"
echo -e "\e[92mThis is Lenses.io's Box. Lenses $FDD_LENSES_VERSION, Kafka ${FDD_KAFKA_VERSION} (Lenses.io's Kafka Distribution).\e[39m"
echo -e "\e[92mYou may visit \e[96mhttp://${PRINT_HOST}:${WEB_PORT}${LENSES_ROOT_PATH}\e[92m in about \e[96ma minute\e[92m. Login with \e[96madmin/admin\e[92m. The services need some time to start up.\e[39m"
echo -e "\e[92mThe broker is accessible at \e[96mPLAINTEXT://${PRINT_HOST}:${BROKER_PORT}\e[92m, Schema Registry at \e[96mhttp://${PRINT_HOST}:${REGISTRY_PORT}\e[92m and Zookeeper at \e[96m${PRINT_HOST}:${ZK_PORT}\e[92m."
echo -e "\e[92mFor documentation please refer to -> \e[96mhttps://docs.lenses.io/dev/lenses-box/ \e[39m"
echo -e "\e[92mIf you have trouble running the image or want to give us feedback (or a rant), come chat with us at \e[96mhttps://ask.lenses.io\e[92m or \e[96mhttps://launchpass.com/lensesio \e[39m"
echo -e "\e[92mYou can view the logs for all running services at \e[96mhttp://${PRINT_HOST}:${WEB_PORT}/fdd/logs \e[39m"
export FDD_DHOST="http://${PRINT_HOST}:${WEB_PORT}"

# Set sample data if needed
if [[ $RUNNING_SAMPLEDATA =~ $TRUE_REG ]] && [[ $SAMPLEDATA =~ $TRUE_REG ]]; then
    envsubst < /usr/local/share/lensesio/etc/supervisord.d/99-supervisord-running-sample-data.conf \
             > /etc/supervisord.d/99-supervisord-running-sample-data.conf
    envsubst < /usr/local/share/lensesio/etc/supervisord.d/09-nullsink-connector.conf \
             > /etc/supervisord.d/09-nullsink-connector.conf
    envsubst < /usr/local/share/lensesio/etc/supervisord.d/09-elastic-ships-connector.conf \
             > /etc/supervisord.d/09-elastic-ships-connector.conf
elif [[ $SAMPLEDATA =~ $TRUE_REG ]]; then
    # This should be added only if we don't have running data, because it sets
    # retention period to 10 years (as the data is so few in this case).
    envsubst < /usr/local/share/lensesio/etc/supervisord.d/99-supervisord-sample-data.conf \
             > /etc/supervisord.d/99-supervisord-sample-data.conf
else
    # If SAMPLEDATA=0 and FORWARDLOGS connector not explicitly requested
    export FORWARDLOGS=0
    export NULLSINK=0
    export ELASTIC_SHIPS=0
fi

LICENSE_URL=${LICENSE_URL:-}
EULA=${EULA:-$LICENSE_URL}
LICENSE=${LICENSE:-}
# Configure lenses provisioning
## License
if [[ -f /license.json ]]; then
    cp /license.json "$LENSES_LICENSE_FILE"
elif [[ ! -z $LICENSE ]] && [[ ! -f $LENSES_LICENSE_FILE ]]; then
    echo "$LICENSE" >> "$LENSES_LICENSE_FILE"
elif [[ ! -z $EULA ]] && [[ ! -f $LENSES_LICENSE_FILE ]]; then
    if [[ $EULA =~ CHECK_YOUR_EMAIL_FOR_KEY ]]; then
        echo
        echo "Oops! It seems you just ran the sample command provided in the website."
        echo "Please check your email to find the actual URL of your license. :)"
        exit 1
    fi
    set +o errexit
    wget --user-agent="Lenses Box (Lenses $FDD_LENSES_VERSION; Kafka $FDD_KAFKA_VERSION; Commit: ${BUILD_COMMIT::8})" \
         -q "$EULA" -O "$LENSES_LICENSE_FILE"
    if [[ $? -ne 0 ]]; then
        echo -e "\e[91mCould not download license. Maybe the link was wrong or the license expired?"
        echo -e "Please check and try again. If the problem persists please contact us.\e[39m"
        exit 1
    fi
    if [[ $STRICT_SCRIPT =~ $TRUE_REG ]]; then set -o errexit; fi
elif [[ -f $LENSES_LICENSE_FILE ]]; then
    echo
else
    echo -e "\e[91mNo license was provided. Lenses will not work."
    echo -e "\e[93mPlease visit <https://lenses.io> to get your free license.\e[91m"
    echo -e "If you already obtained a license, please either provide it at '/license.json'"
    echo -e "inside the container or export its contents as the environment variable 'LICENSE'.\e[39m"
fi
if [[ $PROVISION_LENSES =~ $TRUE_REG ]]; then
    mkdir -p /var/run/lenses/provision
    if [[ $BROKER_PORT != 0 ]]; then
        cat <<EOF > /var/run/lenses/provision/provisioning.yaml
kafka:
  - name: kafka
    version: 1
    tags: [ 'kafka', 'dev' ]
    configuration:
      metricsType:
        value: JMX
      metricsPort:
        value: $BROKER_JMX_PORT
EOF
        if [[ $ENABLE_SSL =~ $TRUE_REG ]]; then
            mkdir -p /var/run/lenses/provision/files
            cp /tmp/certs/client.jks /var/run/lenses/provision/files
            cp /tmp/certs/truststore.jks /var/run/lenses/provision/files
            cat <<EOF >> /var/run/lenses/provision/provisioning.yaml
      kafkaBootstrapServers:
        value:
          - SSL://127.0.0.1:$BROKER_SSL_PORT
      protocol:
        value: SSL
      sslKeystore:
        file: client.jks
      sslKeystorePassword:
        value: fastdata
      sslKeyPassword:
        value: fastdata
      sslTruststore:
        file: truststore.jks
      sslTruststorePassword:
        value: fastdata
EOF
        else
            cat <<EOF >> /var/run/lenses/provision/provisioning.yaml
      kafkaBootstrapServers:
        value: $LENSES_KAFKA_BROKERS
      protocol:
        value: PLAINTEXT
EOF
        fi
    fi
    if [[ $REGISTRY_PORT != 0 ]]; then
        cat <<EOF >> /var/run/lenses/provision/provisioning.yaml
confluentSchemaRegistry:
  - name: schema-registry
    version: 1
    tags: [ 'dev' ]
    configuration:
      schemaRegistryUrls:
        value: $LENSES_SCHEMA_REGISTRY_URLS
      metricsType:
        value: JMX
      metricsPort:
        value: $REGISTRY_JMX_PORT
EOF
    fi
    if [[ $CONNECT_PORT != 0 ]]; then
        cat <<EOF >> /var/run/lenses/provision/provisioning.yaml
connect:
  - name: dev
    version: 1
    tags: [ 'dev' ]
    configuration:
      workers:
        value: $LENSES_KAFKA_CONNECT_CLUSTERS
      aes256Key:
        value: 0123456789abcdef0123456789abcdef
      metricsType:
        value: JMX
      metricsPort:
        value: $CONNECT_JMX_PORT
EOF
    fi
    if [[ $ZK_PORT != 0 ]]; then
        cat <<EOF >> /var/run/lenses/provision/provisioning.yaml
zookeeper:
  - name: zookeeper
    tags: [ 'dev' ]
    version: 1
    configuration:
      zookeeperUrls:
        value: $LENSES_ZOOKEEPER_HOSTS
      metricsPort:
        value: $ZK_JMX_PORT
      metricsType:
        value: JMX
      zookeeperSessionTimeout:
        value: 18000
      zookeeperConnectionTimeout:
        value: 18000
EOF
    fi
    if [ -f /provisioning.append.yaml ]; then
        echo "Found '/provisioning.append.yaml', appending to autocreated one. For common settings, the user provided takes precedence."
        cat /provisioning.append.yaml >> /var/run/lenses/provision/provisioning.yaml
    fi
    PROVISIONING_APPEND_YAML=${PROVISIONING_APPEND_YAML:-}
    if [[ -n "$PROVISIONING_APPEND_YAML" ]]; then
        echo "Found 'PROVISIONING_APPEND_YAML' env var, appending to autocreated one. For common settings, the user provided takes precedence."
        echo "$PROVISIONING_APPEND_YAML" >> /var/run/lenses/provision/provisioning.yaml
    fi
fi

chown nobody:nogroup "$LENSES_LICENSE_FILE"
mkdir -p /var/run/lenses/logs
chown nobody:nogroup /var/run/lenses/*
rm -rf /var/www-lenses
mkdir /var/www-lenses
ln -s /var/www /var/www-lenses/fdd
echo "}" >> /var/run/caddy/Caddyfile

# Run post-setup user provided scripts.
export POST_SETUP=${POST_SETUP:-}
export POST_SETUP_FILE=${POST_SETUP_FILE:-}
export POST_SETUP_URL=${POST_SETUP_URL:-}
if [[ -n "$POST_SETUP" ]]; then
    $POST_SETUP
fi
if [[ -n "$POST_SETUP_FILE" ]]; then
    if [[ ! -f "$POST_SETUP_FILE" ]]; then
        echo "Although POST_SETUP_FILE is set, I cannot find the file."
    fi
    source $POST_SETUP_FILE
fi
if [[ -n "$POST_SETUP_URL" ]]; then
    curl "$POST_SETUP_URL" --silent --show-error --fail --output /tmp/POST_SETUP_URL
    source /tmp/POST_SETUP_URL
    rm /tmp/POST_SETUP_URL
fi

exec /usr/bin/supervisord -c /etc/supervisord.conf

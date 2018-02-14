#!/usr/bin/env bash

[[ -n SET_X ]] && set -x || set +x

set -e
set -u
set -o pipefail

WORKDIR="$(mktemp -d)"

# Login args for development archives
DEVARCH_USER=${DEVARCH_USER:-}
DEVARCH_PASS=${DEVARCH_PASS:-}
LKD_VERSION=${LKD_VERSION:-1.0.0-r0}

############
# Add kafka/
############

# Add Apache Kafka (includes Connect and Zookeeper)
KAFKA_VERSION="${KAFKA_VERSION:-1.0.0}"
KAFKA_LVERSION="${KAFKA_LVERSION:-${KAFKA_VERSION}-L1}"
KAFKA_URL="${KAFKA_URL:-https://archive.landoop.com/lkd/packages/kafka_2.11-${KAFKA_LVERSION}-lkd.tar.gz}"

wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_URL" -O "$WORKDIR"/kafka.tar.gz
tar --no-same-owner -xzf "$WORKDIR"/kafka.tar.gz -C "$WORKDIR"
mkdir "$WORKDIR"/landoop/kafka/logs && chmod 1777 "$WORKDIR"/landoop/kafka/logs
rm -rf "$WORKDIR"/kafka.tar.gz
ln -s "$WORKDIR"/landoop/kafka ""$WORKDIR"/landoop/kafka-${KAFKA_VERSION}"

# Add Schema Registry and REST Proxy
REGISTRY_VERSION="${REGISTRY_VERSION:-4.0.0-lkd}"
REGISTRY_URL="${REGISTRY_URL:-https://archive.landoop.com/lkd/packages/schema_registry_${REGISTRY_VERSION}.tar.gz}"
wget $DEVARCH_USER $DEVARCH_PASS "$REGISTRY_URL" -O "$WORKDIR"/registry.tar.gz
tar --no-same-owner -xzf "$WORKDIR"/registry.tar.gz -C "$WORKDIR"/
rm -rf "$WORKDIR"/registry.tar.gz

REST_VERSION="${REST_VERSION:-4.0.0-lkd}"
REST_URL="${REST_URL:-https://archive.landoop.com/lkd/packages/rest_proxy_${REST_VERSION}.tar.gz}"
wget $DEVARCH_USER $DEVARCH_PASS "$REST_URL" -O "$WORKDIR"/rest.tar.gz
tar --no-same-owner -xzf "$WORKDIR"/rest.tar.gz -C "$WORKDIR"/
rm -rf "$WORKDIR"/rest.tar.gz

# Configure Connect and Confluent Components to support CORS
echo "access.control.allow.methods=GET,POST,PUT,DELETE,OPTIONS" >> "$WORKDIR"/landoop/kafka/etc/schema-registry/schema-registry.properties
echo 'access.control.allow.origin=*' >> "$WORKDIR"/landoop/kafka/etc/schema-registry/schema-registry.properties
echo "access.control.allow.methods=GET,POST,PUT,DELETE,OPTIONS" >> "$WORKDIR"/landoop/kafka/etc/kafka-rest/kafka-rest.properties
echo 'access.control.allow.origin=*' >> "$WORKDIR"/landoop/kafka/etc/kafka-rest/kafka-rest.properties
echo "access.control.allow.methods=GET,POST,PUT,DELETE,OPTIONS" >> "$WORKDIR"/landoop/kafka/etc/schema-registry/connect-avro-distributed.properties
echo 'access.control.allow.origin=*' >> "$WORKDIR"/landoop/kafka/etc/schema-registry/connect-avro-distributed.properties


#################
# Add connectors/
#################

# Add Stream Reactor and Elastic Search (for elastic connector)
STREAM_REACTOR_VERSION="${STREAM_REACTOR_VERSION:-1.0.0}"
STREAM_REACTOR_URL="${STREAM_REACTOR_URL:-https://archive.landoop.com/stream-reactor/stream-reactor-${STREAM_REACTOR_VERSION}_connect${KAFKA_VERSION}.tar.gz}"
ELASTICSEARCH_2X_VERSION="${ELASTICSEARCH_2X_VERSION:-2.4.6}"
ACTIVEMQ_VERSION="${ACTIVEMQ_VERSION:-5.12.3}"
CALCITE_LINQ4J_VERSION="${CALCITE_LINQ4J_VERSION:-1.12.0}"

wget "${STREAM_REACTOR_URL}" -O /stream-reactor.tar.gz
# # Stream Reactor Archive already has hardlinks. Let's de-reference them so we can run duphard for all the files later on
# # (disabled as it doesn't make much of a difference)
# TEMP_DIR="$(mktemp -d)"
# pushd "$TEMP_DIR"
# tar -xzf /stream-reactor.tar.gz -C .
# rm /stream-reactor.tar.gz
# tar czf /stream-reactor.tar.gz --hard-dereference *
# popd
# rm -rf "$TEMP_DIR"
mkdir -p "$WORKDIR"/landoop/connectors/stream-reactor
tar -xzf /stream-reactor.tar.gz --no-same-owner --strip-components=1 -C "$WORKDIR"/landoop/connectors/stream-reactor
rm /stream-reactor.tar.gz

wget https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/${ELASTICSEARCH_2X_VERSION}/elasticsearch-${ELASTICSEARCH_2X_VERSION}.tar.gz \
     -O /elasticsearch.tar.gz
mkdir /elasticsearch
tar xf /elasticsearch.tar.gz --no-same-owner --strip-components=1 -C /elasticsearch
mv /elasticsearch/lib/*.jar "$WORKDIR"/landoop/connectors/stream-reactor/kafka-connect-elastic/
rm -rf /elasticsearch*

wget http://central.maven.org/maven2/org/apache/activemq/activemq-all/${ACTIVEMQ_VERSION}/activemq-all-${ACTIVEMQ_VERSION}.jar \
     -P "$WORKDIR"/landoop/connectors/stream-reactor/kafka-connect-jms
wget http://central.maven.org/maven2/org/apache/calcite/calcite-linq4j/${CALCITE_LINQ4J_VERSION}/calcite-linq4j-${CALCITE_LINQ4J_VERSION}.jar \
     -O /calcite-linq4j-${CALCITE_LINQ4J_VERSION}.jar
for path in "$WORKDIR"/landoop/connectors/stream-reactor/kafka-connect-*; do
    cp /calcite-linq4j-${CALCITE_LINQ4J_VERSION}.jar $path/
done
rm /calcite-linq4j-${CALCITE_LINQ4J_VERSION}.jar

mkdir -p "$WORKDIR"/landoop/kafka/share/java/landoop-common
for file in $(find "$WORKDIR"/landoop/connectors/stream-reactor -maxdepth 2 -type f -exec basename {} \; | sort | uniq -c | grep -E "^\s+20 " | awk '{print $2}' );
do
    cp "$WORKDIR"/landoop/connectors/stream-reactor/kafka-connect-elastic/$file "$WORKDIR"/landoop/kafka/share/java/landoop-common/
    rm -f "$WORKDIR"/landoop/connectors/stream-reactor/kafka-connect-*/$file
done

echo "plugin.path=/opt/landoop/connectors/stream-reactor,/opt/landoop/connectors/third-party" \
             >> "$WORKDIR"/landoop/kafka/etc/schema-registry/connect-avro-distributed.properties


# Add Third Party Connectors

## Twitter
TWITTER_CONNECTOR_URL="https://archive.landoop.com/third-party/kafka-connect-twitter/kafka-connect-twitter-0.1-master-33331ea-connect-1.0.0-jar-with-dependencies.jar"
mkdir -p "$WORKDIR"/landoop/connectors/third-party/kafka-connect-twitter
wget "$TWITTER_CONNECTOR_URL" -P "$WORKDIR"/landoop/connectors/third-party/kafka-connect-twitter
## Kafka Connect JDBC
KAFKA_CONNECT_JDBC_VERSION="${KAFKA_CONNECT_JDBC_VERSION:-4.0.0-lkd}"
KAFKA_CONNECT_JDBC_URL="${KAFKA_CONNECT_JDBC_URL:-https://archive.landoop.com/lkd/packages/kafka-connect-jdbc-${KAFKA_CONNECT_JDBC_VERSION}.tar.gz}"
wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_CONNECT_JDBC_URL" -O "$WORKDIR"/kafka-connect-jdbc.tar.gz
mkdir -p "$WORKDIR"/landoop/connectors/third-party/
tar --no-same-owner -xzf "$WORKDIR"/kafka-connect-jdbc.tar.gz -C "$WORKDIR"/landoop/connectors/third-party/
rm -rf "$WORKDIR"/kafka-connect-jdbc.tar.gz
## Kafka Connect ELASTICSEARCH
KAFKA_CONNECT_ELASTICSEARCH_VERSION="${KAFKA_CONNECT_ELASTICSEARCH_VERSION:-4.0.0-lkd}"
KAFKA_CONNECT_ELASTICSEARCH_URL="${KAFKA_CONNECT_ELASTICSEARCH_URL:-https://archive.landoop.com/lkd/packages/kafka-connect-elasticsearch-${KAFKA_CONNECT_ELASTICSEARCH_VERSION}.tar.gz}"
wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_CONNECT_ELASTICSEARCH_URL" -O "$WORKDIR"/kafka-connect-elasticsearch.tar.gz
mkdir -p "$WORKDIR"/landoop/connectors/third-party/
tar --no-same-owner -xzf "$WORKDIR"/kafka-connect-elasticsearch.tar.gz -C "$WORKDIR"/landoop/connectors/third-party/
rm -rf "$WORKDIR"/kafka-connect-elasticsearch.tar.gz
## Kafka Connect HDFS
KAFKA_CONNECT_HDFS_VERSION="${KAFKA_CONNECT_HDFS_VERSION:-4.0.0-lkd}"
KAFKA_CONNECT_HDFS_URL="${KAFKA_CONNECT_HDFS_URL:-https://archive.landoop.com/lkd/packages/kafka-connect-hdfs-${KAFKA_CONNECT_HDFS_VERSION}.tar.gz}"
wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_CONNECT_HDFS_URL" -O "$WORKDIR"/kafka-connect-hdfs.tar.gz
mkdir -p "$WORKDIR"/landoop/connectors/third-party/
tar --no-same-owner -xzf "$WORKDIR"/kafka-connect-hdfs.tar.gz -C "$WORKDIR"/landoop/connectors/third-party/
rm -rf "$WORKDIR"/kafka-connect-hdfs.tar.gz
# Kafka Connect S3
KAFKA_CONNECT_S3_VERSION="${KAFKA_CONNECT_S3_VERSION:-4.0.0-lkd}"
KAFKA_CONNECT_S3_URL="${KAFKA_CONNECT_S3_URL:-https://archive.landoop.com/lkd/packages/kafka-connect-s3-${KAFKA_CONNECT_S3_VERSION}.tar.gz}"
wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_CONNECT_S3_URL" -O "$WORKDIR"/kafka-connect-s3.tar.gz
mkdir -p "$WORKDIR"/landoop/connectors/third-party/
tar --no-same-owner -xzf "$WORKDIR"/kafka-connect-s3.tar.gz -C "$WORKDIR"/landoop/connectors/third-party/
rm -rf "$WORKDIR"/kafka-connect-s3.tar.gz


############
# Add tools/
############
COYOTE_VERSION="1.2"
COYOTE_URL="https://github.com/Landoop/coyote/releases/download/v${COYOTE_VERSION}/coyote-${COYOTE_VERSION}"
mkdir -p \
      "$WORKDIR"/landoop/tools/bin/win \
      "$WORKDIR"/landoop/tools/bin/mac \
      "$WORKDIR"/landoop/tools/share/coyote/examples
wget "$COYOTE_URL"-linux-amd64 -O "$WORKDIR"/landoop/tools/bin/coyote
wget "$COYOTE_URL"-darwin-amd64 -O "$WORKDIR"/landoop/tools/bin/mac/coyote
wget "$COYOTE_URL"-windows-amd64.exe -O "$WORKDIR"/landoop/tools/bin/win/coyote
chmod +x \
      "$WORKDIR"/landoop/tools/bin/coyote \
      "$WORKDIR"/landoop/tools/bin/mac/coyote \
      "$WORKDIR"/landoop/tools/bin/win/coyote

cp /data/simple-integration-tests.yml "$WORKDIR"/landoop/tools/share/coyote/examples

# Add Kafka Topic UI, Schema Registry UI, Kafka Connect UI
KAFKA_TOPICS_UI_VERSION="0.9.3"
KAFKA_TOPICS_UI_URL="https://github.com/Landoop/kafka-topics-ui/releases/download/v${KAFKA_TOPICS_UI_VERSION}/kafka-topics-ui-${KAFKA_TOPICS_UI_VERSION}.tar.gz"
SCHEMA_REGISTRY_UI_VERSION="0.9.4"
SCHEMA_REGISTRY_UI_URL="https://github.com/Landoop/schema-registry-ui/releases/download/v.${SCHEMA_REGISTRY_UI_VERSION}/schema-registry-ui-${SCHEMA_REGISTRY_UI_VERSION}.tar.gz"
KAFKA_CONNECT_UI_VERSION="0.9.4"
KAFKA_CONNECT_UI_URL="https://github.com/Landoop/kafka-connect-ui/releases/download/v.${KAFKA_CONNECT_UI_VERSION}/kafka-connect-ui-${KAFKA_CONNECT_UI_VERSION}.tar.gz"
mkdir -p \
      "$WORKDIR"/landoop/tools/share/kafka-topics-ui/ \
      "$WORKDIR"/landoop/tools/share/schema-registry-ui/ \
      "$WORKDIR"/landoop/tools/share/kafka-connect-ui/
wget "$KAFKA_TOPICS_UI_URL" -O "$WORKDIR"/landoop/tools/share/kafka-topics-ui/kafka-topics-ui.tar.gz
wget "$SCHEMA_REGISTRY_UI_URL" -O "$WORKDIR"/landoop/tools/share/schema-registry-ui/schema-registry-ui.tar.gz
wget "$KAFKA_CONNECT_UI_URL" -O "$WORKDIR"/landoop/tools/share/kafka-connect-ui/kafka-connect-ui.tar.gz

# Add Kafka Autocomplete
KAFKA_AUTOCOMPLETE_VERSION="0.3"
KAFKA_AUTOCOMPLETE_URL="https://github.com/Landoop/kafka-autocomplete/releases/download/${KAFKA_AUTOCOMPLETE_VERSION}/kafka"
mkdir -p \
      "$WORKDIR"/landoop/tools/share/kafka-autocomplete \
      "$WORKDIR"/landoop/tools/share/bash-completion/completions
wget "$KAFKA_AUTOCOMPLETE_URL" -O "$WORKDIR"/landoop/tools/share/kafka-autocomplete/kafka
wget "$KAFKA_AUTOCOMPLETE_URL" -O "$WORKDIR"/landoop/tools/share/bash-completion/completions/kafka


##########
# Finalize
##########

echo "LKD_VERSION=${LKD_VERSION}"                               | tee -a "$WORKDIR"/landoop/build.info
echo "KAFKA_VERSION=${KAFKA_LVERSION}"                          | tee -a "$WORKDIR"/landoop/build.info
echo "CONNECT_VERSION=${KAFKA_LVERSION}"                        | tee -a "$WORKDIR"/landoop/build.info
echo "SCHEMA_REGISTRY_VERSION=${REGISTRY_VERSION}"              | tee -a "$WORKDIR"/landoop/build.info
echo "REST_PROXY_VERSION=${REST_VERSION}"                       | tee -a "$WORKDIR"/landoop/build.info
echo "STREAM_REACTOR_VERSION=${STREAM_REACTOR_VERSION}"         | tee -a "$WORKDIR"/landoop/build.info
echo "KAFKA_CONNECT_JDBC_VERSION=${KAFKA_CONNECT_JDBC_VERSION}" | tee -a "$WORKDIR"/landoop/build.info
echo "KAFKA_CONNECT_ELASTICSEARCH_VERSION=${KAFKA_CONNECT_ELASTICSEARCH_VERSION}" | tee -a "$WORKDIR"/landoop/build.info
echo "KAFKA_CONNECT_HDFS_VERSION=${KAFKA_CONNECT_HDFS_VERSION}" | tee -a "$WORKDIR"/landoop/build.info
echo "KAFKA_CONNECT_S3_VERSION=${KAFKA_CONNECT_S3_VERSION}"     | tee -a "$WORKDIR"/landoop/build.info
echo "KAFKA_TOPICS_UI=${KAFKA_TOPICS_UI_VERSION}"              | tee -a "$WORKDIR"/landoop/build.info
echo "SCHEMA_REGISTRY_UI=${SCHEMA_REGISTRY_UI_VERSION}"     | tee -a "$WORKDIR"/landoop/build.info
echo "KAFKA_CONNECT_UI=${KAFKA_CONNECT_UI_VERSION}"     | tee -a "$WORKDIR"/landoop/build.info
echo "COYOTE=${COYOTE_VERSION}"     | tee -a "$WORKDIR"/landoop/build.info
echo "KAFKA_AUTOCOMPLETE=${KAFKA_AUTOCOMPLETE_VERSION}"     | tee -a "$WORKDIR"/landoop/build.info

# duphard (replace duplicates with hard links) and create archive
duphard -d=0 "$WORKDIR"/landoop
tar czf LKD-${LKD_VERSION}.tar.gz \
    --owner=root \
    --group=root \
    -C "$WORKDIR" \
    landoop
mkdir -p /mnt
# Chown archives so they can be read from the user who run the docker
chown --reference=/mnt LKD-${LKD_VERSION}.tar.gz
mv LKD-${LKD_VERSION}.tar.gz /mnt/
rm -rf "$WORKDIR"

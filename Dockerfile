ARG LENSES_VERSION=5.3.0
ARG LENSES_ARCHIVE=remote
ARG AD_URL=https://archive.lenses.io/lenses/5.3/lenses-$LENSES_VERSION-linux64.tar.gz
ARG LENSESCLI_ARCHIVE=remote
ARG LC_VERSION=5.3.0
ARG LC_URL=https://archive.lenses.io/lenses/5.3/cli/lenses-cli-$TARGETOS-$TARGETARCH-$LC_VERSION.tar.gz

#== Docker image that builds Lenses.io's Kafka Distributions and tools ==#

FROM debian:bullseye as compile-lkd
MAINTAINER Marios Andreopoulos <marios@lenses.io>
ARG TARGETARCH TARGETOS

RUN printenv \
    && apt-get update \
    && apt-get install -y \
         unzip \
         wget \
	 file \
    && rm -rf /var/lib/apt/lists/* \
    && echo "progress = dot:giga" | tee /etc/wgetrc \
    && mkdir -p /mnt /opt /data \
    && wget https://github.com/andmarios/duphard/releases/download/v1.1/duphard-${TARGETOS}-${TARGETARCH} -O /bin/duphard \
    && chmod +x /bin/duphard

SHELL ["/bin/bash", "-c"]
WORKDIR /

# Login args for development archives
ARG DEVARCH_USER
ARG DEVARCH_PASS
ARG ARCHIVE_SERVER=https://archive.lenses.io
ARG LKD_VERSION=3.3.1-L0

############
# Add kafka/
############

# Add Apache Kafka (includes Connect and Zookeeper)
ARG KAFKA_VERSION=3.3.1
ARG KAFKA_LVERSION="${KAFKA_VERSION}-L0"
ARG KAFKA_URL="${ARCHIVE_SERVER}/lkd/packages/kafka/kafka-2.13-${KAFKA_LVERSION}-lkd.tar.gz"

RUN wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_URL" -O /opt/kafka.tar.gz \
    && tar --no-same-owner -xzf /opt/kafka.tar.gz -C /opt \
    && mkdir /opt/landoop/kafka/logs && chmod 1777 /opt/landoop/kafka/logs \
    && rm -rf /opt/kafka.tar.gz

# Add Schema Registry and REST Proxy
ARG REGISTRY_VERSION=7.3.0-lkd-r0
ARG REGISTRY_URL="${ARCHIVE_SERVER}/lkd/packages/schema-registry/schema-registry-${REGISTRY_VERSION}.tar.gz"
RUN wget $DEVARCH_USER $DEVARCH_PASS "$REGISTRY_URL" -O /opt/registry.tar.gz \
    && tar --no-same-owner -xzf /opt/registry.tar.gz -C /opt/ \
    && rm -rf /opt/registry.tar.gz

ARG REST_VERSION=7.3.0-lkd-r0
ARG REST_URL="${ARCHIVE_SERVER}/lkd/packages/rest-proxy/rest-proxy-${REST_VERSION}.tar.gz"
RUN wget $DEVARCH_USER $DEVARCH_PASS "$REST_URL" -O /opt/rest.tar.gz \
    && tar --no-same-owner -xzf /opt/rest.tar.gz -C /opt/ \
    && rm -rf /opt/rest.tar.gz

# Configure Connect and Confluent Components to support CORS
RUN echo -e 'access.control.allow.methods=GET,POST,PUT,DELETE,OPTIONS\naccess.control.allow.origin=*' \
         | tee -a /opt/landoop/kafka/etc/schema-registry/schema-registry.properties \
         | tee -a /opt/landoop/kafka/etc/kafka-rest/kafka-rest.properties \
         | tee -a /opt/landoop/kafka/etc/schema-registry/connect-avro-distributed.properties


#################
# Add connectors/
#################

# Add Stream Reactor and needed components
ARG STREAM_REACTOR_VERSION=5.0.0
ARG STREAM_REACTOR_URL="https://archive.lenses.io/lkd/packages/connectors/stream-reactor/stream-reactor-${STREAM_REACTOR_VERSION}.tar.gz"
ARG ACTIVEMQ_VERSION=5.12.3

RUN wget $DEVARCH_USER $DEVARCH_PASS "${STREAM_REACTOR_URL}" -O /stream-reactor.tar.gz \
    && mkdir -p /opt/landoop/connectors/stream-reactor \
    && tar -xf /stream-reactor.tar.gz \
           --no-same-owner \
           --strip-components=1 \
           -C /opt/landoop/connectors/stream-reactor \
    && rm /stream-reactor.tar.gz \
    && rm -rf /opt/landoop/connectors/stream-reactor/kafka-connect-hive-1.1 \
    && wget https://repo1.maven.org/maven2/org/apache/activemq/activemq-all/${ACTIVEMQ_VERSION}/activemq-all-${ACTIVEMQ_VERSION}.jar \
            -P /opt/landoop/connectors/stream-reactor/kafka-connect-jms \
    && mkdir -p /opt/landoop/kafka/share/java/landoop-common \
    && export _NUM_CONNECTORS=$(ls /opt/landoop/connectors/stream-reactor | wc -l) \
    && for file in $(find /opt/landoop/connectors/stream-reactor -maxdepth 2 -type f -exec basename {} \; | grep -Ev "scala-logging|kafka-connect-common|scala-" | grep jar | grep -v log4j-over-slf4j | sort | uniq -c | grep -E "^\s+${_NUM_CONNECTORS} " | awk '{print $2}' ); do \
         cp /opt/landoop/connectors/stream-reactor/kafka-connect-aws-s3/$file /opt/landoop/kafka/share/java/landoop-common/; \
         rm -f /opt/landoop/connectors/stream-reactor/kafka-connect-*/$file; \
       done \
    && for file in $(find /opt/landoop/kafka/share/java/{kafka,landoop-common} -maxdepth 1 -type f -exec basename {} \; | sort | uniq -c | grep -E "^\s+2 " | awk '{print $2}' ); do \
         echo "Removing duplicate /opt/landoop/kafka/share/java/landoop-common/$file."; \
         rm -f /opt/landoop/kafka/share/java/landoop-common/$file; \
       done \
    && rm -f /opt/landoop/connectors/stream-reactor/*/*{javadoc,scaladoc,sources}.jar \
    && echo "plugin.path=/opt/landoop/connectors/stream-reactor,/opt/landoop/connectors/third-party" \
            >> /opt/landoop/kafka/etc/schema-registry/connect-avro-distributed.properties

# Add Secrets Provider
ARG SECRET_PROVIDER_VERSION=2.2.0
ARG SECRET_PROVIDER_URL="https://github.com/lensesio/secret-provider/releases/download/${SECRET_PROVIDER_VERSION}/secret-provider-${SECRET_PROVIDER_VERSION}-all.jar"
RUN mkdir -p /opt/landoop/connectors/stream-reactor/kafka-connect-secret-provider \
    && wget "${SECRET_PROVIDER_URL}" -P "/opt/landoop/connectors/stream-reactor/kafka-connect-secret-provider"

# Add Third Party Connectors

## Filesource
RUN mkdir -p /opt/landoop/connectors/third-party/kafka-connect-file \
    && ln -s /opt/landoop/kafka/share/java/kafka/connect-file-${KAFKA_LVERSION}.jar /opt/landoop/connectors/third-party/kafka-connect-file/connect-file-${KAFKA_LVERSION}.jar

## Twitter
ARG TWITTER_CONNECTOR_URL="https://archive.lenses.io/third-party/kafka-connect-twitter/kafka-connect-twitter-0.1-master-33331ea-connect-1.0.0-jar-with-dependencies.jar"
RUN mkdir -p /opt/landoop/connectors/third-party/kafka-connect-twitter \
    && wget "$TWITTER_CONNECTOR_URL" -P /opt/landoop/connectors/third-party/kafka-connect-twitter

## Kafka Connect JDBC
ARG KAFKA_CONNECT_JDBC_VERSION=10.6.0-lkd-r0
ARG KAFKA_CONNECT_JDBC_URL="${ARCHIVE_SERVER}/lkd/packages/connectors/third-party/kafka-connect-jdbc/kafka-connect-jdbc-${KAFKA_CONNECT_JDBC_VERSION}.tar.gz"
RUN wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_CONNECT_JDBC_URL" \
         -O /opt/kafka-connect-jdbc.tar.gz \
    && mkdir -p /opt/landoop/connectors/third-party/ \
    && tar --no-same-owner -xf /opt/kafka-connect-jdbc.tar.gz \
           -C /opt/landoop/connectors/third-party/ \
    && rm -rf /opt/kafka-connect-jdbc.tar.gz

## Kafka Connect ELASTICSEARCH
ARG KAFKA_CONNECT_ELASTICSEARCH_VERSION=14.0.2-lkd-r0
ARG KAFKA_CONNECT_ELASTICSEARCH_URL="${ARCHIVE_SERVER}/lkd/packages/connectors/third-party/kafka-connect-elasticsearch/kafka-connect-elasticsearch-${KAFKA_CONNECT_ELASTICSEARCH_VERSION}.tar.gz"
RUN wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_CONNECT_ELASTICSEARCH_URL" \
         -O /opt/kafka-connect-elasticsearch.tar.gz \
    && mkdir -p /opt/landoop/connectors/third-party/ \
    && tar --no-same-owner -xf /opt/kafka-connect-elasticsearch.tar.gz \
           -C /opt/landoop/connectors/third-party/ \
    && rm -rf /opt/kafka-connect-elasticsearch.tar.gz

## Kafka Connect HDFS
ARG KAFKA_CONNECT_HDFS_VERSION=10.1.14-lkd-r0
ARG KAFKA_CONNECT_HDFS_URL="${ARCHIVE_SERVER}/lkd/packages/connectors/third-party/kafka-connect-hdfs/kafka-connect-hdfs-${KAFKA_CONNECT_HDFS_VERSION}.tar.gz"
RUN wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_CONNECT_HDFS_URL" \
         -O /opt/kafka-connect-hdfs.tar.gz \
    && mkdir -p /opt/landoop/connectors/third-party/ \
    && tar --no-same-owner -xf /opt/kafka-connect-hdfs.tar.gz \
           -C /opt/landoop/connectors/third-party/ \
    && rm -rf /opt/kafka-connect-hdfs.tar.gz

# Kafka Connect S3
ARG KAFKA_CONNECT_S3_VERSION=10.2.3-lkd-r0
ARG KAFKA_CONNECT_S3_URL="${ARCHIVE_SERVER}/lkd/packages/connectors/third-party/kafka-connect-s3/kafka-connect-s3-${KAFKA_CONNECT_S3_VERSION}.tar.gz"
RUN wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_CONNECT_S3_URL" \
         -O /opt/kafka-connect-s3.tar.gz \
    && mkdir -p /opt/landoop/connectors/third-party/ \
    && tar --no-same-owner -xf /opt/kafka-connect-s3.tar.gz \
           -C /opt/landoop/connectors/third-party/ \
    && rm -rf /opt/kafka-connect-s3.tar.gz

# Kafka Connect Couchbase
ARG KAFKA_CONNECT_COUCHBASE_VERSION=4.1.9
ARG KAFKA_CONNECT_COUCHBASE_URL="http://packages.couchbase.com/clients/kafka/${KAFKA_CONNECT_COUCHBASE_VERSION}/couchbase-kafka-connect-couchbase-${KAFKA_CONNECT_COUCHBASE_VERSION}.zip"
RUN wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_CONNECT_COUCHBASE_URL" \
         -O /couchbase.zip \
    && mkdir -p /couchbase /opt/landoop/connectors/third-party/kafka-connect-couchbase \
    && unzip /couchbase.zip -d /couchbase \
    && cp -ax /couchbase/couchbase-kafka-connect-couchbase-${KAFKA_CONNECT_COUCHBASE_VERSION}/* \
          /opt/landoop/connectors/third-party/kafka-connect-couchbase \
    && chown -R root:root /opt/landoop/connectors/third-party/kafka-connect-couchbase \
    && rm -rf /couchbase.zip /couchbase

# Kafka Connect Debezium MongoDB / MySQL / Postgres / MsSQL
ARG KAFKA_CONNECT_DEBEZIUM_MONGODB_VERSION=2.0.0.Final
ARG KAFKA_CONNECT_DEBEZIUM_MONGODB_URL="https://search.maven.org/remotecontent?filepath=io/debezium/debezium-connector-mongodb/${KAFKA_CONNECT_DEBEZIUM_MONGODB_VERSION}/debezium-connector-mongodb-${KAFKA_CONNECT_DEBEZIUM_MONGODB_VERSION}-plugin.tar.gz"
ARG KAFKA_CONNECT_DEBEZIUM_MYSQL_VERSION=2.0.0.Final
ARG KAFKA_CONNECT_DEBEZIUM_MYSQL_URL="https://search.maven.org/remotecontent?filepath=io/debezium/debezium-connector-mysql/${KAFKA_CONNECT_DEBEZIUM_MYSQL_VERSION}/debezium-connector-mysql-${KAFKA_CONNECT_DEBEZIUM_MYSQL_VERSION}-plugin.tar.gz"
ARG KAFKA_CONNECT_DEBEZIUM_POSTGRES_VERSION=2.0.0.Final
ARG KAFKA_CONNECT_DEBEZIUM_POSTGRES_URL="https://search.maven.org/remotecontent?filepath=io/debezium/debezium-connector-postgres/${KAFKA_CONNECT_DEBEZIUM_POSTGRES_VERSION}/debezium-connector-postgres-${KAFKA_CONNECT_DEBEZIUM_POSTGRES_VERSION}-plugin.tar.gz"
ARG KAFKA_CONNECT_DEBEZIUM_SQLSERVER_VERSION=2.0.0.Final
ARG KAFKA_CONNECT_DEBEZIUM_SQLSERVER_URL="https://search.maven.org/remotecontent?filepath=io/debezium/debezium-connector-sqlserver/${KAFKA_CONNECT_DEBEZIUM_SQLSERVER_VERSION}/debezium-connector-sqlserver-${KAFKA_CONNECT_DEBEZIUM_SQLSERVER_VERSION}-plugin.tar.gz"
RUN mkdir -p /opt/landoop/connectors/third-party/kafka-connect-debezium-{mongodb,mysql,postgres,sqlserver} \
    && wget "$KAFKA_CONNECT_DEBEZIUM_MONGODB_URL" -O /debezium-mongodb.tgz \
    && file /debezium-mongodb.tgz \
    && tar -xf /debezium-mongodb.tgz \
           --owner=root --group=root --strip-components=1 \
           -C  /opt/landoop/connectors/third-party/kafka-connect-debezium-mongodb \
    && wget "$KAFKA_CONNECT_DEBEZIUM_MYSQL_URL" -O /debezium-mysql.tgz \
    && file /debezium-mysql.tgz \
    && tar -xf /debezium-mysql.tgz \
           --owner=root --group=root --strip-components=1 \
           -C  /opt/landoop/connectors/third-party/kafka-connect-debezium-mysql \
    && wget "$KAFKA_CONNECT_DEBEZIUM_POSTGRES_URL" -O /debezium-postgres.tgz \
    && file /debezium-postgres.tgz \
    && tar -xf /debezium-postgres.tgz \
           --owner=root --group=root --strip-components=1 \
           -C  /opt/landoop/connectors/third-party/kafka-connect-debezium-postgres \
    && wget "$KAFKA_CONNECT_DEBEZIUM_SQLSERVER_URL" -O /debezium-sqlserver.tgz \
    && tar -xf /debezium-sqlserver.tgz \
           --owner=root --group=root --strip-components=1 \
           -C  /opt/landoop/connectors/third-party/kafka-connect-debezium-sqlserver \
    && rm -rf /debezium-{mongodb,mysql,postgres,sqlserver}.tgz

# Kafka Connect Splunk
ARG KAFKA_CONNECT_SPLUNK_VERSION="2.0.4"
ARG KAFKA_CONNECT_SPLUNK_URL="https://github.com/splunk/kafka-connect-splunk/releases/download/v${KAFKA_CONNECT_SPLUNK_VERSION}/splunk-kafka-connect-v${KAFKA_CONNECT_SPLUNK_VERSION}.jar"
RUN mkdir -p /opt/landoop/connectors/third-party/kafka-connect-splunk \
    && wget "$KAFKA_CONNECT_SPLUNK_URL" \
       -O /opt/landoop/connectors/third-party/kafka-connect-splunk/splunk-kafka-connect-v${KAFKA_CONNECT_SPLUNK_VERSION}.jar

###################
# Add ElasticSearch
###################
# Disable until CVE-2021-44228 is addressed
# ARG ELASTICSEARCH_VERSION="6.8.7"
# ARG ELASTICSEARCH_URL="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-oss-${ELASTICSEARCH_VERSION}.tar.gz"
# #ARG ELASTICSEARCH_URL="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-oss-${ELASTICSEARCH_VERSION}-no-jdk-linux-x86_64.tar.gz" # For 7.x ES
# RUN wget "${ELASTICSEARCH_URL}" -O /elasticsearch.tar.gz \
#     && mkdir -p /opt/elasticsearch \
#     && tar -xzf /elasticsearch.tar.gz \
#            --owner=root --group=root --strip-components=1 \
#            -C  /opt/elasticsearch \
#     && rm -f /elasticsearch.tar.gz \
#     && chmod o+r /opt/elasticsearch/config/*

############
# Add tools/
############

# Add Coyote
ARG COYOTE_VERSION=1.5
ARG COYOTE_URL="https://github.com/Landoop/coyote/releases/download/v${COYOTE_VERSION}/coyote-${COYOTE_VERSION}-${TARGETOS}-${TARGETARCH}"
RUN mkdir -p /opt/landoop/tools/bin /opt/landoop/tools/share/coyote/examples \
    && wget "$COYOTE_URL" -O /opt/landoop/tools/bin/coyote \
    && chmod +x /opt/landoop/tools/bin/coyote
ADD lkd/simple-integration-tests.yml /opt/landoop/tools/share/coyote/examples/

# Add Kafka Topic UI, Schema Registry UI, Kafka Connect UI
ARG KAFKA_TOPICS_UI_VERSION=0.9.4
ARG KAFKA_TOPICS_UI_URL="https://github.com/lensesio/kafka-topics-ui/releases/download/v${KAFKA_TOPICS_UI_VERSION}/kafka-topics-ui-${KAFKA_TOPICS_UI_VERSION}.tar.gz"
ARG SCHEMA_REGISTRY_UI_VERSION=0.9.5
ARG SCHEMA_REGISTRY_UI_URL="https://github.com/lensesio/schema-registry-ui/releases/download/v.${SCHEMA_REGISTRY_UI_VERSION}/schema-registry-ui-${SCHEMA_REGISTRY_UI_VERSION}.tar.gz"
ARG KAFKA_CONNECT_UI_VERSION=0.9.7
ARG KAFKA_CONNECT_UI_URL="https://github.com/lensesio/kafka-connect-ui/releases/download/v.${KAFKA_CONNECT_UI_VERSION}/kafka-connect-ui-${KAFKA_CONNECT_UI_VERSION}.tar.gz"
RUN mkdir -p /opt/landoop/tools/share/kafka-topics-ui/ \
             /opt/landoop/tools/share/schema-registry-ui/ \
             /opt/landoop/tools/share/kafka-connect-ui/ \
    && wget "$KAFKA_TOPICS_UI_URL" -O /kafka-topics-ui.tar.gz \
    && tar xvf /kafka-topics-ui.tar.gz -C /opt/landoop/tools/share/kafka-topics-ui \
    && mv /opt/landoop/tools/share/kafka-topics-ui/env.js /opt/landoop/tools/share/kafka-topics-ui/env.js.sample \
    && wget "$SCHEMA_REGISTRY_UI_URL" -O /schema-registry-ui.tar.gz \
    && tar xvf /schema-registry-ui.tar.gz -C /opt/landoop/tools/share/schema-registry-ui \
    && mv /opt/landoop/tools/share/schema-registry-ui/env.js /opt/landoop/tools/share/schema-registry-ui/env.js.sample \
    && wget "$KAFKA_CONNECT_UI_URL" -O /kafka-connect-ui.tar.gz \
    && tar xvf /kafka-connect-ui.tar.gz -C /opt/landoop/tools/share/kafka-connect-ui \
    && mv /opt/landoop/tools/share/kafka-connect-ui/env.js /opt/landoop/tools/share/kafka-connect-ui/env.js.sample \
    && rm -f /kafka-topics-ui.tar.gz /schema-registry-ui.tar.gz /kafka-connect-ui.tar.gz

# Add Kafka Autocomplete
ARG KAFKA_AUTOCOMPLETE_VERSION=0.3
ARG KAFKA_AUTOCOMPLETE_URL="https://github.com/Landoop/kafka-autocomplete/releases/download/${KAFKA_AUTOCOMPLETE_VERSION}/kafka"
RUN mkdir -p /opt/landoop/tools/share/kafka-autocomplete \
             /opt/landoop/tools/share/bash-completion/completions \
    && wget "$KAFKA_AUTOCOMPLETE_URL" \
            -O /opt/landoop/tools/share/kafka-autocomplete/kafka \
    && wget "$KAFKA_AUTOCOMPLETE_URL" \
            -O /opt/landoop/tools/share/bash-completion/completions/kafka

# Enable jline for Zookeeper
RUN TJLINE="$(find /opt/landoop/kafka -name "jline-0*.jar" | head -n1)" \
    && if [[ -n $TJLINE ]]; then sed "s|^exec.*|export CLASSPATH=\"\$CLASSPATH:$TJLINE\"\n&|" -i /opt/landoop/kafka/bin/zookeeper-shell; fi

# Add normcat
ARG NORMCAT_VERSION=1.1.1
ARG NORMCAT_URL="https://github.com/andmarios/normcat/releases/download/${NORMCAT_VERSION}/normcat-${NORMCAT_VERSION}-${TARGETOS}-${TARGETARCH}"
RUN wget "$NORMCAT_URL"-lowmem.tar.gz -O /normcat-linux.tgz \
    && tar -xf /normcat-linux.tgz -C /opt/landoop/tools/bin \
    && chmod +x /opt/landoop/tools/bin/normcat \
    && rm -f /normcat-linux.tgz

# Add connect-cli
ARG CONNECT_CLI_VERSION=1.0.9
ARG CONNECT_CLI_URL="https://github.com/lensesio/kafka-connect-tools/releases/download/v${CONNECT_CLI_VERSION}/connect-cli"
RUN wget "$CONNECT_CLI_URL" -O /opt/landoop/tools/bin/connect-cli && chmod +x /opt/landoop/tools/bin/connect-cli

##########
# Finalize
##########

RUN echo    "LKD_VERSION=${LKD_VERSION}"                               | tee -a /opt/landoop/build.info \
    && echo "KAFKA_VERSION=${KAFKA_LVERSION}"                          | tee -a /opt/landoop/build.info \
    && echo "CONNECT_VERSION=${KAFKA_LVERSION}"                        | tee -a /opt/landoop/build.info \
    && echo "SCHEMA_REGISTRY_VERSION=${REGISTRY_VERSION}"              | tee -a /opt/landoop/build.info \
    && echo "REST_PROXY_VERSION=${REST_VERSION}"                       | tee -a /opt/landoop/build.info \
    && echo "STREAM_REACTOR_VERSION=${STREAM_REACTOR_VERSION}"         | tee -a /opt/landoop/build.info \
    && echo "SECRET_PROVIDER_VERSION=${SECRET_PROVIDER_VERSION}"       | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_JDBC_VERSION=${KAFKA_CONNECT_JDBC_VERSION}" | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_ELASTICSEARCH_VERSION=${KAFKA_CONNECT_ELASTICSEARCH_VERSION}" \
                                                                       | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_HDFS_VERSION=${KAFKA_CONNECT_HDFS_VERSION}" | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_S3_VERSION=${KAFKA_CONNECT_S3_VERSION}"     | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_COUCHBASE_VERSION=${KAFKA_CONNECT_COUCHBASE_VERSION}" \
                                                                       | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_DEBEZIUM_MONGODB_VERSION=${KAFKA_CONNECT_DEBEZIUM_MONGODB_VERSION}" \
                                                                       | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_DEBEZIUM_MYSQL_VERSION=${KAFKA_CONNECT_DEBEZIUM_MYSQL_VERSION}" \
                                                                       | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_DEBEZIUM_SQLSERVER_VERSION=${KAFKA_CONNECT_DEBEZIUM_SQLSERVER_VERSION}" \
                                                                       | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_DEBEZIUM_POSTGRES_VERSION=${KAFKA_CONNECT_DEBEZIUM_POSTGRES_VERSION}" \
                                                                       | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_SPLUNK_VERSION=${KAFKA_CONNECT_SPLUNK_VERSION}" \
                                                                       | tee -a /opt/landoop/build.info \
    && echo "KAFKA_TOPICS_UI_VERSION=${KAFKA_TOPICS_UI_VERSION}"       | tee -a /opt/landoop/build.info \
    && echo "SCHEMA_REGISTRY_UI_VERSION=${SCHEMA_REGISTRY_UI_VERSION}" | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_UI_VERSION=${KAFKA_CONNECT_UI_VERSION}"     | tee -a /opt/landoop/build.info \
    && echo "COYOTE_VERSION=${COYOTE_VERSION}"                         | tee -a /opt/landoop/build.info \
    && echo "KAFKA_AUTOCOMPLETE_VERSION=${KAFKA_AUTOCOMPLETE_VERSION}" | tee -a /opt/landoop/build.info \
    && echo "NORMCAT_VERSION=${NORMCAT_VERSION}"                       | tee -a /opt/landoop/build.info \
    && echo "CONNECT_CLI_VERSION=${CONNECT_CLI_VERSION}"               | tee -a /opt/landoop/build.info
#    && echo "ELASTICSEARCH_VERSION=${ELASTICSEARCH_VERSION}"           | tee -a /opt/elasticsearch/build.info # Disable until CVE-2021-44228 is addressed

# duphard (replace duplicates with hard links) and create archive
# We run as two separate commands because otherwise the build fails in docker hub (but not locally)
RUN duphard -d=0 /opt/landoop
RUN tar -czf /LKD-${LKD_VERSION}.tar.gz \
           --owner=root \
           --group=root \
           -C /opt \
           landoop \
    && rm -rf /opt/landoop
# Unfortunately we have to make this a separate step in order for docker to understand the change to hardlinks
# Good thing: final image that people download is much smaller (~200MB).
RUN tar xf /LKD-${LKD_VERSION}.tar.gz -C /opt \
    && rm /LKD-${LKD_VERSION}.tar.gz

ENV LKD_VERSION=${LKD_VERSION}
# If this stage is run as container and you mount `/mnt`, we will create the LKD archive there.
CMD ["bash", "-c", "tar -czf /mnt/LKD-${LKD_VERSION}.tar.gz -C /opt landoop; chown --reference=/mnt /mnt/LKD-${LKD_VERSION}.tar.gz"]

#= Docker Images that bring in Lenses, either from a remote or using files on disk =#

# This is the default image we use for installing Lenses
FROM alpine as lenses_archive_remote
ONBUILD ARG AD_UN
ONBUILD ARG AD_PW
ONBUILD ARG AD_URL
ONBUILD RUN apk add --no-cache wget \
        && echo "progress = dot:giga" | tee /etc/wgetrc \
        && mkdir -p /opt  \
        && echo "$AD_URL $AD_FILENAME" \
        && if [ -z "$AD_URL" ]; then exit 0; fi && wget $AD_UN $AD_PW "$AD_URL" -O /lenses.tgz \
        && tar xf /lenses.tgz -C /opt \
        && rm /lenses.tgz

# This image gets Lenses from a local file instead of a remote URL
FROM alpine as lenses_archive_local
ONBUILD ARG AD_FILENAME
ONBUILD RUN mkdir -p /opt
ONBUILD ADD $AD_FILENAME /opt

# This image gets Lenses and a custom Lenses frontend from a local file
FROM alpine as lenses_archive_local_with_ui
ONBUILD ARG AD_FILENAME
ONBUILD RUN mkdir -p /opt
ONBUILD ADD $AD_FILENAME /opt
ONBUILD ARG UI_FILENAME
ONBUILD ADD $UI_FILENAME /opt
ONBUILD RUN rm -rf /opt/lenses/ui \
            && mv /opt/dist /opt/lenses/ui \
            && sed \
                 -e "s/export LENSESUI_REVISION=.*/export LENSESUI_REVISION=$(cat /opt/lenses/ui/build.info | cut -f 2 -d ' ')/" \
                 -i /opt/lenses/bin/lenses

# This image is here to just trigger the build of any of the above 3 images
FROM lenses_archive_${LENSES_ARCHIVE} as lenses_archive


#= Docker Images that bring in lenses-cli, either from a remote or using files on disk =#

# This is the default image we use for installing Lenses
FROM alpine as lenses_cli_remote
ARG TARGETARCH TARGETOS
ONBUILD ARG CAD_UN
ONBUILD ARG CAD_PW
ONBUILD ARG LC_VERSION
ONBUILD ARG LC_URL
ONBUILD RUN wget $CAD_UN $CAD_PW "$LC_URL" -O /lenses-cli.tgz \
          && tar xzf /lenses-cli.tgz --strip-components=1 -C /usr/local/bin/ lenses-cli-$TARGETOS-$TARGETARCH-$LC_VERSION/lenses-cli \
          && rm -f /lenses-cli.tgz

# This image gets Lenses from a local file instead of a remote URL
FROM alpine as lenses_cli_local
ONBUILD ARG LC_FILENAME
ONBUILD RUN mkdir -p /lenses-cli
ONBUILD COPY $LC_FILENAME /lenses-cli.tgz
ONBUILD RUN mkdir  -p /usr/local/bin && \
            tar xzf /lenses-cli.tgz --strip-components=1 -C /usr/local/bin

# This image is here to just trigger the build of any of the above 3 images
ARG LENSESCLI_ARCHIVE
FROM lenses_cli_${LENSESCLI_ARCHIVE} as lenses_cli

#= Final Docker Image =#

FROM debian:bullseye-slim
MAINTAINER Marios Andreopoulos <marios@lenses.io>

COPY --from=compile-lkd /opt /opt
ARG TARGETOS TARGETARCH

# Update, install tooling and some basic setup
RUN apt-get update \
    && apt-get install -y \
        bash-completion \
        bzip2 \
        coreutils \
        curl \
        default-jre-headless \
        dumb-init \
        gettext \
        gzip \
        jq \
        locales \
        netcat \
        openssl \
        sqlite3 \
        supervisor \
        wget \
    && rm -rf /var/lib/apt/lists/* \
    && echo "progress = dot:giga" | tee /etc/wgetrc \
    && mkdir -p /opt \
    && mkdir /extra-connect-jars /connectors \
    && mkdir /etc/supervisord.d /etc/supervisord.templates.d \
    && rm -rf /var/log/*

SHELL ["/bin/bash", "-c"]
WORKDIR /

# Install external tooling
# checkport: checks for ports that are already in use, useful when we run with
#            '--net=host so we have an easy way to detect if our ports are free
# quickcert: a small tool we use to create a CA and key-cert pairs so we can easily
#            setup SSL on the brokers with autogenerated keys and certs
# glibc    : alpine linux has an embedded libc which misses some functions that are
#            needed by some apps (e.g jvm's rocksdb jni — HDFS connector, Lenses, etc),
#            so we add glibc to make them work. Also now we can add en_US.UTF-8 locale.
#            https://github.com/sgerrand/alpine-pkg-glibc
# caddy    : an excellent web server we use to serve fast-data-dev UI, proxy various REST
#            endpoints, etc
#            https://github.com/mholt/caddy
# gotty    : a small tool that allows us to run a shell in a web browser
ARG CHECKPORT_URL="https://github.com/andmarios/checkport/releases/download/0.1/checkport-${TARGETOS}-${TARGETARCH}"
ARG QUICKCERT_URL="https://github.com/andmarios/quickcert/releases/download/1.1/quickcert-1.1-${TARGETOS}-${TARGETARCH}"
ARG CADDY_URL=https://github.com/caddyserver/caddy/releases/download/v0.11.5/caddy_v0.11.5_${TARGETOS}_${TARGETARCH}.tar.gz
ARG GOTTY_URL_AMD64=https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_amd64.tar.gz
ARG GOTTY_URL_ARM64=https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_arm.tar.gz
RUN wget "$CHECKPORT_URL" -O /usr/local/bin/checkport \
    && wget "$QUICKCERT_URL" -O /usr/local/bin/quickcert \
    && chmod 0755 /usr/local/bin/quickcert /usr/local/bin/checkport \
    && wget "$CADDY_URL" -O /caddy.tgz \
    && mkdir -p /opt/caddy \
    && tar xzf /caddy.tgz -C /opt/caddy \
    && rm -f /caddy.tgz \
    && if [[ $TARGETARCH == amd64 ]]; then GOTTY_URL=$GOTTY_URL_AMD64; elif [[ $TARGETARCH == arm64 ]]; then GOTTY_URL=$GOTTY_URL_ARM64; fi \
    && wget "$GOTTY_URL" -O /gotty.tar.gz \
    && mkdir -p /opt/gotty \
    && tar xzf gotty.tar.gz -C /opt/gotty \
    && rm -f gotty.tar.gz \
    && localedef -i en_US -f UTF-8 en_US.UTF-8
ENV LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8


# PLACEHOLDER: This line can be used to inject code if needed, please do not remove #

# Add Lenses
COPY --from=lenses_archive /opt/lenses /opt/lenses

# Add Lenses CLI
ARG LC_VERSION
COPY --from=lenses_cli /usr/local/bin/lenses-cli /usr/local/bin/lenses-cli

# Add cc_payments generator
RUN wget https://archive.lenses.io/tools/cc_payments_demo_generator/generator-1.0.tgz -O /generator.tgz \
    && mkdir -p /opt/generator \
    && tar xf /generator.tgz --no-same-owner --strip-components=1 -C /opt/generator \
    && sed -e 's/localhost/0.0.0.0/' -i /opt/generator/lenses.conf \
    && rm -f /generator.tgz

COPY /filesystem /
RUN chmod +x /usr/local/bin/{smoke-tests,logs-to-kafka,nullsink,elastic-ships}.sh \
             /usr/local/share/landoop/sample-data/*.sh

# Create system symlinks to Kafka binaries
RUN bash -c 'for i in $(find /opt/landoop/{kafka,tools}/bin /opt/elasticsearch/bin -maxdepth 1 -type f); do ln -s $i /usr/local/bin/$(echo $i | sed -e "s>.*/>>"); done'

# Add kafka ssl principal builder
RUN wget https://archive.lenses.io/third-party/kafka-custom-principal-builder/kafka-custom-principal-builder-1.0-SNAPSHOT.jar \
         -P /opt/landoop/kafka/share/java/kafka \
    && mkdir -p /opt/landoop/kafka/share/docs/kafka-custom-principal-builder \
    && wget https://archive.lenses.io/third-party/kafka-custom-principal-builder/LICENSE \
         -P /opt/landoop/kafka/share/docs/kafka-custom-principal-builder \
    && wget https://archive.lenses.io/third-party/kafka-custom-principal-builder/README.md \
         -P /opt/landoop/kafka/share/docs/kafka-custom-principal-builder

# Setup Kafka Topics UI, Schema Registry UI, Kafka Connect UI
RUN mkdir -p \
      /var/www/kafka-topics-ui \
      /var/www/schema-registry-ui \
      /var/www/kafka-connect-ui \
    && cp -ax /opt/landoop/tools/share/kafka-topics-ui/* /var/www/kafka-topics-ui/ \
    && cp -ax /opt/landoop/tools/share/schema-registry-ui/* /var/www/schema-registry-ui/ \
    && cp -ax /opt/landoop/tools/share/kafka-connect-ui/* /var/www/kafka-connect-ui/

RUN ln -s /var/log /var/www/logs

# Add executables, settings and configuration
ADD setup-and-run.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup-and-run.sh \
    && rm -f /root/.bashrc \
    && ln -s /usr/local/share/landoop/etc/bashrc /root/.bashrc

VOLUME ["/data"]

ARG BUILD_BRANCH
ARG BUILD_COMMIT
ARG BUILD_TIME
ARG DOCKER_REPO=local
RUN echo "BUILD_BRANCH=${BUILD_BRANCH}"    | tee /build.info \
    && echo "BUILD_COMMIT=${BUILD_COMMIT}" | tee -a /build.info \
    && echo "BUILD_TIME=${BUILD_TIME}"     | tee -a /build.info \
    && echo "DOCKER_REPO=${DOCKER_REPO}"   | tee -a /build.info \
    && echo "TARGETPLATFORM=${TARGETOS}/${TARGETARCH}" | tee -a /build.info \
    && grep 'export LENSES_REVISION'   /opt/lenses/bin/lenses | sed -e 's/export /FDD_/' -e 's/"//g' | tee -a /build.info \
    && grep 'export LENSESUI_REVISION' /opt/lenses/bin/lenses | sed -e 's/export /FDD_/' -e 's/"//g' | tee -a /build.info \
    && grep 'export LENSES_VERSION'    /opt/lenses/bin/lenses | sed -e 's/export /FDD_/' -e 's/"//g' | tee -a /build.info \
    && echo "FDD_LENSES_CLI_VERSION=${LC_VERSION}" | tee -a /build.info \
    && sed -e 's/^/FDD_/' /opt/landoop/build.info  | tee -a /build.info
#    && sed -e 's/^/FDD_/' /opt/elasticsearch/build.info  | tee -a /build.info # Disable until CVE-2021-44228 is addressed

EXPOSE 2181 3030 3031 8081 8082 8083 9092
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/local/bin/setup-and-run.sh"]

FROM debian as compile-lkd
MAINTAINER Marios Andreopoulos <marios@landoop.com>

RUN apt-get update \
    && apt-get install -y \
         unzip \
         wget \
    && rm -rf /var/lib/apt/lists/* \
    && echo "progress = dot:giga" | tee /etc/wgetrc \
    && mkdir -p /mnt /opt /data \
    && wget https://github.com/andmarios/duphard/releases/download/v1.0/duphard -O /bin/duphard \
    && chmod +x /bin/duphard

SHELL ["/bin/bash", "-c"]
WORKDIR /

# Login args for development archives
ARG DEVARCH_USER
ARG DEVARCH_PASS
ARG LKD_VERSION=1.0.1

############
# Add kafka/
############

# Add Apache Kafka (includes Connect and Zookeeper)
ARG KAFKA_VERSION=1.0.1
ARG KAFKA_LVERSION="${KAFKA_VERSION}-L0"
ARG KAFKA_URL="https://archive.landoop.com/lkd/packages/kafka/kafka-2.11-${KAFKA_LVERSION}-lkd.tar.gz"

RUN wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_URL" -O /opt/kafka.tar.gz \
    && tar --no-same-owner -xzf /opt/kafka.tar.gz -C /opt \
    && mkdir /opt/landoop/kafka/logs && chmod 1777 /opt/landoop/kafka/logs \
    && rm -rf /opt/kafka.tar.gz

# Add Schema Registry and REST Proxy
ARG REGISTRY_VERSION=4.0.1-lkd-r0
ARG REGISTRY_URL="https://archive.landoop.com/lkd/packages/schema-registry/schema-registry-${REGISTRY_VERSION}.tar.gz"
RUN wget $DEVARCH_USER $DEVARCH_PASS "$REGISTRY_URL" -O /opt/registry.tar.gz \
    && tar --no-same-owner -xzf /opt/registry.tar.gz -C /opt/ \
    && rm -rf /opt/registry.tar.gz

ARG REST_VERSION=4.0.1-lkd-r0
ARG REST_URL="https://archive.landoop.com/lkd/packages/rest-proxy/rest-proxy-${REST_VERSION}.tar.gz"
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
ARG STREAM_REACTOR_VERSION=1.0.0
ARG KAFKA_VERSION_4SR=1.0.0
ARG STREAM_REACTOR_URL="https://archive.landoop.com/lkd/packages/connectors/stream-reactor/stream-reactor-${STREAM_REACTOR_VERSION}_connect${KAFKA_VERSION_4SR}.tar.gz"
ARG ELASTICSEARCH_2X_VERSION=2.4.6
ARG ACTIVEMQ_VERSION=5.12.3
ARG CALCITE_LINQ4J_VERSION=1.12.0

RUN wget "${STREAM_REACTOR_URL}" -O /stream-reactor.tar.gz \
    && mkdir -p /opt/landoop/connectors/stream-reactor \
    && tar -xf /stream-reactor.tar.gz \
           --no-same-owner \
           --strip-components=1 \
           -C /opt/landoop/connectors/stream-reactor \
    && rm /stream-reactor.tar.gz \
    && wget https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/${ELASTICSEARCH_2X_VERSION}/elasticsearch-${ELASTICSEARCH_2X_VERSION}.tar.gz \
            -O /elasticsearch.tar.gz \
    && mkdir /elasticsearch \
    && tar -xf /elasticsearch.tar.gz \
           --no-same-owner \
           --strip-components=1 \
           -C /elasticsearch \
    && mv /elasticsearch/lib/*.jar /opt/landoop/connectors/stream-reactor/kafka-connect-elastic/ \
    && rm -rf /elasticsearch* \
    && wget http://central.maven.org/maven2/org/apache/activemq/activemq-all/${ACTIVEMQ_VERSION}/activemq-all-${ACTIVEMQ_VERSION}.jar \
            -P /opt/landoop/connectors/stream-reactor/kafka-connect-jms \
    && wget http://central.maven.org/maven2/org/apache/calcite/calcite-linq4j/${CALCITE_LINQ4J_VERSION}/calcite-linq4j-${CALCITE_LINQ4J_VERSION}.jar \
            -O /calcite-linq4j-${CALCITE_LINQ4J_VERSION}.jar \
    && for path in /opt/landoop/connectors/stream-reactor/kafka-connect-*; do \
          cp /calcite-linq4j-${CALCITE_LINQ4J_VERSION}.jar $path/; \
       done \
    && rm /calcite-linq4j-${CALCITE_LINQ4J_VERSION}.jar \
    && mkdir -p /opt/landoop/kafka/share/java/landoop-common \
    && for file in $(find /opt/landoop/connectors/stream-reactor -maxdepth 2 -type f -exec basename {} \; | sort | uniq -c | grep -E "^\s+20 " | awk '{print $2}' ); do \
         cp /opt/landoop/connectors/stream-reactor/kafka-connect-elastic/$file /opt/landoop/kafka/share/java/landoop-common/; \
         rm -f /opt/landoop/connectors/stream-reactor/kafka-connect-*/$file; \
       done \
    && for file in $(find /opt/landoop/kafka/share/java/{kafka,landoop-common} -maxdepth 1 -type f -exec basename {} \; | sort | uniq -c | grep -E "^\s+2 " | awk '{print $2}' ); do \
         echo "Removing duplicate /opt/landoop/kafka/share/java/landoop-common/$file."; \
         rm -f /opt/landoop/kafka/share/java/landoop-common/$file; \
       done \
    && rm -f /opt/landoop/connectors/stream-reactor/*/*{javadoc,scaladoc,sources}.jar \
    && echo "plugin.path=/opt/landoop/connectors/stream-reactor,/opt/landoop/connectors/third-party" \
            >> /opt/landoop/kafka/etc/schema-registry/connect-avro-distributed.properties

# Add Third Party Connectors

## Twitter
ARG TWITTER_CONNECTOR_URL="https://archive.landoop.com/third-party/kafka-connect-twitter/kafka-connect-twitter-0.1-master-33331ea-connect-1.0.0-jar-with-dependencies.jar"
RUN mkdir -p /opt/landoop/connectors/third-party/kafka-connect-twitter \
    && wget "$TWITTER_CONNECTOR_URL" -P /opt/landoop/connectors/third-party/kafka-connect-twitter

## Kafka Connect JDBC
ARG KAFKA_CONNECT_JDBC_VERSION=4.0.1-lkd-r0
ARG KAFKA_CONNECT_JDBC_URL="https://archive.landoop.com/lkd/packages/connectors/third-party/kafka-connect-jdbc/kafka-connect-jdbc-${KAFKA_CONNECT_JDBC_VERSION}.tar.gz"
RUN wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_CONNECT_JDBC_URL" \
         -O /opt/kafka-connect-jdbc.tar.gz \
    && mkdir -p /opt/landoop/connectors/third-party/ \
    && tar --no-same-owner -xf /opt/kafka-connect-jdbc.tar.gz \
           -C /opt/landoop/connectors/third-party/ \
    && rm -rf /opt/kafka-connect-jdbc.tar.gz

## Kafka Connect ELASTICSEARCH
ARG KAFKA_CONNECT_ELASTICSEARCH_VERSION=4.0.1-lkd-r0
ARG KAFKA_CONNECT_ELASTICSEARCH_URL="https://archive.landoop.com/lkd/packages/connectors/third-party/kafka-connect-elasticsearch/kafka-connect-elasticsearch-${KAFKA_CONNECT_ELASTICSEARCH_VERSION}.tar.gz"
RUN wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_CONNECT_ELASTICSEARCH_URL" \
         -O /opt/kafka-connect-elasticsearch.tar.gz \
    && mkdir -p /opt/landoop/connectors/third-party/ \
    && tar --no-same-owner -xf /opt/kafka-connect-elasticsearch.tar.gz \
           -C /opt/landoop/connectors/third-party/ \
    && rm -rf /opt/kafka-connect-elasticsearch.tar.gz

## Kafka Connect HDFS
ARG KAFKA_CONNECT_HDFS_VERSION=4.0.1-lkd-r0
ARG KAFKA_CONNECT_HDFS_URL="https://archive.landoop.com/lkd/packages/connectors/third-party/kafka-connect-hdfs/kafka-connect-hdfs-${KAFKA_CONNECT_HDFS_VERSION}.tar.gz"
RUN wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_CONNECT_HDFS_URL" \
         -O /opt/kafka-connect-hdfs.tar.gz \
    && mkdir -p /opt/landoop/connectors/third-party/ \
    && tar --no-same-owner -xf /opt/kafka-connect-hdfs.tar.gz \
           -C /opt/landoop/connectors/third-party/ \
    && rm -rf /opt/kafka-connect-hdfs.tar.gz

# Kafka Connect S3
ARG KAFKA_CONNECT_S3_VERSION=4.0.1-lkd-r0
ARG KAFKA_CONNECT_S3_URL="https://archive.landoop.com/lkd/packages/connectors/third-party/kafka-connect-s3/kafka-connect-s3-${KAFKA_CONNECT_S3_VERSION}.tar.gz"
RUN wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_CONNECT_S3_URL" \
         -O /opt/kafka-connect-s3.tar.gz \
    && mkdir -p /opt/landoop/connectors/third-party/ \
    && tar --no-same-owner -xf /opt/kafka-connect-s3.tar.gz \
           -C /opt/landoop/connectors/third-party/ \
    && rm -rf /opt/kafka-connect-s3.tar.gz

# Kafka Connect Couchbase
ARG KAFKA_CONNECT_COUCHBASE_VERSION=3.2.2
ARG KAFKA_CONNECT_COUCHBASE_URL="http://packages.couchbase.com/clients/kafka/${KAFKA_CONNECT_COUCHBASE_VERSION}/kafka-connect-couchbase-${KAFKA_CONNECT_COUCHBASE_VERSION}.zip"
RUN wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_CONNECT_COUCHBASE_URL" \
         -O /couchbase.zip \
    && mkdir -p /couchbase /opt/landoop/connectors/third-party/kafka-connect-couchbase \
    && unzip /couchbase.zip -d /couchbase \
    && cp -ax /couchbase/kafka-connect-couchbase-${KAFKA_CONNECT_COUCHBASE_VERSION}/* \
          /opt/landoop/connectors/third-party/kafka-connect-couchbase \
    && chown -R root:root /opt/landoop/connectors/third-party/kafka-connect-couchbase \
    && rm -rf /couchbase.zip /couchbase

# Kafka Connect Dbvisit Replicate
ARG KAFKA_CONNECT_DBVISITREPLICATE_VERSION=2.0.0-SNAPSHOT
ARG KAFKA_CONNECT_DBVISITREPLICATE_URL="https://www.dropbox.com/s/nhs8v3lwmigpks1/kafka-connect-dbvisitreplicate-${KAFKA_CONNECT_DBVISITREPLICATE_VERSION}.jar?dl=0"
RUN mkdir -p /opt/landoop/connectors/third-party/kafka-connect-dbvisitreplicate \
    && wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_CONNECT_DBVISITREPLICATE_URL" \
            -O /opt/landoop/connectors/third-party/kafka-connect-dbvisitreplicate/kafka-connect-dbvisitreplicate-${KAFKA_CONNECT_DBVISITREPLICATE_VERSION}.jar

# Kafka Connect Debezium MongoDB / MySQL / Postgres
ARG KAFKA_CONNECT_DEBEZIUM_MONGODB_VERSION=0.7.2
ARG KAFKA_CONNECT_DEBEZIUM_MONGODB_URL="https://search.maven.org/remotecontent?filepath=io/debezium/debezium-connector-mongodb/${KAFKA_CONNECT_DEBEZIUM_MONGODB_VERSION}/debezium-connector-mongodb-${KAFKA_CONNECT_DEBEZIUM_MONGODB_VERSION}-plugin.tar.gz"
ARG KAFKA_CONNECT_DEBEZIUM_MYSQL_VERSION=0.7.2
ARG KAFKA_CONNECT_DEBEZIUM_MYSQL_URL="https://search.maven.org/remotecontent?filepath=io/debezium/debezium-connector-mysql/${KAFKA_CONNECT_DEBEZIUM_MYSQL_VERSION}/debezium-connector-mysql-${KAFKA_CONNECT_DEBEZIUM_MYSQL_VERSION}-plugin.tar.gz"
ARG KAFKA_CONNECT_DEBEZIUM_POSTGRES_VERSION=0.7.2
ARG KAFKA_CONNECT_DEBEZIUM_POSTGRES_URL="https://search.maven.org/remotecontent?filepath=io/debezium/debezium-connector-postgres/${KAFKA_CONNECT_DEBEZIUM_POSTGRES_VERSION}/debezium-connector-postgres-${KAFKA_CONNECT_DEBEZIUM_POSTGRES_VERSION}-plugin.tar.gz"
RUN mkdir -p /opt/landoop/connectors/third-party/kafka-connect-debezium-{mongodb,mysql,postgres} \
    && wget "$KAFKA_CONNECT_DEBEZIUM_MONGODB_URL" -O /debezium-mongodb.tgz \
    && tar -xf /debezium-mongodb.tgz \
           --owner=root --group=root --strip-components=1 \
           -C  /opt/landoop/connectors/third-party/kafka-connect-debezium-mongodb \
    && wget "$KAFKA_CONNECT_DEBEZIUM_MYSQL_URL" -O /debezium-mysql.tgz \
    && tar -xf /debezium-mysql.tgz \
           --owner=root --group=root --strip-components=1 \
           -C  /opt/landoop/connectors/third-party/kafka-connect-debezium-mysql \
    && wget "$KAFKA_CONNECT_DEBEZIUM_POSTGRES_URL" -O /debezium-postgres.tgz \
    && tar -xf /debezium-postgres.tgz \
           --owner=root --group=root --strip-components=1 \
           -C  /opt/landoop/connectors/third-party/kafka-connect-debezium-postgres \
    && rm -rf /debezium-{mongodb,mysql,postgres}.tgz

############
# Add tools/
############

# Add Coyote
ARG COYOTE_VERSION=1.4
ARG COYOTE_URL="https://github.com/Landoop/coyote/releases/download/v${COYOTE_VERSION}/coyote-${COYOTE_VERSION}"
RUN mkdir -p /opt/landoop/tools/bin/win \
             /opt/landoop/tools/bin/mac \
             /opt/landoop/tools/share/coyote/examples \
    && wget "$COYOTE_URL"-linux-amd64 -O /opt/landoop/tools/bin/coyote \
    && wget "$COYOTE_URL"-darwin-amd64 -O /opt/landoop/tools/bin/mac/coyote \
    && wget "$COYOTE_URL"-windows-amd64.exe -O /opt/landoop/tools/bin/win/coyote \
    && chmod +x /opt/landoop/tools/bin/coyote \
                /opt/landoop/tools/bin/mac/coyote
ADD lkd/simple-integration-tests.yml /opt/landoop/tools/share/coyote/examples/

# Add Kafka Topic UI, Schema Registry UI, Kafka Connect UI
ARG KAFKA_TOPICS_UI_VERSION=0.9.3
ARG KAFKA_TOPICS_UI_URL="https://github.com/Landoop/kafka-topics-ui/releases/download/v${KAFKA_TOPICS_UI_VERSION}/kafka-topics-ui-${KAFKA_TOPICS_UI_VERSION}.tar.gz"
ARG SCHEMA_REGISTRY_UI_VERSION=0.9.4
ARG SCHEMA_REGISTRY_UI_URL="https://github.com/Landoop/schema-registry-ui/releases/download/v.${SCHEMA_REGISTRY_UI_VERSION}/schema-registry-ui-${SCHEMA_REGISTRY_UI_VERSION}.tar.gz"
ARG KAFKA_CONNECT_UI_VERSION=0.9.4
ARG KAFKA_CONNECT_UI_URL="https://github.com/Landoop/kafka-connect-ui/releases/download/v.${KAFKA_CONNECT_UI_VERSION}/kafka-connect-ui-${KAFKA_CONNECT_UI_VERSION}.tar.gz"
RUN mkdir -p /opt/landoop/tools/share/kafka-topics-ui/ \
             /opt/landoop/tools/share/schema-registry-ui/ \
             /opt/landoop/tools/share/kafka-connect-ui/ \
    && wget "$KAFKA_TOPICS_UI_URL" \
            -O /opt/landoop/tools/share/kafka-topics-ui/kafka-topics-ui.tar.gz \
    && wget "$SCHEMA_REGISTRY_UI_URL" \
            -O /opt/landoop/tools/share/schema-registry-ui/schema-registry-ui.tar.gz \
    && wget "$KAFKA_CONNECT_UI_URL" \
            -O /opt/landoop/tools/share/kafka-connect-ui/kafka-connect-ui.tar.gz

# Add Kafka Autocomplete
ARG KAFKA_AUTOCOMPLETE_VERSION=0.3
ARG KAFKA_AUTOCOMPLETE_URL="https://github.com/Landoop/kafka-autocomplete/releases/download/${KAFKA_AUTOCOMPLETE_VERSION}/kafka"
RUN mkdir -p /opt/landoop/tools/share/kafka-autocomplete \
             /opt/landoop/tools/share/bash-completion/completions \
    && wget "$KAFKA_AUTOCOMPLETE_URL" \
            -O /opt/landoop/tools/share/kafka-autocomplete/kafka \
    && wget "$KAFKA_AUTOCOMPLETE_URL" \
            -O /opt/landoop/tools/share/bash-completion/completions/kafka

# Add normcat
ARG NORMCAT_VERSION=1.1.1
ARG NORMCAT_URL="https://github.com/andmarios/normcat/releases/download/${NORMCAT_VERSION}/normcat-${NORMCAT_VERSION}"
RUN mkdir -p /opt/landoop/tools/bin/win \
             /opt/landoop/tools/bin/mac \
    && wget "$NORMCAT_URL"-linux-amd64-lowmem.tar.gz -O /normcat-linux.tgz \
    && tar -xf /normcat-linux.tgz -C /opt/landoop/tools/bin \
    && wget "$NORMCAT_URL"-darwin-amd64.zip -O /normcat-mac.zip \
    && unzip /normcat-mac.zip -d /opt/landoop/tools/bin/mac \
    && wget "$NORMCAT_URL"-windows-amd64.zip -O /normcat-win.zip \
    && unzip /normcat-win.zip -d /opt/landoop/tools/bin/win \
    && chmod +x /opt/landoop/tools/bin/coyote \
                /opt/landoop/tools/bin/mac/coyote \
    && rm -f /normcat-linux.tg /normcat-mac.zip /normcat-win.zip


##########
# Finalize
##########

RUN echo    "LKD_VERSION=${LKD_VERSION}"                               | tee -a /opt/landoop/build.info \
    && echo "KAFKA_VERSION=${KAFKA_LVERSION}"                          | tee -a /opt/landoop/build.info \
    && echo "CONNECT_VERSION=${KAFKA_LVERSION}"                        | tee -a /opt/landoop/build.info \
    && echo "SCHEMA_REGISTRY_VERSION=${REGISTRY_VERSION}"              | tee -a /opt/landoop/build.info \
    && echo "REST_PROXY_VERSION=${REST_VERSION}"                       | tee -a /opt/landoop/build.info \
    && echo "STREAM_REACTOR_VERSION=${STREAM_REACTOR_VERSION}"         | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_JDBC_VERSION=${KAFKA_CONNECT_JDBC_VERSION}" | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_ELASTICSEARCH_VERSION=${KAFKA_CONNECT_ELASTICSEARCH_VERSION}" \
                                                                       | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_HDFS_VERSION=${KAFKA_CONNECT_HDFS_VERSION}" | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_S3_VERSION=${KAFKA_CONNECT_S3_VERSION}"     | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_COUCHBASE_VERSION=${KAFKA_CONNECT_COUCHBASE_VERSION}" \
                                                                       | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_DBVISITREPLICATE_VERSION=${KAFKA_CONNECT_DBVISITREPLICATE_VERSION}" \
                                                                       | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_DEBEZIUM_MONGODB_VERSION=${KAFKA_CONNECT_DEBEZIUM_MONGODB_VERSION}" \
                                                                       | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_DEBEZIUM_MYSQL_VERSION=${KAFKA_CONNECT_DEBEZIUM_MYSQL_VERSION}" \
                                                                       | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_DEBEZIUM_POSTGRES_VERSION=${KAFKA_CONNECT_DEBEZIUM_POSTGRES_VERSION}" \
                                                                       | tee -a /opt/landoop/build.info \
    && echo "KAFKA_TOPICS_UI_VERSION=${KAFKA_TOPICS_UI_VERSION}"       | tee -a /opt/landoop/build.info \
    && echo "SCHEMA_REGISTRY_UI_VERSION=${SCHEMA_REGISTRY_UI_VERSION}" | tee -a /opt/landoop/build.info \
    && echo "KAFKA_CONNECT_UI_VERSION=${KAFKA_CONNECT_UI_VERSION}"     | tee -a /opt/landoop/build.info \
    && echo "COYOTE_VERSION=${COYOTE_VERSION}"                         | tee -a /opt/landoop/build.info \
    && echo "KAFKA_AUTOCOMPLETE_VERSION=${KAFKA_AUTOCOMPLETE_VERSION}" | tee -a /opt/landoop/build.info \
    && echo "NORMCAT_VERSION=${NORMCAT_VERSION}"                       | tee -a /opt/landoop/build.info

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

FROM alpine
MAINTAINER Marios Andreopoulos <marios@landoop.com>
COPY --from=compile-lkd /opt /opt

# Update, install tooling and some basic setup
RUN apk add --no-cache \
        bash \
        bash-completion \
        bzip2 \
        coreutils \
        curl \
        dumb-init \
        gettext \
        gzip \
        jq \
        libstdc++ \
        openjdk8-jre-base \
        openssl \
        sqlite \
        supervisor \
        tar \
        wget \
    && echo "progress = dot:giga" | tee /etc/wgetrc \
    && mkdir -p /opt \
    && mkdir /extra-connect-jars /connectors \
    && mkdir /etc/supervisord.d /etc/supervisord.templates.d

SHELL ["/bin/bash", "-c"]
WORKDIR /

# Install external tooling
# checkport: checks for ports that are already in use, useful when we run with
#            '--net=host so we have an easy way to detect if our ports are free
# quickcert: a small tool we use to create a CA and key-cert pairs so we can easily
#            setup SSL on the brokers with autogenerated keys and certs
# glibc    : alpine linux has an embedded libc which misses some functions that are
#            needed by some apps (e.g jvm's rocksdb jni — HDFS connector, Lenses, etc),
#            so we add glibc to make them work
#            https://github.com/sgerrand/alpine-pkg-glibc
# caddy    : an excellent web server we use to serve fast-data-dev UI, proxy various REST
#            endpoints, etc
#            https://github.com/mholt/caddy
ARG CHECKPORT_URL="https://gitlab.com/andmarios/checkport/uploads/3903dcaeae16cd2d6156213d22f23509/checkport"
ARG QUICKCERT_URL="https://github.com/andmarios/quickcert/releases/download/1.0/quickcert-1.0-linux-amd64-alpine"
ARG GLIBC_INST_VERSION="2.27-r0"
ARG CADDY_URL=https://github.com/mholt/caddy/releases/download/v0.10.10/caddy_v0.10.10_linux_amd64.tar.gz
RUN wget "$CHECKPORT_URL" -O /usr/local/bin/checkport \
    && wget "$QUICKCERT_URL" -O /usr/local/bin/quickcert \
    && chmod 0755 /usr/local/bin/quickcert /usr/local/bin/checkport \
    && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_INST_VERSION}/glibc-${GLIBC_INST_VERSION}.apk \
    && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_INST_VERSION}/glibc-bin-${GLIBC_INST_VERSION}.apk \
    && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_INST_VERSION}/glibc-i18n-${GLIBC_INST_VERSION}.apk \
    && apk add --no-cache --allow-untrusted glibc-${GLIBC_INST_VERSION}.apk glibc-bin-${GLIBC_INST_VERSION}.apk glibc-i18n-${GLIBC_INST_VERSION}.apk \
    && rm -f glibc-${GLIBC_INST_VERSION}.apk glibc-bin-${GLIBC_INST_VERSION}.apk glibc-i18n-${GLIBC_INST_VERSION}.apk \
    && wget "$CADDY_URL" -O /caddy.tgz \
    && mkdir -p /opt/caddy \
    && tar xzf /caddy.tgz -C /opt/caddy \
    && rm -f /caddy.tgz

# Add and setup Lenses
ARG AD_UN
ARG AD_PW
ARG AD_URL="https://archive.landoop.com/lenses/2.0/lenses-2.0.7-linux64.tar.gz"
RUN wget $AD_UN $AD_PW "$AD_URL" -O /lenses.tgz \
    && tar xf /lenses.tgz -C /opt \
    && ln -s /opt/lenses/bin/lenses /usr/local/bin/lenses \
    && rm /lenses.tgz

# Add Lenses CLI
ARG LC_VERSION="2.0.3"
ARG LC_URL="https://archive.landoop.com/tools/lenses-cli/2.0/$LC_VERSION/lenses-cli-linux-amd64-$LC_VERSION.tar.gz"
RUN wget "$LC_URL" -O /lenses-cli.tgz \
    && tar xzf /lenses-cli.tgz --strip-components=1 -C /usr/local/bin/ lenses-cli-linux-amd64-$LC_VERSION/lenses-cli \
    && rm -f /lenses-cli.tgz

# Add cc_payments generator
RUN wget https://archive.landoop.com/tools/cc_payments_demo_generator/generator-1.0.tgz -O /generator.tgz \
    && mkdir -p /opt/generator \
    && tar xf /generator.tgz --no-same-owner --strip-components=1 -C /opt/generator \
    && sed -e 's/localhost/0.0.0.0/' -i /opt/generator/lenses.conf \
    && rm -f /generator.tgz

COPY /filesystem /
RUN chmod +x /usr/local/bin/{smoke-tests,logs-to-kafka,nullsink}.sh \
             /usr/local/share/landoop/sample-data/*.sh

# Create system symlinks to Kafka binaries
RUN bash -c 'for i in $(find /opt/landoop/kafka/bin /opt/landoop/tools/bin -maxdepth 1 -type f); do ln -s $i /usr/local/bin/$(echo $i | sed -e "s>.*/>>"); done'

# Setup Kafka Topics UI, Schema Registry UI, Kafka Connect UI
RUN mkdir -p \
      /var/www/kafka-topics-ui \
      /var/www/schema-registry-ui \
      /var/www/kafka-connect-ui \
    && tar -xf /opt/landoop/tools/share/kafka-topics-ui/kafka-topics-ui.tar.gz \
           -C /var/www/kafka-topics-ui \
           --exclude=env.js \
    && tar -xf /opt/landoop/tools/share/schema-registry-ui/schema-registry-ui.tar.gz \
           -C /var/www/schema-registry-ui \
           --exclude=env.js \
    && tar -xf /opt/landoop/tools/share/kafka-connect-ui/kafka-connect-ui.tar.gz \
           -C /var/www/kafka-connect-ui \
           --exclude=env.js

RUN ln -s /var/log /var/www/logs

# Add executables, settings and configuration
ADD setup-and-run.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup-and-run.sh \
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
    && grep 'export LENSES_REVISION'   /opt/lenses/bin/lenses | sed -e 's/export /FDD_/' | tee -a /build.info \
    && grep 'export LENSESUI_REVISION' /opt/lenses/bin/lenses | sed -e 's/export /FDD_/' | tee -a /build.info \
    && grep 'export LENSES_VERSION'    /opt/lenses/bin/lenses | sed -e 's/export /FDD_/' | tee -a /build.info \
    && echo "FDD_LENSES_CLI_VERSION=${LC_VERSION}" | tee -a /build.info \
    && sed -e 's/^/FDD_/' /opt/landoop/build.info  | tee -a /build.info

EXPOSE 2181 3030 3031 8081 8082 8083 9092
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/local/bin/setup-and-run.sh"]

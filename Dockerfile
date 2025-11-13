ARG LKD_VERSION=3.9.0-L0

FROM debian:12 AS compile-lkd
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
ARG LKD_VERSION

############
# Add kafka/
############

# Add Apache Kafka (includes Connect and Zookeeper)
ARG KAFKA_VERSION=3.9.0
ARG KAFKA_LVERSION="${KAFKA_VERSION}-L0"
ARG KAFKA_URL="${ARCHIVE_SERVER}/lkd/packages/kafka/kafka-2.13-${KAFKA_LVERSION}-lkd.tar.gz"

RUN wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_URL" -O /opt/kafka.tar.gz \
    && tar --no-same-owner -xzf /opt/kafka.tar.gz -C /opt \
    && mkdir /opt/lensesio/kafka/logs && chmod 1777 /opt/lensesio/kafka/logs \
    && rm -rf /opt/kafka.tar.gz

# Add Schema Registry
ARG REGISTRY_VERSION=7.7.1-lkd-r0
ARG REGISTRY_URL="${ARCHIVE_SERVER}/lkd/packages/schema-registry/schema-registry-${REGISTRY_VERSION}.tar.gz"
RUN wget $DEVARCH_USER $DEVARCH_PASS "$REGISTRY_URL" -O /opt/registry.tar.gz \
    && tar --no-same-owner -xzf /opt/registry.tar.gz -C /opt/ \
    && rm -rf /opt/registry.tar.gz

# Configure Connect and Confluent Components to support CORS
RUN echo -e 'access.control.allow.methods=GET,POST,PUT,DELETE,OPTIONS\naccess.control.allow.origin=*' \
         | tee -a /opt/lensesio/kafka/etc/schema-registry/schema-registry.properties \
         | tee -a /opt/lensesio/kafka/etc/schema-registry/connect-avro-distributed.properties


#################
# Add connectors/
#################

# Add Stream Reactor and needed components
ARG STREAM_REACTOR_VERSION=10.0.2
ARG STREAM_REACTOR_URL="https://archive.lenses.io/lkd/packages/connectors/stream-reactor/stream-reactor-${STREAM_REACTOR_VERSION}.tar.gz"
ARG ACTIVEMQ_VERSION=5.12.3

RUN wget $DEVARCH_USER $DEVARCH_PASS "${STREAM_REACTOR_URL}" -O /stream-reactor.tar.gz \
    && mkdir -p /opt/lensesio/connectors/stream-reactor \
    && tar -xf /stream-reactor.tar.gz \
           --no-same-owner \
           --strip-components=1 \
           -C /opt/lensesio/connectors/stream-reactor \
    && rm /stream-reactor.tar.gz \
    && wget https://repo1.maven.org/maven2/org/apache/activemq/activemq-all/${ACTIVEMQ_VERSION}/activemq-all-${ACTIVEMQ_VERSION}.jar \
            -P /opt/lensesio/connectors/stream-reactor/kafka-connect-jms \
    && mkdir -p /opt/lensesio/kafka/share/java/lensesio-common \
    && export _NUM_CONNECTORS=$(ls /opt/lensesio/connectors/stream-reactor | wc -l) \
    && for file in $(find /opt/lensesio/connectors/stream-reactor -maxdepth 2 -type f -exec basename {} \; | grep -Ev "scala-logging|kafka-connect-common|scala-" | grep jar | grep -v log4j-over-slf4j | sort | uniq -c | awk '{if ($1>5) print $2}' ); do \
         cp $(find /opt/lensesio/connectors/stream-reactor/ -type f -name $file | head -n1) /opt/lensesio/kafka/share/java/lensesio-common/; \
         find /opt/lensesio/connectors/stream-reactor/ -type f -name $file -delete; \
       done \
    && for file in $(find /opt/lensesio/kafka/share/java/{kafka,lensesio-common} -maxdepth 1 -type f -exec basename {} \; | sort | uniq -c | grep -E "^\s+2 " | awk '{print $2}' ); do \
         echo "Removing duplicate /opt/lensesio/kafka/share/java/lensesio-common/$file."; \
         rm -f /opt/lensesio/kafka/share/java/lensesio-common/$file; \
       done \
    && rm -f /opt/lensesio/connectors/stream-reactor/*/*{javadoc,scaladoc,sources}.jar \
    && echo "plugin.path=/opt/lensesio/connectors/stream-reactor,/opt/lensesio/connectors/third-party" \
            >> /opt/lensesio/kafka/etc/schema-registry/connect-avro-distributed.properties

# Add Secrets Provider
ARG SECRET_PROVIDER_VERSION=2.3.0
ARG SECRET_PROVIDER_URL="https://github.com/lensesio/secret-provider/releases/download/${SECRET_PROVIDER_VERSION}/secret-provider-${SECRET_PROVIDER_VERSION}-all.jar"
RUN mkdir -p /opt/lensesio/connectors/stream-reactor/kafka-connect-secret-provider \
    && wget "${SECRET_PROVIDER_URL}" -P "/opt/lensesio/connectors/stream-reactor/kafka-connect-secret-provider"

# Add Kafka Connect SMTs
ARG KAFKA_CONNECT_SMT_VERSION=1.5.0
ARG KAFKA_CONNECT_SMT_URL="https://github.com/lensesio/kafka-connect-smt/releases/download/v${KAFKA_CONNECT_SMT_VERSION}/kafka-connect-smt-${KAFKA_CONNECT_SMT_VERSION}.jar"
RUN mkdir -p /opt/lensesio/connectors/stream-reactor/kafka-connect-smt \
    && wget "${KAFKA_CONNECT_SMT_URL}" -P "/opt/lensesio/connectors/stream-reactor/kafka-connect-smt"

# Add Third Party Connectors

## Filesource
RUN mkdir -p /opt/lensesio/connectors/third-party/kafka-connect-file \
    && ln -s /opt/lensesio/kafka/share/java/kafka/connect-file-${KAFKA_LVERSION}.jar \
          /opt/lensesio/connectors/third-party/kafka-connect-file/connect-file-${KAFKA_LVERSION}.jar

# Kafka Connect Debezium MongoDB / MySQL / Postgres / MsSQL
ARG KAFKA_CONNECT_DEBEZIUM_MONGODB_VERSION=2.7.4.Final
ARG KAFKA_CONNECT_DEBEZIUM_MONGODB_URL="https://search.maven.org/remotecontent?filepath=io/debezium/debezium-connector-mongodb/${KAFKA_CONNECT_DEBEZIUM_MONGODB_VERSION}/debezium-connector-mongodb-${KAFKA_CONNECT_DEBEZIUM_MONGODB_VERSION}-plugin.tar.gz"
ARG KAFKA_CONNECT_DEBEZIUM_MYSQL_VERSION=2.7.4.Final
ARG KAFKA_CONNECT_DEBEZIUM_MYSQL_URL="https://search.maven.org/remotecontent?filepath=io/debezium/debezium-connector-mysql/${KAFKA_CONNECT_DEBEZIUM_MYSQL_VERSION}/debezium-connector-mysql-${KAFKA_CONNECT_DEBEZIUM_MYSQL_VERSION}-plugin.tar.gz"
ARG KAFKA_CONNECT_DEBEZIUM_POSTGRES_VERSION=2.7.4.Final
ARG KAFKA_CONNECT_DEBEZIUM_POSTGRES_URL="https://search.maven.org/remotecontent?filepath=io/debezium/debezium-connector-postgres/${KAFKA_CONNECT_DEBEZIUM_POSTGRES_VERSION}/debezium-connector-postgres-${KAFKA_CONNECT_DEBEZIUM_POSTGRES_VERSION}-plugin.tar.gz"
ARG KAFKA_CONNECT_DEBEZIUM_SQLSERVER_VERSION=2.7.4.Final
ARG KAFKA_CONNECT_DEBEZIUM_SQLSERVER_URL="https://search.maven.org/remotecontent?filepath=io/debezium/debezium-connector-sqlserver/${KAFKA_CONNECT_DEBEZIUM_SQLSERVER_VERSION}/debezium-connector-sqlserver-${KAFKA_CONNECT_DEBEZIUM_SQLSERVER_VERSION}-plugin.tar.gz"
ARG KAFKA_CONNECT_DEBEZIUM_JDBC_VERSION=2.7.4.Final
ARG KAFKA_CONNECT_DEBEZIUM_JDBC_URL="https://search.maven.org/remotecontent?filepath=io/debezium/debezium-connector-jdbc/${KAFKA_CONNECT_DEBEZIUM_JDBC_VERSION}/debezium-connector-jdbc-${KAFKA_CONNECT_DEBEZIUM_JDBC_VERSION}-plugin.tar.gz"
RUN mkdir -p /opt/lensesio/connectors/third-party/kafka-connect-debezium-{mongodb,mysql,postgres,sqlserver,jdbc} \
    && wget "$KAFKA_CONNECT_DEBEZIUM_MONGODB_URL" -O /debezium-mongodb.tgz \
    && file /debezium-mongodb.tgz \
    && tar -xf /debezium-mongodb.tgz \
           --owner=root --group=root --strip-components=1 \
           -C  /opt/lensesio/connectors/third-party/kafka-connect-debezium-mongodb \
    && wget "$KAFKA_CONNECT_DEBEZIUM_MYSQL_URL" -O /debezium-mysql.tgz \
    && file /debezium-mysql.tgz \
    && tar -xf /debezium-mysql.tgz \
           --owner=root --group=root --strip-components=1 \
           -C  /opt/lensesio/connectors/third-party/kafka-connect-debezium-mysql \
    && wget "$KAFKA_CONNECT_DEBEZIUM_POSTGRES_URL" -O /debezium-postgres.tgz \
    && file /debezium-postgres.tgz \
    && tar -xf /debezium-postgres.tgz \
           --owner=root --group=root --strip-components=1 \
           -C  /opt/lensesio/connectors/third-party/kafka-connect-debezium-postgres \
    && wget "$KAFKA_CONNECT_DEBEZIUM_SQLSERVER_URL" -O /debezium-sqlserver.tgz \
    && tar -xf /debezium-sqlserver.tgz \
           --owner=root --group=root --strip-components=1 \
           -C  /opt/lensesio/connectors/third-party/kafka-connect-debezium-sqlserver \
    && wget "$KAFKA_CONNECT_DEBEZIUM_JDBC_URL" -O /debezium-jdbc.tgz \
    && tar -xf /debezium-jdbc.tgz \
           --owner=root --group=root --strip-components=1 \
           -C  /opt/lensesio/connectors/third-party/kafka-connect-debezium-jdbc \
    && rm -rf /debezium-{mongodb,mysql,postgres,sqlserver,jdbc}.tgz

############
# Add tools/
############

# Add Coyote
ARG COYOTE_VERSION=1.5
ARG COYOTE_URL="https://github.com/lensesio/coyote/releases/download/v${COYOTE_VERSION}/coyote-${COYOTE_VERSION}-${TARGETOS}-${TARGETARCH}"
RUN mkdir -p /opt/lensesio/tools/bin /opt/lensesio/tools/share/coyote/examples \
    && wget "$COYOTE_URL" -O /opt/lensesio/tools/bin/coyote \
    && chmod +x /opt/lensesio/tools/bin/coyote
ADD lkd/simple-integration-tests.yml /opt/lensesio/tools/share/coyote/examples/

# Add Kafka Autocomplete
ARG KAFKA_AUTOCOMPLETE_VERSION=0.4
ARG KAFKA_AUTOCOMPLETE_URL="https://github.com/lensesio/kafka-autocomplete/releases/download/${KAFKA_AUTOCOMPLETE_VERSION}/kafka"
RUN mkdir -p /opt/lensesio/tools/share/kafka-autocomplete \
             /opt/lensesio/tools/share/bash-completion/completions \
    && wget "$KAFKA_AUTOCOMPLETE_URL" \
            -O /opt/lensesio/tools/share/kafka-autocomplete/kafka \
    && wget "$KAFKA_AUTOCOMPLETE_URL" \
            -O /opt/lensesio/tools/share/bash-completion/completions/kafka

# Enable jline for Zookeeper
RUN TJLINE="$(find /opt/lensesio/kafka -name "jline-0*.jar" | head -n1)" \
    && if [[ -n $TJLINE ]]; then sed "s|^exec.*|export CLASSPATH=\"\$CLASSPATH:$TJLINE\"\n&|" -i /opt/lensesio/kafka/bin/zookeeper-shell; fi

# Add normcat
ARG NORMCAT_VERSION=1.1.1
ARG NORMCAT_URL="https://github.com/andmarios/normcat/releases/download/${NORMCAT_VERSION}/normcat-${NORMCAT_VERSION}-${TARGETOS}-${TARGETARCH}"
RUN wget "$NORMCAT_URL"-lowmem.tar.gz -O /normcat-linux.tgz \
    && tar -xf /normcat-linux.tgz -C /opt/lensesio/tools/bin \
    && chmod +x /opt/lensesio/tools/bin/normcat \
    && rm -f /normcat-linux.tgz

##########
# Finalize
##########

RUN echo    "LKD_VERSION=${LKD_VERSION}"                               | tee -a /opt/lensesio/build.info \
    && echo "KAFKA_VERSION=${KAFKA_LVERSION}"                          | tee -a /opt/lensesio/build.info \
    && echo "CONNECT_VERSION=${KAFKA_LVERSION}"                        | tee -a /opt/lensesio/build.info \
    && echo "SCHEMA_REGISTRY_VERSION=${REGISTRY_VERSION}"              | tee -a /opt/lensesio/build.info \
    && echo "STREAM_REACTOR_VERSION=${STREAM_REACTOR_VERSION}"         | tee -a /opt/lensesio/build.info \
    && echo "KAFKA_CONNECT_SMT_VERSION=${KAFKA_CONNECT_SMT_VERSION}"   | tee -a /opt/lensesio/build.info \
    && echo "SECRET_PROVIDER_VERSION=${SECRET_PROVIDER_VERSION}"       | tee -a /opt/lensesio/build.info \
    && echo "KAFKA_CONNECT_DEBEZIUM_MONGODB_VERSION=${KAFKA_CONNECT_DEBEZIUM_MONGODB_VERSION}" \
                                                                       | tee -a /opt/lensesio/build.info \
    && echo "KAFKA_CONNECT_DEBEZIUM_MYSQL_VERSION=${KAFKA_CONNECT_DEBEZIUM_MYSQL_VERSION}" \
                                                                       | tee -a /opt/lensesio/build.info \
    && echo "KAFKA_CONNECT_DEBEZIUM_SQLSERVER_VERSION=${KAFKA_CONNECT_DEBEZIUM_SQLSERVER_VERSION}" \
                                                                       | tee -a /opt/lensesio/build.info \
    && echo "KAFKA_CONNECT_DEBEZIUM_POSTGRES_VERSION=${KAFKA_CONNECT_DEBEZIUM_POSTGRES_VERSION}" \
                                                                       | tee -a /opt/lensesio/build.info \
    && echo "KAFKA_CONNECT_DEBEZIUM_JDBC_VERSION=${KAFKA_CONNECT_DEBEZIUM_JDBC_VERSION}" \
                                                                       | tee -a /opt/lensesio/build.info \
    && echo "COYOTE_VERSION=${COYOTE_VERSION}"                         | tee -a /opt/lensesio/build.info \
    && echo "KAFKA_AUTOCOMPLETE_VERSION=${KAFKA_AUTOCOMPLETE_VERSION}" | tee -a /opt/lensesio/build.info \
    && echo "NORMCAT_VERSION=${NORMCAT_VERSION}"                       | tee -a /opt/lensesio/build.info

# duphard (replace duplicates with hard links) and create archive
# We run as two separate commands because otherwise the build fails in docker hub (but not locally)
RUN duphard -d=0 /opt/lensesio
RUN tar -czf /LKD-${LKD_VERSION}.tar.gz \
           --owner=root \
           --group=root \
           -C /opt \
           lensesio \
    && rm -rf /opt/lensesio
# Unfortunately we have to make this a separate step in order for docker to understand the change to hardlinks
# Good thing: final image that people download is much smaller (~200MB).
RUN tar xf /LKD-${LKD_VERSION}.tar.gz -C /opt \
    && rm /LKD-${LKD_VERSION}.tar.gz

ENV LKD_VERSION=${LKD_VERSION}
# If this stage is run as container and you mount `/mnt`, we will create the LKD archive there.
CMD ["bash", "-c", "tar -czf /mnt/LKD-${LKD_VERSION}.tar.gz -C /opt lensesio; chown --reference=/mnt /mnt/LKD-${LKD_VERSION}.tar.gz"]

FROM debian:12-slim

MAINTAINER Marios Andreopoulos <marios@lenses.io>
COPY --from=compile-lkd /opt /opt
ARG TARGETOS TARGETARCH
ARG LKD_VERSION
LABEL org.opencontainers.image.authors="Marios Andreopoulos <marios@lenses.io>"
LABEL org.opencontainers.image.ref.name="lensesio/fast-data-dev"
LABEL org.opencontainers.image.version=${LKD_VERSION}
LABEL org.opencontainers.imave.vendor="Lenses.io"

# Update, install tooling and some basic setup
RUN apt-get update \
    && apt-get install -y \
        bash-completion \
        bzip2 \
        caddy \
        coreutils \
        curl \
        default-jre-headless \
        dumb-init \
        gettext \
        gzip \
        jq \
        locales \
        netcat-openbsd \
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
ARG CHECKPORT_URL="https://github.com/andmarios/checkport/releases/download/0.1/checkport-${TARGETOS}-${TARGETARCH}"
ARG QUICKCERT_URL="https://github.com/andmarios/quickcert/releases/download/1.1/quickcert-1.1-${TARGETOS}-${TARGETARCH}"
ARG GOTTY_URL_AMD64=https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_amd64.tar.gz
ARG GOTTY_URL_ARM64=https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_arm.tar.gz
RUN wget "$CHECKPORT_URL" -O /usr/local/bin/checkport \
    && wget "$QUICKCERT_URL" -O /usr/local/bin/quickcert \
    && chmod 0755 /usr/local/bin/quickcert /usr/local/bin/checkport \
    && if [[ $TARGETARCH == amd64 ]]; then GOTTY_URL=$GOTTY_URL_AMD64; elif [[ $TARGETARCH == arm64 ]]; then GOTTY_URL=$GOTTY_URL_ARM64; fi \
    && wget "$GOTTY_URL" -O /gotty.tar.gz \
    && mkdir -p /opt/gotty \
    && tar xzf gotty.tar.gz -C /opt/gotty \
    && rm -f gotty.tar.gz \
    && localedef -i en_US -f UTF-8 en_US.UTF-8
ENV LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8

COPY /filesystem /
RUN chmod +x /usr/local/bin/{smoke-tests,logs-to-kafka,nullsink}.sh \
             /usr/local/share/lensesio/sample-data/*.sh

# Create system symlinks to Kafka binaries
RUN bash -c 'for i in $(find /opt/lensesio/kafka/bin /opt/lensesio/tools/bin -maxdepth 1 -type f); do ln -s $i /usr/local/bin/$(echo $i | sed -e "s>.*/>>"); done'

# Compatibility directories that were used with LKD 3.3.1 and older. FDD does
# not need them, but we add them in case users have scripts or docker-compose
# files that rely on them.
RUN ln -s /opt/lensesio /opt/landoop \
    && ln -s /usr/local/share/lensesio /usr/local/share/landoop

# Add kafka ssl principal builder
RUN wget https://archive.lenses.io/third-party/kafka-custom-principal-builder/kafka-custom-principal-builder-1.0-SNAPSHOT.jar \
         -P /opt/lensesio/kafka/share/java/kafka \
    && mkdir -p /opt/lensesio/kafka/share/docs/kafka-custom-principal-builder \
    && wget https://archive.lenses.io/third-party/kafka-custom-principal-builder/LICENSE \
         -P /opt/lensesio/kafka/share/docs/kafka-custom-principal-builder \
    && wget https://archive.lenses.io/third-party/kafka-custom-principal-builder/README.md \
         -P /opt/lensesio/kafka/share/docs/kafka-custom-principal-builder

RUN ln -s /var/log /var/www/logs

# Add executables, settings and configuration
ADD setup-and-run.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup-and-run.sh \
    && rm -f /root/.bashrc \
    && ln -s /usr/local/share/lensesio/etc/bashrc /root/.bashrc

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
    && sed -e 's/^/FDD_/' /opt/lensesio/build.info      | tee -a /build.info

EXPOSE 2181 3030 3031 8081 8082 8083 9092
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/local/bin/setup-and-run.sh"]

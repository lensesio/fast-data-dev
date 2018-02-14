FROM debian as lkd-build
MAINTAINER Marios Andreopoulos <marios@landoop.com>

RUN apt-get update \
    && apt-get install -y \
         wget \
    && rm -rf /var/lib/apt/lists/* \
    && echo "progress = dot:giga" | tee /etc/wgetrc \
    && mkdir -p /mnt /opt /data \
    && wget https://github.com/andmarios/duphard/releases/download/v1.0/duphard -O /bin/duphard \
    && chmod +x /bin/duphard

ADD build-lkd.sh /usr/bin/
ADD simple-integration-tests.yml /data/

WORKDIR /root

#docker build --build-arg KAFKA_URL=http://192.168.1.30:2015/kafka-2.11-1.0.0-L1-lkd.tar.gz --build-arg REGISTRY_URL=http://192.168.1.30:2015/schema-registry-4.0.0-lkd.tar.gz --build-arg REST_URL=http://192.168.1.30:2015/rest-proxy-4.0.0-lkd.tar.gz --build-arg KAFKA_CONNECT_JDBC_URL=http://192.168.1.30:2015/kafka-connect-jdbc-4.0.0-lkd.tar.gz --build-arg KAFKA_CONNECT_ELASTICSEARCH_URL=http://192.168.1.30:2015/kafka-connect-elasticsearch-4.0.0-lkd.tar.gz --build-arg KAFKA_CONNECT_HDFS_URL=http://192.168.1.30:2015/kafka-connect-hdfs-4.0.0-lkd.tar.gz --build-arg KAFKA_CONNECT_S3_URL=http://192.168.1.30:2015/kafka-connect-s3-4.0.0-lkd.tar.gz?1 -t landoop/fdd:lkd-1.0 .

ARG LKD_VERSION=1.0.0-r0
ENV LKD_VERSION=$LKD_VERSION
ARG KAFKA_URL
ENV KAFKA_URL=$KAFKA_URL
ARG REGISTRY_URL
ENV REGISTRY_URL=$REGISTRY_URL
ARG REST_URL
ENV REST_URL=$REST_URL
ARG KAFKA_CONNECT_JDBC_URL
ENV KAFKA_CONNECT_JDBC_URL=$KAFKA_CONNECT_JDBC_URL
ARG KAFKA_CONNECT_ELASTICSEARCH_URL
ENV KAFKA_CONNECT_ELASTICSEARCH_URL=$KAFKA_CONNECT_ELASTICSEARCH_URL
ARG KAFKA_CONNECT_HDFS_URL
ENV KAFKA_CONNECT_HDFS_URL=$KAFKA_CONNECT_HDFS_URL
ARG KAFKA_CONNECT_S3_URL
ENV KAFKA_CONNECT_S3_URL=$KAFKA_CONNECT_S3_URL

RUN build-lkd.sh
RUN tar xzf /mnt/LKD-${LKD_VERSION}.tar.gz -C /opt

FROM alpine
MAINTAINER Marios Andreopoulos <marios@landoop.com>
COPY --from=lkd-build /opt /opt

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
    && wget https://gitlab.com/andmarios/checkport/uploads/3903dcaeae16cd2d6156213d22f23509/checkport -O /usr/local/bin/checkport \
    && chmod +x /usr/local/bin/checkport \
    && mkdir /extra-connect-jars /connectors \
    && mkdir /etc/supervisord.d /etc/supervisord.templates.d

# # Install LKD (Landoop’s Kafka Distribution)
# ENV LKD_VERSION="1.0.0-r0"
# ARG LKD_URL="https://archive.landoop.com/lkd/packages/lkd-${LKD_VERSION}.tar.gz"
# RUN wget "$LKD_URL" -O /lkd.tar.gz \
#     && tar xf /lkd.tar.gz -C /opt \
#     && rm /lkd.tar.gz \
#     && echo "plugin.path=/opt/landoop/connectors/stream-reactor,/opt/landoop/connectors/third-party,/connectors,/extra-jars" \
#              >> /opt/landoop/kafka/etc/schema-registry/connect-avro-distributed.properties

RUN echo "plugin.path=/opt/landoop/connectors/stream-reactor,/opt/landoop/connectors/third-party,/connectors,/extra-jars" \
          >> /opt/landoop/kafka/etc/schema-registry/connect-avro-distributed.properties

# Create Landoop configuration directory
RUN mkdir /usr/share/landoop

# Add glibc (for Lenses branch, for HDFS connector etc as some java libs need some functions provided by glibc)
ARG GLIBC_INST_VERSION="2.27-r0"
RUN wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_INST_VERSION}/glibc-${GLIBC_INST_VERSION}.apk \
    && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_INST_VERSION}/glibc-bin-${GLIBC_INST_VERSION}.apk \
    && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_INST_VERSION}/glibc-i18n-${GLIBC_INST_VERSION}.apk \
    && apk add --no-cache --allow-untrusted glibc-${GLIBC_INST_VERSION}.apk glibc-bin-${GLIBC_INST_VERSION}.apk glibc-i18n-${GLIBC_INST_VERSION}.apk \
    && rm -f glibc-${GLIBC_INST_VERSION}.apk glibc-bin-${GLIBC_INST_VERSION}.apk glibc-i18n-${GLIBC_INST_VERSION}.apk

# Create system symlinks to Kafka binaries
RUN bash -c 'for i in $(find /opt/landoop/kafka/bin -maxdepth 1 -type f); do ln -s $i /usr/local/bin/$(echo $i | sed -e "s>.*/>>"); done'

# Add quickcert
RUN wget https://github.com/andmarios/quickcert/releases/download/1.0/quickcert-1.0-linux-amd64-alpine -O /usr/local/bin/quickcert \
    && chmod 0755 /usr/local/bin/quickcert

# Add Coyote and tests
ADD integration-tests/smoke-tests.sh /usr/local/bin
RUN chmod +x /usr/local/bin/smoke-tests.sh \
    && mkdir -p /var/www/coyote-tests
ADD integration-tests/index.html integration-tests/results /var/www/coyote-tests/

# Setup Kafka Topics UI, Schema Registry UI, Kafka Connect UI
RUN mkdir -p \
      /var/www/kafka-topics-ui \
      /var/www/schema-registry-ui \
      /var/www/kafka-connect-ui \
    && tar xzf /opt/landoop/tools/share/kafka-topics-ui/kafka-topics-ui.tar.gz -C /var/www/kafka-topics-ui \
    && tar xzf /opt/landoop/tools/share/schema-registry-ui/schema-registry-ui.tar.gz -C /var/www/schema-registry-ui \
    && tar xzf /opt/landoop/tools/share/kafka-connect-ui/kafka-connect-ui.tar.gz -C /var/www/kafka-connect-ui
COPY web/registry-ui-env.js /var/www/schema-registry-ui/env.js
COPY web/topics-ui-env.js /var/www/kafka-topics-ui/env.js
COPY web/connect-ui-env.js /var/www/kafka-connect-ui/env.js

# Add and setup Caddy Server
ARG CADDY_URL=https://github.com/mholt/caddy/releases/download/v0.10.10/caddy_v0.10.10_linux_amd64.tar.gz
RUN wget "$CADDY_URL" -O /caddy.tgz \
    && mkdir -p /opt/caddy \
    && tar xzf /caddy.tgz -C /opt/caddy \
    && rm -f /caddy.tgz
ADD web/Caddyfile /usr/share/landoop

# Add fast-data-dev UI
COPY web/index.html web/env.js web/env-webonly.js /var/www/
COPY web/img /var/www/img
RUN ln -s /var/log /var/www/logs

# Add sample data and install normcat
ARG NORMCAT_URL=https://archive.landoop.com/tools/normcat/normcat_lowmem-1.1.1.tgz
RUN wget "$NORMCAT_URL" -O /normcat.tgz \
    && tar xf /normcat.tgz -C /usr/local/bin \
    && rm /normcat.tgz
COPY sample-data /usr/share/landoop/sample-data

# Add executables, settings and configuration
ADD extras/ /usr/share/landoop/
ADD supervisord.conf /etc/supervisord.conf
ADD supervisord.templates.d/* /etc/supervisord.templates.d/
ADD setup-and-run.sh logs-to-kafka.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup-and-run.sh /usr/local/bin/logs-to-kafka.sh \
    && ln -s /usr/share/landoop/bashrc /root/.bashrc \
    && cat /etc/supervisord.templates.d/* > /etc/supervisord.d/01-fast-data.conf

ARG BUILD_BRANCH
ARG BUILD_COMMIT
ARG BUILD_TIME
ARG DOCKER_REPO=local
RUN echo "BUILD_BRANCH=${BUILD_BRANCH}"       | tee /build.info \
    && echo "BUILD_COMMIT=${BUILD_COMMIT}"    | tee -a /build.info \
    && echo "BUILD_TIME=${BUILD_TIME}"        | tee -a /build.info \
    && echo "DOCKER_REPO=${DOCKER_REPO}"      | tee -a /build.info \
    && echo "LKD=${LKD_VERSION}"              | tee -a /build.info \
    && cat /opt/landoop/build.info            | tee -a /build.info

EXPOSE 2181 3030 3031 8081 8082 8083 9092
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/local/bin/setup-and-run.sh"]

FROM alpine
MAINTAINER Marios Andreopoulos <marios@landoop.com>

# Update, install tooling and some basic setup
RUN apk add --no-cache \
        bash \
        bash-completion \
        bzip2 \
        coreutils \
        curl \
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
    && mkdir /opt \
    && wget https://gitlab.com/andmarios/checkport/uploads/3903dcaeae16cd2d6156213d22f23509/checkport -O /usr/local/bin/checkport \
    && chmod +x /usr/local/bin/checkport \
    && mkdir /extra-connect-jars /connectors \
    && mkdir /etc/supervisord.d /etc/supervisord.templates.d

# Create Landoop configuration directory
RUN mkdir /usr/share/landoop

# Login args for development archives
ARG DEVARCH_USER
ARG DEVARCH_PASS
# Add Apache Kafka (includes Connect and Zookeeper)
ENV KAFKA_VERSION="1.0.0"
ENV KAFKA_LVERSION="1.0.0-L1"
ARG KAFKA_URL="https://archive.landoop.com/lkd/packages/kafka_2.11-${KAFKA_LVERSION}-lkd.tar.gz"
RUN wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_URL" -O /opt/kafka.tar.gz \
    && tar --no-same-owner -xzf /opt/kafka.tar.gz -C /opt \
    && mkdir /opt/landoop/kafka/logs && chmod 1777 /opt/landoop/kafka/logs \
    && rm -rf /opt/kafka.tar.gz \
    && ln -s /opt/landoop/kafka "/opt/landoop/kafka-${KAFKA_VERSION}"

# Add Schema Registry and REST Proxy
ENV REGISTRY_VERSION="4.0.0-lkd"
ARG REGISTRY_URL="https://archive.landoop.com/lkd/packages/schema_registry_${REGISTRY_VERSION}.tar.gz"
RUN wget $DEVARCH_USER $DEVARCH_PASS "$REGISTRY_URL" -O /opt/registry.tar.gz \
    && tar --no-same-owner -xzf /opt/registry.tar.gz -C /opt/ \
    && rm -rf /opt/registry.tar.gz

ENV REST_VERSION="4.0.0-lkd"
ARG REST_URL="https://archive.landoop.com/lkd/packages/rest_proxy_${REST_VERSION}.tar.gz"
RUN wget $DEVARCH_USER $DEVARCH_PASS "$REST_URL" -O /opt/rest.tar.gz \
    && tar --no-same-owner -xzf /opt/rest.tar.gz -C /opt/ \
    && rm -rf /opt/rest.tar.gz

# Add Stream Reactor and Elastic Search (for elastic connector)
ENV STREAM_REACTOR_VERSION="1.0.0"
ARG STREAM_REACTOR_URL=https://archive.landoop.com/stream-reactor/stream-reactor-${STREAM_REACTOR_VERSION}_connect${KAFKA_VERSION}.tar.gz
ARG CALCITE_LINQ4J_URL="https://central.maven.org/maven2/org/apache/calcite/calcite-linq4j/1.12.0/calcite-linq4j-1.12.0.jar"
RUN wget "${STREAM_REACTOR_URL}" -O stream-reactor.tar.gz \
    && mkdir -p /opt/landoop/connectors \
    && tar -xzf stream-reactor.tar.gz --no-same-owner --strip-components=1 -C /opt/landoop/connectors \
    && rm /stream-reactor.tar.gz \
    && wget https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/2.4.1/elasticsearch-2.4.1.tar.gz \
    && tar xf /elasticsearch-2.4.1.tar.gz --no-same-owner \
    && mv /elasticsearch-2.4.1/lib/*.jar /opt/landoop/connectors/kafka-connect-elastic/ \
    && rm -rf /elasticsearch-2.4.1* \
    && wget http://central.maven.org/maven2/org/apache/activemq/activemq-all/5.15.2/activemq-all-5.15.2.jar -P /opt/landoop/connectors/kafka-connect-jms \
    && wget http://central.maven.org/maven2/org/apache/calcite/calcite-linq4j/1.12.0/calcite-linq4j-1.12.0.jar -O /calcite-linq4j-1.12.0.jar \
    && bash -c 'for path in /opt/landoop/connectors/kafka-connect-*; do cp /calcite-linq4j-1.12.0.jar $path/; done' \
    && rm /calcite-linq4j-1.12.0.jar \
    && echo "plugin.path=/opt/landoop/connectors,/opt/landoop/connectors-3rd-party,/extra-connect-jars,/connectors" >> /opt/landoop/kafka/etc/schema-registry/connect-avro-distributed.properties

# Add glibc (for Lenses branch, for HDFS connector etc as some java libs need some functions provided by glibc)
ARG GLIBC_INST_VERSION="2.27-r0"
RUN wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_INST_VERSION}/glibc-${GLIBC_INST_VERSION}.apk \
    && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_INST_VERSION}/glibc-bin-${GLIBC_INST_VERSION}.apk \
    && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_INST_VERSION}/glibc-i18n-${GLIBC_INST_VERSION}.apk \
    && apk add --no-cache --allow-untrusted glibc-${GLIBC_INST_VERSION}.apk glibc-bin-${GLIBC_INST_VERSION}.apk glibc-i18n-${GLIBC_INST_VERSION}.apk \
    && rm -f glibc-${GLIBC_INST_VERSION}.apk glibc-bin-${GLIBC_INST_VERSION}.apk glibc-i18n-${GLIBC_INST_VERSION}.apk

# Create system symlinks to Kafka binaries
RUN bash -c 'for i in $(find /opt/landoop/kafka/bin -maxdepth 1 -type f); do ln -s $i /usr/local/bin/$(echo $i | sed -e "s>.*/>>"); done' \
    && cd /opt/landoop/kafka/bin \
    && ln -s kafka-run-class kafka-run-class.sh

# Configure Connect and Confluent Components to support CORS
RUN echo "access.control.allow.methods=GET,POST,PUT,DELETE,OPTIONS" >> /opt/landoop/kafka/etc/schema-registry/schema-registry.properties \
    && echo 'access.control.allow.origin=*' >> /opt/landoop/kafka/etc/schema-registry/schema-registry.properties \
    && echo "access.control.allow.methods=GET,POST,PUT,DELETE,OPTIONS" >> /opt/landoop/kafka/etc/kafka-rest/kafka-rest.properties \
    && echo 'access.control.allow.origin=*' >> /opt/landoop/kafka/etc/kafka-rest/kafka-rest.properties \
    && echo "access.control.allow.methods=GET,POST,PUT,DELETE,OPTIONS" >> /opt/landoop/kafka/etc/schema-registry/connect-avro-distributed.properties \
    && echo 'access.control.allow.origin=*' >> /opt/landoop/kafka/etc/schema-registry/connect-avro-distributed.properties

# # Add and setup Kafka Manager
# RUN wget https://archive.landoop.com/third-party/kafka-manager/kafka-manager-1.3.2.1.zip \
#          -O /kafka-manager-1.3.2.1.zip \
#     && unzip /kafka-manager-1.3.2.1.zip -d /opt \
#     && rm -rf /kafka-manager-1.3.2.1.zip

# Add Third Party Connectors
## Twitter
ARG TWITTER_CONNECTOR_URL="https://archive.landoop.com/third-party/kafka-connect-twitter/kafka-connect-twitter-0.1-master-33331ea-connect-1.0.0-jar-with-dependencies.jar"
RUN mkdir -p /opt/landoop/connectors-3rd-party/kafka-connect-twitter \
    && wget "$TWITTER_CONNECTOR_URL" -P /opt/landoop/connectors-3rd-party/kafka-connect-twitter
## Kafka Connect JDBC
ENV KAFKA_CONNECT_JDBC_VERSION="4.0.0-lkd"
ARG KAFKA_CONNECT_JDBC_URL="https://archive.landoop.com/lkd/packages/kafka-connect-jdbc_${KAFKA_CONNECT_JDBC_VERSION}.tar.gz"
RUN wget $DEVARCH_USER $DEVARCH_PASS "$KAFKA_CONNECT_JDBC_URL" -O /opt/kafka-connect-jdbc.tar.gz \
    && mkdir -p /opt/landoop/connectors-3rd-party/ \
    && tar --no-same-owner -xzf /opt/kafka-connect-jdbc.tar.gz -C /opt/landoop/connectors-3rd-party/ \
    && rm -rf /opt/kafka-connect-jdbc.tar.gz

# Add dumb init and quickcert
RUN wget https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 -O /usr/local/bin/dumb-init \
    && wget https://github.com/andmarios/quickcert/releases/download/1.0/quickcert-1.0-linux-amd64-alpine -O /usr/local/bin/quickcert \
    && chmod 0755 /usr/local/bin/dumb-init /usr/local/bin/quickcert

# Add Coyote and tests
ADD integration-tests/kafka-tests.yml /usr/share/landoop
ADD integration-tests/smoke-tests.sh /usr/local/bin
RUN wget https://github.com/Landoop/coyote/releases/download/v1.1/coyote-1.1-linux-amd64 -O /usr/local/bin/coyote \
    && chmod +x /usr/local/bin/coyote /usr/local/bin/smoke-tests.sh \
    && mkdir -p /var/www/coyote-tests
ADD integration-tests/index.html integration-tests/results /var/www/coyote-tests/

# Add and Setup Schema-Registry-Ui
ARG SCHEMA_REGISTRY_UI_URL="https://github.com/Landoop/schema-registry-ui/releases/download/v.0.9.4/schema-registry-ui-0.9.4.tar.gz"
RUN wget "$SCHEMA_REGISTRY_UI_URL" -O /schema-registry-ui.tar.gz \
    && mkdir -p /var/www/schema-registry-ui \
    && tar xzf /schema-registry-ui.tar.gz -C /var/www/schema-registry-ui \
    && rm -f /schema-registry-ui.tar.gz
COPY web/registry-ui-env.js /var/www/schema-registry-ui/env.js

# Add and Setup Kafka-Topics-Ui
ARG KAFKA_TOPICS_UI_URL="https://github.com/Landoop/kafka-topics-ui/releases/download/v0.9.3/kafka-topics-ui-0.9.3.tar.gz"
RUN wget "$KAFKA_TOPICS_UI_URL" -O /kafka-topics-ui.tar.gz \
    && mkdir /var/www/kafka-topics-ui \
    && tar xzf /kafka-topics-ui.tar.gz -C /var/www/kafka-topics-ui \
    && rm -f /kafka-topics-ui.tar.gz
COPY web/topics-ui-env.js /var/www/kafka-topics-ui/env.js

# Add and Setup Kafka-Connect-UI
ARG KAFKA_CONNECT_UI_URL="https://github.com/Landoop/kafka-connect-ui/releases/download/v.0.9.4/kafka-connect-ui-0.9.4.tar.gz"
RUN wget "$KAFKA_CONNECT_UI_URL" -O /kafka-connect-ui.tar.gz \
    && mkdir /var/www/kafka-connect-ui \
    && tar xzf /kafka-connect-ui.tar.gz -C /var/www/kafka-connect-ui \
    && rm -f /kafka-connect-ui.tar.gz
COPY web/connect-ui-env.js /var/www/kafka-connect-ui/env.js

# Add and setup Caddy Server
ARG CADDY_URL=https://github.com/mholt/caddy/releases/download/v0.9.5/caddy_linux_amd64.tar.gz
RUN wget "$CADDY_URL" -O /caddy.tgz \
    && mkdir -p /opt/caddy \
    && tar xzf /caddy.tgz -C /opt/caddy \
    && mv /opt/caddy/caddy_linux_amd64 /opt/caddy/caddy \
    && rm -f /caddy.tgz
ADD web/Caddyfile /usr/share/landoop

# Add and setup Lenses
ARG AD_UN
ARG AD_PW
ARG AD_URL="https://archive.landoop.com/lenses/1.1/lenses-1.1.1-linux64.tar.gz"
RUN wget $AD_UN $AD_PW "$AD_URL" -O /lenses.tgz \
    && tar xf /lenses.tgz -C /opt \
    && mv /opt/lenses/lenses.conf /opt/lenses/lenses.conf.sample \
    && rm /lenses.tgz

# Add cc_payments generator
RUN wget https://archive.landoop.com/tools/cc_payments_demo_generator/generator-1.0.tgz -O /generator.tgz \
    && mkdir -p /opt/generator \
    && tar xf /generator.tgz --no-same-owner --strip-components=1 -C /opt/generator \
    && sed -e 's/localhost/0.0.0.0/' -i /opt/generator/lenses.conf \
    && rm -f /generator.tgz

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
ADD setup-and-run.sh logs-to-kafka.sh nullsink.sh /usr/local/bin/
ADD https://github.com/Landoop/kafka-autocomplete/releases/download/0.3/kafka /usr/share/landoop/kafka-completion
RUN chmod +x /usr/local/bin/setup-and-run.sh /usr/local/bin/logs-to-kafka.sh \
    && ln -s /usr/share/landoop/bashrc /root/.bashrc \
    && cat /etc/supervisord.templates.d/*.conf > /etc/supervisord.d/01-fast-data.conf

ARG BUILD_BRANCH
ARG BUILD_COMMIT
ARG BUILD_TIME
ARG DOCKER_REPO=local
RUN echo "BUILD_BRANCH=${BUILD_BRANCH}"                                | tee /build.info \
    && echo "BUILD_COMMIT=${BUILD_COMMIT}"                             | tee -a /build.info \
    && echo "BUILD_TIME=${BUILD_TIME}"                                 | tee -a /build.info \
    && echo "DOCKER_REPO=${DOCKER_REPO}"                               | tee -a /build.info \
    && grep 'export LENSES_REVISION'   /opt/lenses/bin/lenses | sed -e 's/export //' | tee -a /build.info \
    && grep 'export LENSESUI_REVISION' /opt/lenses/bin/lenses | sed -e 's/export //' | tee -a /build.info \
    && grep 'export LENSES_VERSION'    /opt/lenses/bin/lenses | sed -e 's/export //' | tee -a /build.info \
    && echo "KAFKA_VERSION=${KAFKA_LVERSION}"                          | tee -a /build.info \
    && echo "CONNECT_VERSION=${KAFKA_LVERSION}"                        | tee -a /build.info \
    && echo "SCHEMA_REGISTRY_VERSION=${REGISTRY_VERSION}"              | tee -a /build.info \
    && echo "REST_PROXY_VERSION=${REST_VERSION}"                       | tee -a /build.info \
    && echo "STREAM_REACTOR_VERSION=${STREAM_REACTOR_VERSION}"         | tee -a /build.info \
    && echo "KAFKA_CONNECT_JDBC_VERSION=${KAFKA_CONNECT_JDBC_VERSION}" | tee -a /build.info

EXPOSE 2181 3030 3031 8081 8082 8083 9092
ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["/usr/local/bin/setup-and-run.sh"]

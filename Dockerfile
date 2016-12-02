FROM alpine
MAINTAINER Marios Andreopoulos <marios@landoop.com>

# Update, install tooling and some basic setup
RUN apk add --no-cache \
        bash coreutils \
        wget curl \
        openjdk8-jre-base \
        tar gzip bzip2 \
        supervisor \
        sqlite \
        libstdc++ \
    && echo "progress = dot:giga" | tee /etc/wgetrc \
    && mkdir /opt \
    && wget https://gitlab.com/andmarios/checkport/uploads/3903dcaeae16cd2d6156213d22f23509/checkport -O /usr/local/bin/checkport \
    && chmod +x /usr/local/bin/checkport \
    && mkdir /extra-connect-jars /connectors

# Create Landoop configuration directory
RUN mkdir /usr/share/landoop

# Add Confluent Distribution
RUN wget https://packages.confluent.io/archive/3.1/confluent-3.1.1-2.11.tar.gz -O /opt/confluent-3.1.1-2.11.tar.gz \
    && tar --no-same-owner -xzf /opt/confluent-3.1.1-2.11.tar.gz -C /opt/ \
    && rm -rf /opt/confluent-3.1.1-2.11.tar.gz

# # Add Stream Reactor and Elastic Search (for elastic connector)
# ARG STREAM_REACTOR_URL=https://archive.landoop.com/third-party/stream-reactor/stream-reactor-v0.2.2-42-ga4205f5.tar.gz
# RUN wget "${STREAM_REACTOR_URL}" -O stream-reactor.tar.gz \
#     && tar -xzf stream-reactor.tar.gz --no-same-owner --strip-components=1 -C /opt/confluent-3.1.1/share/java \
#     && rm -rf /opt/confluent-3.1.1/share/java/kafka-connect-druid \
#     && rm /stream-reactor.tar.gz \
#     && wget https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/2.4.1/elasticsearch-2.4.1.tar.gz \
#     && tar xf /elasticsearch-2.4.1.tar.gz --no-same-owner \
#     && mv /elasticsearch-2.4.1/lib/*.jar /extra-connect-jars/ \
#     && rm -rf /elasticsearch-2.4.1*

# Create system symlinks to Confluent's binaries
ADD binaries /opt/confluent-3.1.1/bin-install
RUN bash -c 'for i in $(find /opt/confluent-3.1.1/bin-install); do ln -s $i /usr/local/bin/$(echo $i | sed -e "s>.*/>>"); done'

# Configure Confluent
RUN echo "access.control.allow.methods=GET,POST,PUT,DELETE,OPTIONS" >> /opt/confluent-3.1.1/etc/schema-registry/schema-registry.properties \
    && echo 'access.control.allow.origin=*' >> /opt/confluent-3.1.1/etc/schema-registry/schema-registry.properties \
    && echo "access.control.allow.methods=GET,POST,PUT,DELETE,OPTIONS" >> /opt/confluent-3.1.1/etc/kafka-rest/kafka-rest.properties \
    && echo 'access.control.allow.origin=*' >> /opt/confluent-3.1.1/etc/kafka-rest/kafka-rest.properties

# # Add and setup Kafka Manager
# RUN wget https://archive.landoop.com/third-party/kafka-manager/kafka-manager-1.3.2.1.zip \
#          -O /kafka-manager-1.3.2.1.zip \
#     && unzip /kafka-manager-1.3.2.1.zip -d /opt \
#     && rm -rf /kafka-manager-1.3.2.1.zip

# # Add Twitter Connector
# RUN wget https://archive.landoop.com/third-party/kafka-connect-twitter/kafka-connect-twitter-0.1-develop-389e621-jar-with-dependencies.jar \
#          -O /extra-connect-jars/kafka-connect-twitter-0.1-develop-8624fbe-jar-with-dependencies.jar

# Add dumb init
RUN wget https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 -O /usr/local/bin/dumb-init \
    && chmod 0755 /usr/local/bin/dumb-init

# Add Coyote and tests
ADD integration-tests/kafka-tests.yml /usr/share/landoop
ADD integration-tests/smoke-tests.sh /usr/local/bin
RUN wget https://github.com/Landoop/coyote/releases/download/v1.1/coyote-1.1-linux-amd64 -O /usr/local/bin/coyote \
    && chmod +x /usr/local/bin/coyote /usr/local/bin/smoke-tests.sh \
    && mkdir -p /var/www/coyote-tests
ADD integration-tests/index.html integration-tests/results /var/www/coyote-tests/

# Add and Setup Schema-Registry-Ui
RUN wget https://github.com/Landoop/schema-registry-ui/releases/download/v.0.7.1/schema-registry-ui-0.7.1.tar.gz \
         -O /schema-registry-ui.tar.gz \
    && mkdir -p /var/www/schema-registry-ui \
    && tar xzf /schema-registry-ui.tar.gz -C /var/www/schema-registry-ui \
    && rm -f /schema-registry-ui.tar.gz \
    && sed -e 's|KAFKA_REST:.*|  KAFKA_REST: "/api/kafka-rest-proxy",|' \
           -e 's|var KAFKA_REST =.*|var KAFKA_REST = "/api/kafka-rest-proxy";|' \
           -e 's|^\s*var SCHEMA_REGISTRY =.*|  var SCHEMA_REGISTRY = "/api/schema-registry";|' \
           -e 's|^\s*SCHEMA_REGISTRY_UI:.*|  SCHEMA_REGISTRY_UI: "/schema-registry-ui/",|' \
           -e 's|var UI_SCHEMA_REGISTRY =.*|var UI_SCHEMA_REGISTRY = "/schema-registry-ui/";|' \
           -e 's|^\s*urlSchema:.*|      urlSchema: "/schema-registry-ui/"|' \
           -i /var/www/schema-registry-ui/combined.js
## Alternate regexp that also works:
#           -r -e 's|https{0,1}://localhost:8081|../api/schema-registry|g' \
#           -e 's|https{0,1}://localhost:8082|../api/kafka-rest-proxy|g' \
#           -e 's|https{0,1}://schema-registry\.demo\.landoop\.com|../api/schema-registry|g' \
#           -e 's|https{0,1}://kafka-rest-proxy\.demo\.landoop\.com|../api/kafka-rest-proxy|g' \
#           -e 's|https{0,1}://schema-registry-ui\.landoop\.com|/schema-registry-ui/|g' \

# Add and Setup Kafka-Topics-Ui (the regexp is the exactly the same as for schema-registry-ui
RUN wget https://github.com/Landoop/kafka-topics-ui/releases/download/v0.7.3/kafka-topics-ui-0.7.3.tar.gz \
         -O /kafka-topics-ui.tar.gz \
    && mkdir /var/www/kafka-topics-ui \
    && tar xzf /kafka-topics-ui.tar.gz -C /var/www/kafka-topics-ui \
    && rm -f /kafka-topics-ui.tar.gz \
    && sed -e 's|KAFKA_REST:.*|  KAFKA_REST: "/api/kafka-rest-proxy",|' \
           -e 's|var KAFKA_REST =.*|var KAFKA_REST = "/api/kafka-rest-proxy";|' \
           -e 's|^\s*var SCHEMA_REGISTRY =.*|  var SCHEMA_REGISTRY = "/api/schema-registry";|' \
           -e 's|^\s*SCHEMA_REGISTRY_UI:.*|  SCHEMA_REGISTRY_UI: "/schema-registry-ui/",|' \
           -e 's|var UI_SCHEMA_REGISTRY =.*|var UI_SCHEMA_REGISTRY = "/schema-registry-ui/";|' \
           -e 's|^\s*urlSchema:.*|      urlSchema: "/schema-registry-ui/"|' \
           -i /var/www/kafka-topics-ui/combined.js

# Add and Setup Kafka-Connect-UI
RUN wget https://github.com/Landoop/kafka-connect-ui/releases/download/v0.8.0/kafka-connect-ui-0.8.0.tar.gz \
         -O /kafka-connect-ui.tar.gz \
    && mkdir /var/www/kafka-connect-ui \
    && tar xzf /kafka-connect-ui.tar.gz -C /var/www/kafka-connect-ui \
    && rm -f /kafka-connect-ui.tar.gz
COPY web/connect-ui-env.js /var/www/kafka-connect-ui/env.js

# Add and setup Caddy Server
RUN wget 'https://caddyserver.com/download/build?os=linux&arch=amd64&features=' -O /caddy.tgz \
    && mkdir -p /opt/caddy \
    && tar xzf /caddy.tgz -C /opt/caddy \
    && rm -f /caddy.tgz
ADD web/Caddyfile /usr/share/landoop

# Add fast-data-dev UI
COPY web/index.html web/env.js /var/www/
COPY web/img /var/www/img

# Add executables, settings and configuration
ADD extras/supervisord-web-only.conf /usr/share/landoop/
ADD supervisord.conf /etc/supervisord.conf
ADD setup-and-run.sh logs-to-kafka.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup-and-run.sh /usr/local/bin/logs-to-kafka.sh \
    && echo \
         'export PS1="\[\033[1;31m\]\u\[\033[1;33m\]@\[\033[1;34m\]fast-data-dev \[\033[1;36m\]\W\[\033[1;0m\] $ "' \
         > /root/.bashrc

EXPOSE 2181 3030 3031 8081 8082 8083 9092
ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["/usr/local/bin/setup-and-run.sh"]

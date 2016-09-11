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
    && echo "progress = dot:giga" | tee /etc/wgetrc \
    && mkdir /opt \
    && wget https://gitlab.com/andmarios/checkport/uploads/3903dcaeae16cd2d6156213d22f23509/checkport -O /usr/local/bin/checkport \
    && chmod +x /usr/local/bin/checkport \
    && mkdir /connectors

# Create Landoop configuration directory
RUN mkdir /usr/share/landoop

# Add Confluent Distribution and Stream Reactor
RUN wget http://packages.confluent.io/archive/3.0/confluent-3.0.1-2.11.tar.gz -O /opt/confluent-3.0.1-2.11.tar.gz \
    && tar --no-same-owner -xzf /opt/confluent-3.0.1-2.11.tar.gz -C /opt/ \
    && wget https://archive.landoop.com/third-party/stream-reactor/stream-reactor-20160819-cp-3.0.0-4c160a7.tar.gz \
            -O /stream-reactor.tar.gz \
    && tar --no-same-owner -xzf /stream-reactor.tar.gz \
    && wget https://github.com/andmarios/duphard/releases/download/v1.0/duphard -O /duphard \
    && chmod +x /duphard \
    && /duphard -d=0 /opt/confluent-3.0.1/share/java \
    && /duphard -d=0 /stream-reactor \
    && mv /stream-reactor/* /opt/confluent-3.0.1/share/java/ \
    && rm -rf /opt/confluent-3.0.1-2.11.tar.gz /stream-reactor.tar.gz /stream-reactor /duphard

# Create system symlinks to Confluent's binaries
ADD binaries /opt/confluent-3.0.1/bin-install
RUN bash -c 'for i in $(find /opt/confluent-3.0.1/bin-install); do ln -s $i /usr/local/bin/$(echo $i | sed -e "s>.*/>>"); done'

# Configure Confluent
RUN echo "access.control.allow.methods=GET,POST,PUT,DELETE,OPTIONS" >> /opt/confluent-3.0.1/etc/schema-registry/schema-registry.properties \
    && echo 'access.control.allow.origin=*' >> /opt/confluent-3.0.1/etc/schema-registry/schema-registry.properties \
    && echo "access.control.allow.methods=GET,POST,PUT,DELETE,OPTIONS" >> /opt/confluent-3.0.1/etc/kafka-rest/kafka-rest.properties \
    && echo 'access.control.allow.origin=*' >> /opt/confluent-3.0.1/etc/kafka-rest/kafka-rest.properties

# # Add and setup Kafka Manager
# RUN wget https://archive.landoop.com/third-party/kafka-manager/kafka-manager-1.3.1.6.zip \
#          -O /kafka-manager-1.3.1.6.zip \
#     && unzip /kafka-manager-1.3.1.6.zip -d /opt \
#     && rm -rf /kafka-manager-1.3.1.6.zip

# Add Twitter Connector
RUN wget https://archive.landoop.com/third-party/kafka-connect-twitter/kafka-connect-twitter-0.1-develop-8624fbe-jar-with-dependencies.jar \
         -O /connectors/kafka-connect-twitter-0.1-develop-8624fbe-jar-with-dependencies.jar

# Add dumb init
RUN wget https://github.com/Yelp/dumb-init/releases/download/v1.1.3/dumb-init_1.1.3_amd64 -O /usr/local/bin/dumb-init \
    && chmod 0755 /usr/local/bin/dumb-init

# Add Coyote and tests
ADD kafka-tests.yml /usr/share/landoop
ADD smoke-tests.sh /usr/local/bin
RUN wget https://github.com/Landoop/coyote/releases/download/20160819-7432a8e/coyote -O /usr/local/bin/coyote \
    && chmod +x /usr/local/bin/coyote /usr/local/bin/smoke-tests.sh \
    && mkdir -p /var/www/tests
ADD index-tests.html /var/www/tests/index.html

# Add and setup Caddy Server
RUN wget 'https://caddyserver.com/download/build?os=linux&arch=amd64&features=' -O /caddy.tgz \
    && mkdir -p /opt/caddy \
    && tar xzf /caddy.tgz -C /opt/caddy \
    && rm -f /caddy.tgz \
    && mkdir -p /var/www
ADD Caddyfile /usr/share/landoop
ADD index.html /var/www

# Add and Setup Schema-Registry-Ui
RUN wget https://github.com/Landoop/schema-registry-ui/releases/download/0.7/schema-registry-ui-0.7.tar.gz \
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
RUN wget https://github.com/Landoop/kafka-topics-ui/releases/download/v0.7/kafka-topics-ui-0.7.tar.gz \
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

ADD supervisord.conf /etc/supervisord.conf
ADD setup-and-run.sh /usr/local/bin
RUN chmod +x /usr/local/bin/setup-and-run.sh

EXPOSE 2181 3030 3031 8081 8082 8083 9092
ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["/usr/local/bin/setup-and-run.sh"]

FROM centos:7
MAINTAINER Marios Andreopoulos <marios@landoop.com>

# Update, install tooling and some basic setup
RUN sed '/tsflags=nodocs/d' -i /etc/yum.conf && \
    rm -f /etc/rpm/macros.imgcreate && \
    yum install -y epel-release deltarpm wget && \
    echo "progress = dot:giga" | tee /etc/wgetrc && \
    yum install -y \
        curl \
        which \
        tar \
        supervisor \
        java-1.8.0-openjdk-headless

# Create Landoop configuration directory
RUN mkdir /usr/share/landoop

# Add Confluent Distribution
RUN wget http://packages.confluent.io/archive/3.0/confluent-3.0.0-2.11.tar.gz -O /opt/confluent-3.0.0-2.11.tar.gz && \
    tar -xzf /opt/confluent-3.0.0-2.11.tar.gz -C /opt/ && \
    rm -f /opt/confluent-3.0.0-2.11.tar.gz

# Create system symlinks to Confluent's binaries
ADD bin-install /opt/confluent-3.0.0/bin-install
RUN bash -c 'for i in $(find /opt/confluent-3.0.0/bin-install); do ln -s $i /usr/local/bin/$(echo $i | sed -e "s>.*/>>"); done'

# Add dumb init
RUN wget https://github.com/Yelp/dumb-init/releases/download/v1.1.3/dumb-init_1.1.3_amd64 -O /usr/local/bin/dumb-init && \
    chmod 0755 /usr/local/bin/dumb-init

# Add Coyote and tests
ADD kafka-tests.yml /usr/share/landoop
ADD smoke-tests.sh /usr/local/bin
RUN wget https://github.com/Landoop/coyote/releases/download/20160819-7432a8e/coyote -O /usr/local/bin/coyote && \
    chmod +x /usr/local/bin/coyote /usr/local/bin/smoke-tests.sh && \
    mkdir -p /var/www/tests
ADD index-tests.html /var/www/tests/index.html

# Add and setup Caddy Server
RUN wget 'https://caddyserver.com/download/build?os=linux&arch=amd64&features=minify' -O /caddy.tgz && \
    mkdir -p /opt/caddy && \
    tar xzf /caddy.tgz -C /opt/caddy && \
    rm -f /caddy.tgz && \
    mkdir -p /var/www
ADD Caddyfile /usr/share/landoop
ADD index.html /var/www

# Add and Setup Schema-Registry-Ui
RUN wget https://github.com/Landoop/schema-registry-ui/releases/download/v0.6/schema-registry-ui-0.6.tar.gz \
         -O /schema-registry-ui.tar.gz && \
    mkdir -p /var/www/schema-registry-ui && \
    tar xzf /schema-registry-ui.tar.gz -C /var/www/schema-registry-ui && \
    rm -f /schema-registry-ui.tar.gz && \
    sed -e 's|http://localhost:8081|../api/schema-registry|g' \
        -e 's|http://localhost:8082|../api/kafka-rest|g' \
        -i /var/www/schema-registry-ui/combined.js

# Add and Setup Kafka-Topics-Ui
RUN wget https://github.com/Landoop/kafka-topics-ui/releases/download/v0.2/kafka-topics-ui-0.2.tar.gz \
         -O /kafka-topics-ui.tar.gz && \
    mkdir /var/www/kafka-topics-ui && \
    tar xzf /kafka-topics-ui.tar.gz -C /var/www/kafka-topics-ui && \
    rm -f /kafka-topics-ui.tar.gz && \
    sed -e 's|http://localhost:8081|../api/schema-registry|g' \
        -e 's|http://localhost:8082|../api/kafka-rest|g' \
        -i /var/www/kafka-topics-ui/combined.js

# Clean up
RUN yum -y clean all


ADD supervisord.conf /etc/supervisord.conf
EXPOSE 2181 3030 8081 8082 8083 9092
ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

FROM landoop/fast-data-dev
MAINTAINER Marios Andreopoulos <marios@landoop.com>

RUN wget https://archive.landoop.com/third-party/stream-reactor/stream-reactor-20160819-cp-3.0.0-4c160a7.tar.gz \
         -O /stream-reactor.tar.gz \
    && tar -xzf /stream-reactor.tar.gz \
    && mv /stream-reactor/* /opt/confluent-3.0.0/share/java/ \
    && wget https://github.com/andmarios/duphard/releases/download/v1.0/duphard -O /duphard \
    && chmod +x /duphard \
    && /duphard -d=0 /opt/confluent-3.0.0/share/java/ \
    && rm -rf /stream-reactor.tar.gz /stream-reactor /duphard

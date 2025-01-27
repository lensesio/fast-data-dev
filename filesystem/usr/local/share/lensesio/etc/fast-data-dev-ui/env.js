var runningServices = [
  {
    "name" : "Kafka $FDD_KAFKA_VERSION @ Lenses.io's Apache Kafka Distribution",
    "description" : "1× Broker, 1× Schema Registry, 1× Connect Distributed Worker"
  },
  {
    "name" : "Lenses.io Stream Reactor $FDD_STREAM_REACTOR_VERSION",
    "description" : "Source & Sink connectors collection (25+) supporting KCQL"
  },
  {
    "name": "Third Party Connectors",
    "description": "Extra connectors from Debezium"
  }
];

var disabled = [
];

var servicesInfo = [
  {
    "name" : "Kafka Broker",
    "port" : "$BROKER_PORT",
    "jmx"  : "$BROKER_JMX_PORT : JMX",
    "url"  : "localhost"
  },
  {
    "name" : "Kafka Broker SSL 🔒",
    "port" : "$BROKER_SSL_PORT",
    "jmx"  : "$BROKER_JMX_PORT : JMX",
    "url"  : "localhost"
  },
  {
    "name" : "Schema Registry",
    "port" : "$REGISTRY_PORT",
    "jmx"  : "$REGISTRY_JMX_PORT : JMX",
    "url"  : "http://localhost"
  },
  {
    "name" : "Kafka Connect Distributed",
    "port" : "$CONNECT_PORT",
    "jmx"  : "$CONNECT_JMX_PORT : JMX",
    "url"  : "http://localhost"
  },
  {
    "name" : "Web Server",
    "port" : "$WEB_PORT",
    "jmx"  : "",
    "url"  : "http://localhost"
  }
];

var exposedDirectories = [
  {
    "name" : "certificates (truststore and client keystore)",
    "url" : "/certs/",
    ssl_browse
  },
  {
    "name" : "configuration files of running services",
    "url"  : "/config/",
    browseconfigs
  },
  {
    "name" : "control running services",
    "url" : "http://localhost:$SUPERVISORWEB_PORT",
    supervisorweb
  },
  {
    "name" : "log files of running services",
    "url" : "/logs/",
    "enabled" : true
  }
];

var boxInfoNews = [];

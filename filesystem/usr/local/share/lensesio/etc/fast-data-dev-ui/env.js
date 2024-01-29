var runningServices = [
  {
    "name" : "Kafka $FDD_KAFKA_VERSION @ Lenses.io's Apache Kafka Distribution",
    "description" : "1× Broker, 1× Schema Registry, 1× Connect Distributed Worker, 1× REST Proxy, 1× Zookeeper"
  },
  {
    "name" : "Lenses.io Stream Reactor $FDD_STREAM_REACTOR_VERSION",
    "description" : "Source & Sink connectors collection (25+) supporting KCQL"
  },
  {
    "name" : "Lenses.io Schema Registry UI $FDD_SCHEMA_REGISTRY_UI_VERSION",
    "description" : "Create, view, search, edit, validate, evolve & configure Avro schemas"
  },
  {
    "name" : "Lenses.io Kafka Topics UI $FDD_KAFKA_TOPICS_UI_VERSION",
    "description" : "Browse and search topics, inspect data, metadata and configuration"
  },
  {
    "name" : "Lenses.io Kafka Connect UI $FDD_KAFKA_CONNECT_UI_VERSION",
    "description" : "View, create, update and manage connectors"
  },
  {
    "name": "Third Party Connectors",
    "description": "Extra connectors from Confluent, Couchbase, Debezium"
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
    "name" : "Kafka REST Proxy",
    "port" : "$REST_PORT",
    "jmx"  : "$REST_JMX_PORT : JMX",
    "url"  : "http://localhost"
  },
  {
    "name" : "Kafka Connect Distributed",
    "port" : "$CONNECT_PORT",
    "jmx"  : "$CONNECT_JMX_PORT : JMX",
    "url"  : "http://localhost"
  },
  {
    "name" : "ZooKeeper",
    "port" : "$ZK_PORT",
    "jmx"  : "$ZK_JMX_PORT : JMX",
    "url"  : "localhost"
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
    "url" : "/certs",
    ssl_browse
  },
  {
    "name" : "configuration files of running services",
    "url"  : "/config",
    browseconfigs
  },
  {
    "name" : "control running services",
    "url" : "http://localhost:$SUPERVISORWEB_PORT",
    supervisorweb
  },
  {
    "name" : "log files of running services",
    "url" : "/logs",
    "enabled" : true
  }
];

var boxInfoNews = [];

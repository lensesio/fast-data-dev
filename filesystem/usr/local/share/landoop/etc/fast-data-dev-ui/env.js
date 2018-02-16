var runningServices = [
  {
    "name" : "Kafka $KAFKA_VERSION @ Landoop's Apache Kafka Distribution",
    "description" : "1× Broker, 1× Schema Registry, 1× Connect Distributed Worker, 1× REST Proxy, 1× Zookeeper"
  },
  {
    "name" : "Landoop Stream Reactor $STREAM_REACTOR_VERSION",
    "description" : "Source & Sink connectors collection (25+) supporting KCQL"
  },
  {
    "name" : "Landoop Schema Registry UI $SCHEMA_REGISTRY_UI_VERSION",
    "description" : "Create, view, search, edit, validate, evolve & configure Avro schemas"
  },
  {
    "name" : "Landoop Kafka Topics UI $KAFKA_TOPICS_UI_VERSION",
    "description" : "Browse and search topics, inspect data, metadata and configuration"
  },
  {
    "name" : "Landoop Kafka Connect UI $KAFKA_CONNECT_UI_VERSION",
    "description" : "View, create, update and manage connectors"
  },
  {
    "name": "Third Party Connectors",
    "description": "Extra connectors from Confluent, Couchbase, Dbvisit, Debezium"
  }
];

var disabled = [
];

var servicesInfo = [
  {
    "name" : "Kafka Broker",
    "port" : "9092",
    "jmx"  : "9581 : JMX",
    "url"  : "localhost"
  },
  {
    "name" : "Kafka Broker SSL 🔒",
    "port" : "9093",
    "jmx"  : "9581 : JMX",
    "url"  : "localhost"
  },
  {
    "name" : "Schema Registry",
    "port" : "8081",
    "jmx"  : "9582 : JMX",
    "url"  : "http://localhost"
  },
  {
    "name" : "Kafka REST Proxy",
    "port" : "8082",
    "jmx"  : "9583 : JMX",
    "url"  : "http://localhost"
  },
  {
    "name" : "Kafka Connect Distributed",
    "port" : "8083",
    "jmx"  : "9584 : JMX",
    "url"  : "http://localhost"
  },
  {
    "name" : "ZooKeeper",
    "port" : "2181",
    "jmx"  : "9585 : JMX",
    "url"  : "localhost"
  },
  {
    "name" : "Web Server",
    "port" : "3030",
    "jmx"  : "",
    "url"  : "http://localhost"
  }
];

var exposedDirectories = [
  {
    "name" : "running services log files",
    "url" : "/logs",
    "enabled" : "1"
  },
  {
    "name" : "certificates (truststore and client keystore)",
    "url" : "/certs",
    "enabled" : "ssl_browse"
  }
];

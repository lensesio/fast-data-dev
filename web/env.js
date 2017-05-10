var runningServices = [
  {
    "name" : "Confluent OSS v3.0.1 - Kafka v0.10.0.1",
    "description" : "1× Broker, 1× Schema Registry, 1× Connect Distributed Worker, 1× REST Proxy, 1× Zookeeper"
  },
  {
    "name" : "Landoop Schema Registry UI v0.9.0",
    "description" : "Create, view, search, edit, validate, evolve & configure Avro schemas"
  },
  {
    "name" : "Landoop Kafka Topics UI v0.8.3",
    "description" : "Browse and search topics, inspect data, metadata and configuration"
  },
  {
    "name" : "Landoop Kafka Connect UI v0.9.1",
    "description" : "View, create, update and manage connectors"
  },
  {
    "name" : "Datamountaineer Stream Reactor v0.2.5",
    "description" : "Source & Sink connectors collection (20+ in total) supporting KCQL"
  }
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

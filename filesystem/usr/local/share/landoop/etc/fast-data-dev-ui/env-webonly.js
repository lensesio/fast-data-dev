var runningServices = [
  {
    "name" : "Lenses.io Schema Registry UI $FDD_SCHEMA_REGISTRY_UI_VERSION",
    "description" : "Create / view / search / validate / evolve / view history & configure Avro schemas of your Kafka cluster"
  },
  {
    "name" : "Lenses.io Kafka Topics UI $FDD_KAFKA_TOPICS_UI_VERSION",
    "description" : "Browse Kafka topics and understand what's happening on your cluster. Find topics / view topic metadata / browse topic data (kafka messages) / view topic configuration / download data."
  },
  {
    "name" : "Lenses.io Kafka Connect UI $FDD_KAFKA_CONNECT_UI_VERSION",
    "description" : "This is a web tool for Kafka Connect for setting up and managing connectors for multiple connect clusters."
  }
];

var servicesInfo = [
  {
    "name" : "Kafka Broker",
    "port" : "9092",
    "jmx"  : "",
    "url"  : "localhost"
  },
  {
    "name" : "Schema Registry",
    "port" : "8081",
    "jmx"  : "",
    "url"  : "http://localhost"
  },
  {
    "name" : "Kafka REST Proxy",
    "port" : "8082",
    "jmx"  : "",
    "url"  : "http://localhost"
  },
  {
    "name" : "Kafka Connect Distributed",
    "port" : "8083",
    "jmx"  : "",
    "url"  : "http://localhost"
  },
  {
    "name" : "ZooKeeper",
    "port" : "2181",
    "jmx"  : "",
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
    ssl_browse
  }
];

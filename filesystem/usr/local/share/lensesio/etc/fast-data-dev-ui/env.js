var runningServices = [
  {
    "name" : "Lenses $FDD_LENSES_VERSION",
    "description": "A rich, streaming platform and powerful DataOps tool for Apache Kafka."
  },
  {
    "name" : "Kafka $FDD_KAFKA_VERSION @ Lenses.io's Apache Kafka Distribution",
    "description" : "1× Broker, 1× Schema Registry, 1× Connect Distributed Worker, 1× Zookeeper"
  },
  {
    "name" : "Lenses.io Stream Reactor $FDD_STREAM_REACTOR_VERSION",
    "description" : "Source & Sink connectors collection (25+) supporting KCQL"
  },
  {
    "name": "Third Party Connectors",
    "description": "Extra connectors from Confluent, Couchbase, Debezium"
  },
  {
    "name": "ElasticSearch OSS $FDD_ELASTICSEARCH_VERSION",
    "description": "Open Source Search"
  }
];

var disabled = [
];

var servicesInfo = [
  {
    "name" : "Lenses",
    "port" : "$LENSES_PORT",
    "url"  : "localhost"
  },
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
  },
  {
    "name" : "ElasticSearch HTTP Port",
    "port" : "$ELASTICSEARCH_PORT",
    "jmx"  : "",
    "url"  : "http://localhost"
  },
  {
    "name" : "ElasticSearch Transport Port",
    "port" : "$ELASTICSEARCH_TRANSPORT_PORT",
    "jmx"  : "",
    "url"  : "http://localhost"
  }
];

var exposedDirectories = [
  {
    "name" : "SSL certificates",
    "url" : "/fdd/certs",
    ssl_browse
  },
  {
    "name" : "Configuration",
    "url"  : "/fdd/config",
    browseconfigs
  },
  {
    "name" : "Supervisor",
    "url" : "http://localhost:$SUPERVISORWEB_PORT",
    supervisorweb
  },
  {
    "name" : "Logs",
    "url" : "/fdd/logs",
    "enabled" : true
  }
];

var boxInfoNews = [];

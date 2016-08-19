# fast-data-dev #

A docker image for demonstration and development of Kafka related technology.

---

## Basics

If you need zookeeper, kafka broker, schema registry, kafka rest proxy, kafka
connect distributed instances with extra tools, such as web UI's for schema
registry and kafka topic management, extra connectors and integrated testing,
just run:

    docker run -rm -it --net=host landoop/fast-data-dev

That's it. Your broker is at localhost:9092, your kafka-rest at localhost:8082,
your schema-registry at localhost:8081, your connect-distributed at
localhost:8083, your zookeeper at localhost:2181 and at localhost:3030 you will
find web UIs for kafka topics, schema registry and a test report.

Hit control+c and everything is stopped and removed it.

Do you need some kafka console tools? Whilst your Kafka containers is running,
try something like:

    docker run --rm -it --net=host landoop/fast-data-dev kafka-topics --zookeeper localhost:2181 --list

Or enter the container to use the tools as you like:

    docker run --rm -it --net=host landoop/fast-data-dev bash

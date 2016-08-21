# fast-data-dev #

[![Join the chat at https://gitter.im/Landoop/fast-data-dev](https://badges.gitter.im/Landoop/fast-data-dev.svg)](https://gitter.im/Landoop/fast-data-dev?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

A docker image for demonstration and development of Kafka related technology.

---

## Basics

If you need Kafka Broker, ZooKeeper, Schema Registry, Kafka REST Proxy, Kafka
Connect Distributed instances with extra tools, such as Landoop's Web UIs for
Schema Registry and Kafka Topic management, DataMountaineer Connectors and
integrated testing, just run:

    docker run --rm -it --net=host landoop/fast-data-dev

That's it. Your Broker is at <localhost:9092>, your Kafka REST Proxy at
<localhost:8082>, your Schema Registry at <localhost:8081>, your Connect
Distributed at <localhost:8083>, your ZooKeeper at <localhost:2181> and at
<http://localhost:3030> you will find Landoop's Web UIs for Kafka Topics and
Schema Registry, as well as a test report.

Hit control+c and everything is stopped and removed it.

Do you need some kafka console tools? Whilst your Kafka containers is running,
try something like:

    docker run --rm -it --net=host landoop/fast-data-dev kafka-topics --zookeeper localhost:2181 --list

Or enter the container to use the tools as you like:

    docker run --rm -it --net=host landoop/fast-data-dev bash

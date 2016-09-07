# fast-data-dev #

[![](https://images.microbadger.com/badges/image/landoop/fast-data-dev.svg)](http://microbadger.com/images/landoop/fast-data-dev) [![Join the chat at https://gitter.im/Landoop/fast-data-dev](https://badges.gitter.im/Landoop/fast-data-dev.svg)](https://gitter.im/Landoop/fast-data-dev?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

A docker image for demonstration and development of Kafka related technology.

---

## Basics

If you need Kafka Broker, ZooKeeper, Schema Registry, Kafka REST Proxy, Kafka
Connect Distributed instances with extra tools, such as Landoop's Web UIs for
Schema Registry and Kafka Topic management, DataMountaineer Connectors and
integrated testing, just run:

    docker run --rm -it --net=host landoop/fast-data-dev

If you are on Mac OS X, you have to expose the ports instead:

    docker run --rm -it \
               -p 2181:2181 -p 3030:3030 -p 8081:8081 \
               -p 8082:8082 -p 8083:8083 -p 9092:9092 \
               landoop/fast-data-dev

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

### Note

_Fast-data-dev_ isn't thoroughly tested on Mac OS X. Due to not being able
to use `--net=host`, some components may have networking issues. We are
interested in hearing about your experience.

## Advanced

If you have a custom connector you would like to use, you can mount it at
`/connectors`. We've setup the `CLASSPATH` variable for Connect as
`/connectors/*`, so it will use any jar files it will find inside this
directory:

    docker run --rm -it --net=host \
           -v /path/to/my/connector/jar/files:/connectors \
           landoop/fast-data-dev

## FAQ

- Schema Registry UI and Kafka Topics UI need some time to start working.
  
  That is because the services (Schema Registry and Kafka REST Proxy) have
  to start and initialize before the UIs can read data.
- When you start the container, Schema Registry and REST Proxy fail.
  
  This happens because the Broker isn't up yet. It is normal. Supervisord will
  restart them and they will work when Broker is up.
- What resources does this need?
  
  An idle, fresh ran container will need about 1.5GiB of RAM. We spawn 4 JVM
  based apps after all. Once you start working, your mileage will vary. In our
  experience it is Connect that can turn to a memory hog. We set its heap size
  to 1GiB but this may not be enough.
- I want to see some logs.
  
  Every application stores its logs under `/var/log` inside the container.
  If you have your container's ID, or name, you could do something like:
  
      docker exec -it <ID> cat /var/log/broker.log
  
- Fast-data-dev does not start properly, broker fails with:
  > [2016-08-23 15:54:36,772] FATAL [Kafka Server 0], Fatal error during
  > KafkaServer startup. Prepare to shutdown (kafka.server.KafkaServer)
  > java.net.UnknownHostException: [HOSTNAME]: [HOSTNAME]: unknown error
  
  JVM based apps tend to be a bit sensitive to hostname issues.
  Either run the image without `--net=host` and expose all ports
  (2181, 3030, 8081, 8082, 8083, 9092) to the same port at the host, or
  better yet make sure your hostname resolves to the localhost address
  (127.0.0.1). Usually to achieve this, you need to add your hostname (case
  sensitive) at `/etc/hosts` as the first name after 127.0.0.1. E.g:
  
      127.0.0.1 MyHost localhost

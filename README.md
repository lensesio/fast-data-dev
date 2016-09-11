# fast-data-dev #
[![docker](https://img.shields.io/docker/pulls/landoop/fast-data-dev.svg?style=flat)](https://hub.docker.com/r/landoop/fast-data-dev/)
[![](https://images.microbadger.com/badges/image/landoop/fast-data-dev.svg)](http://microbadger.com/images/landoop/fast-data-dev) [![Join the chat at https://gitter.im/Landoop/fast-data-dev](https://badges.gitter.im/Landoop/fast-data-dev.svg)](https://gitter.im/Landoop/fast-data-dev?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Docker image packaging the best Kafka tools available

---

## Basics

If you need 

1. Kafka Broker
2. ZooKeeper
3. Schema Registry
4. Kafka REST Proxy
5. Kafka Connect Distributed
6. Certified DataMountaineer Connectors (ElasticSearch, Cassandra, Redis ..)
6. Landoop's Fast Data Web UIs : schema-registry , kafka-topics , kafka-connect) and 
7. Embedded integration tests with examples

just run:

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
Schema Registry, as well as a [Coyote](https://github.com/landoop/coyote) test report.

> Hit **control+c** to stop and remove everything

Do you need remote access? Then you have one more knob to turn; your machine's
IP address or hostname that other machines can use to access it:

    docker run --rm -it --net=host -e ADV_HOST=<IP> landoop/fast-data-dev

Do you need to execute kafka related console tools? Whilst your Kafka containers is running,
try something like:

    docker run --rm -it --net=host landoop/fast-data-dev kafka-topics --zookeeper localhost:2181 --list

Or enter the container to use any tool as you like:

    docker run --rm -it --net=host landoop/fast-data-dev bash

## Versions

The latest version of this docker image packages: 

+ Confluent 3.0.1
+ Apache Kafka 0.10.0.1
+ DataMountaineer Stream Reactor 0.2
+ Landoop Fast Data Web UIs 0.7

## Advanced

If you have a custom connector you would like to use, you can mount it at folder
`/connectors`. `CLASSPATH` variable for Kafka Connect is set up as
`/connectors/*`, so it will use any jar files it will find inside this
directory:

    docker run --rm -it --net=host \
           -v /path/to/my/connector/jar/files:/connectors \
           landoop/fast-data-dev

## FAQ

- Landoop's Fast Data Web UI tools and integration test requires a few seconds till they fully work.
  
  That is because the services (Schema Registry and Kafka REST Proxy) have
  to start and initialize before the UIs can read data.
- When you start the container, Schema Registry and REST Proxy fail.
  
  This happens because the Broker isn't up yet. It is normal. Supervisord will
  make sure they will work automatically once the Broker starts.
- What resources does this container need?
  
  An idle, fresh container will need about 1.5GiB of RAM. As at least 4 JVM
  applications will be working in it, your mileage will vary. In our
  experience Kafka Connect usually requires a lot of memory. It's heap size is set by default 
  to 1GiB but you'll might need more than that.
 
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

### Troubleshooting

_Fast-data-dev_ isn't thoroughly tested on Mac OS X and/or with remote access
scenarios. Some components may have networking issues in such setups. We are
interested in hearing about your experience.

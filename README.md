# fast-data-dev / kafka-lenses-dev (Lenses Box) #
lensesio/fast-data-dev
[![docker](https://img.shields.io/docker/pulls/landoop/fast-data-dev.svg?style=flat)](https://hub.docker.com/r/landoop/fast-data-dev/)
[![](https://images.microbadger.com/badges/image/landoop/fast-data-dev.svg)](http://microbadger.com/images/landoop/fast-data-dev)

lensesio/box (landoop/kafka-lenses-dev)
[![docker](https://img.shields.io/docker/pulls/landoop/kafka-lenses-dev.svg?style=flat)](https://hub.docker.com/r/landoop/kafka-lenses-dev/)
[![](https://images.microbadger.com/badges/image/landoop/kafka-lenses-dev.svg)](http://microbadger.com/images/landoop/kafka-lenses-dev)

[Join the Slack Lenses.io Community!](https://launchpass.com/lensesio)

[Apache Kafka](http://kafka.apache.org/) docker image for developers; with
Lenses
([lensesio/box](https://hub.docker.com/r/lensesio/box))
or Lenses.io's open source UI tools
([lensesio/fast-data-dev](https://hub.docker.com/r/lensesio/fast-data-dev)). Have
a full fledged Kafka installation up and running in seconds and top it off with
a modern streaming platform (only for kafka-lenses-dev), intuitive UIs and extra
goodies. Also includes Kafka Connect, Schema Registry, Lenses.io's Stream Reactor
25+ Connectors and more.

> View latest **[demo on-line](https://fast-data-dev.demo.landoop.com)** or **[get a free license for Lenses Box](https://lenses.io/downloads/lenses/)**

### Introduction

When you need:

1. **A Kafka distribution** with Apache Kafka, Kafka Connect, Zookeeper, Confluent Schema Registry and REST Proxy
2. **Lenses.io** Lenses or kafka-topics-ui, schema-registry-ui, kafka-connect-ui
3. **Lenses.io** Stream Reactor, 25+ Kafka Connectors to simplify ETL processes
4. Integration testing and examples embedded into the docker

just run:

    docker run --rm --net=host lensesio/fast-data-dev

That's it. Visit <http://localhost:3030> to get into the fast-data-dev environment

<img src="https://storage.googleapis.com/wch/fast-data-dev-ports.png" alt="fast-data-dev web UI screenshot" type="image/png" width="320">

All the service ports are exposed, and can be used from localhost / or within
your IntelliJ.  The kafka broker is exposed by default at port `9092`, zookeeper
at port `2181`, schema registry at `8081`, connect at `8083`.  As an example, to
access the JMX data of the broker run:

    jconsole localhost:9581

If you want to have the services remotely accessible, then you may need to pass
in your machine's IP address or hostname that other machines can use to access
it:

    docker run --rm --net=host -e ADV_HOST=<IP> lensesio/fast-data-dev

> Hit **control+c** to stop and remove everything

<img src="https://storage.googleapis.com/wch/fast-data-dev-ui.png" alt="fast-data-dev web UI screenshot" type="image/png" width="900">

### Mac and Windows users (docker-machine)

Create a VM with 4+GB RAM using Docker Machine:

    docker-machine create --driver virtualbox --virtualbox-memory 4096 lensesio


Run `docker-machine ls` to verify that the Docker Machine is running correctly. The command's output should be similar to:


    $ docker-machine ls
    NAME        ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
    lensesio     *        virtualbox   Running   tcp://192.168.99.100:2376           v17.03.1-ce

Configure your terminal to be able to use the new Docker Machine named lensesio:

    eval $(docker-machine env lensesio)

And run the Kafka Development Environment. Define ports, advertise the hostname and use extra parameters:

    docker run --rm -p 2181:2181 -p 3030:3030 -p 8081-8083:8081-8083 \
           -p 9581-9585:9581-9585 -p 9092:9092 -e ADV_HOST=192.168.99.100 \
           lensesio/fast-data-dev:latest

That's it. Visit <http://192.168.99.100:3030> to get into the fast-data-dev environment

### Run on the Cloud

You may want to quickly run a Kafka instance in GCE or AWS and access it from your local
computer. Fast-data-dev has you covered.

Start a VM in the respective cloud. You can use the OS of your choice, provided it has
a docker package. CoreOS is a nice choice as you get docker out of the box.

Next you have to open the firewall, both for your machines but also *for the VM itself*.
This is important!

Once the firewall is open try:

    docker run -d --net=host -e ADV_HOST=[VM_EXTERNAL_IP] \
               -e RUNNING_SAMPLEDATA=1 lensesio/fast-data-dev

Alternatively just export the ports you need. E.g:

    docker run -d -p 2181:2181 -p 3030:3030 -p 8081-8083:8081-8083 \
               -p 9581-9585:9581-9585 -p 9092:9092 -e ADV_HOST=[VM_EXTERNAL_IP] \
               -e RUNNING_SAMPLEDATA=1 lensesio/fast-data-dev

Enjoy Kafka, Schema Registry, Connect, Lensesio UIs and Stream Reactor.

### Customize execution

Fast-data-dev and kafka-lenses-dev support custom configuration and extra features
via environment variables.

#### fast-data-dev / kafka-lenses-dev advanced configuration

 Optional Parameters                 | Description
------------------------------------ | ------------------------------------------------------------------------------------------------------------
 `CONNECT_HEAP=3G`                   | Configure the maximum (`-Xmx`) heap size allocated to Kafka Connect. Useful when you want to start many connectors.
 `<SERVICE>_PORT=<PORT>`             | Custom port `<PORT>` for service, `0` will disable it. `<SERVICE>` one of `ZK`, `BROKER`, `BROKER_SSL`, `REGISTRY`, `REST`, `CONNECT`.
 `<SERVICE>_JMX_PORT=<PORT>`         | Custom JMX port `<PORT>` for service, `0` will disable it. `<SERVICE>` one of `ZK`, `BROKER`, `BROKER_SSL`, `REGISTRY`, `REST`, `CONNECT`.
 `USER=username`                     | Run in combination with `PASSWORD` to specify the username to use on basic auth.
 `PASSWORD=password`                 | Protect the fast-data-dev UI when running publicly. If `USER` is not set, the default username is `kafka`.
 `KAFKA_CREATE_TOPICS=topic1,topic2` | Creates user-defined topics on startup. Topics are expressed as following: `name:partitions:replicas:cleanup.policy`. E.g `meteo:3:1`
 `SAMPLEDATA=0`                      | Do not create topics with sample avro and json records; (e.g do not create topics `sea_vessel_position_reports`, `reddit_posts`).
 `RUNNING_SAMPLEDATA=1`              | In the sample topics send a continuous (yet very low) flow of messages, so you can develop against live data.
 `RUNTESTS=0`                        | Disable the (coyote) integration tests from running when container starts.
 `FORWARDLOGS=0`                     | Disable running the file source connector that brings broker logs into a Kafka topic.
 `RUN_AS_ROOT=1`                     | Run kafka as `root` user - useful to i.e. test HDFS connector.
 `DISABLE_JMX=1`                     | Disable JMX - enabled by default on ports 9581 - 9585. You may also disable it individually for services.
 `ENABLE_SSL=1`                      | Generate a CA, key-certificate pairs and enable a SSL port on the broker.
 `SSL_EXTRA_HOSTS=IP1,host2`         | If SSL is enabled, extra hostnames and IP addresses to include to the broker certificate.
 `CONNECTORS=<CONNECTOR>[,<CON2>]`   | Explicitly set which connectors* will be enabled. E.g `hbase`, `elastic` (Stream Reactor version)
 `DISABLE=<CONNECTOR>[,<CON2>]`      | Disable one or more connectors*. E.g `hbase`, `elastic` (Stream Reactor version), `elasticsearch` (Confluent version)
 `BROWSECONFIGS=1`                   | Expose service configuration in the UI. Useful to see how Kafka is setup.
 `DEBUG=1`                           | Print stdout and stderr of all processes to container's stdout. Useful for debugging early container exits.
 `SUPERVISORWEB=1`                   | Enable supervisor web interface on port 9001 (adjust via `SUPERVISORWEB_PORT`) in order to control services, run `tail -f`, etc.

*Available connectors are: azure-documentdb, blockchain, bloomberg, cassandra,
coap, druid, elastic, elastic5, ftp, hazelcast, hbase, influxdb, jms, kudu,
mongodb, mqtt, pulsar, redis, rethink, voltdb, couchbase, dbvisitreplicate,
debezium-mongodb, debezium-mysql, debezium-postgres, elasticsearch, hdfs,
jdbc, s3, twitter.

To programmatically get a list, run:

    docker run --rm -it lensesio/fast-data-dev \
           find /opt/landoop/connectors -type d -maxdepth 2 -name "kafka-connect-*"

Optional Parameters (unsupported) | Description
----------------------------------|---------------------------------------------------------------------------------------------------------
`WEB_ONLY=1`                      | Run in combination with `--net=host` and docker will connect to the kafka services running on the local host. Please use our UI docker images instead.
`TOPIC_DELETE=0`                  | Configure whether you can delete topics. By default topics can be deleted. Please use `KAFKA_DELETE_TOPIC_ENABLE=false` instead.


#### Configure Kafka Components

You may configure any Kafka component (broker, schema registry, connect, rest proxy) by converting the configuration option to uppercase, replace dots with underscores and prepend with
`<SERVICE>_`.

As example:

- To set the `log.retention.bytes` for the broker, you would set the environment
  variable `KAFKA_LOG_RETENTION_BYTES=1073741824`.
- To set the `kafkastore.topic` for the schema registry, you would set
  `SCHEMA_REGISTRY_KAFKASTORE_TOPIC=_schemas`.
- To set the `plugin.path` for the connect worker, you would set
  `CONNECT_PLUGIN_PATH=/var/run/connect/connectors/stream-reactor,/var/run/connect/connectors/third-party,/connectors`.
- To set the `schema.registry.url` for the rest proxy, you would set
  `KAFKA_REST_SCHEMA_REGISTRY_URL=http://localhost:8081`.

We also support the variables that set JVM options, such as `KAFKA_OPTS`, `SCHEMA_REGISTRY_JMX_OPTS`, etc.

Lensesio's Kafka Distribution (LKD) supports a few extra flags as well. Since in
the Apache Kafka build, both the broker and the connect worker expect JVM
options at the default `KAFKA_OPTS`, LKD supports using `BROKER_OPTS`, etc for
the broker and `CONNECT_OPTS`, etc for the connect worker. Of course
`KAFKA_OPTS` are still supported and apply to both applications (and the
embedded zookeeper).

Another LKD addition are the `VANILLA_CONNECT`, `SERDE_TOOLS` and
`LANDOOP_COMMON` flags for Kafka Connect.  By default we load into the Connect
Classpath the Schema Registry and Serde Tools by Confluent in order to support
avro and our own base jars in order to support avro and our connectors. You can
choose to run a completely vanilla kafka connect, the same that comes from the
official distribution, without avro support by setting `VANILLA_CONNECT=1`.
Please note that most if not all the connectors will fail to load, so it would
be wise to disable them.  `SERDE_TOOLS=0` will disable Confluent's jars and
`LANDOOP_COMMON=0` will disable our jars. Any of these is enough to support
avro, but disabling `LANDOOP_COMMON` will render Stream Reactor inoperable.

### Versions

The latest version of this docker image tracks our latest stable tag (1.0.1). Our
images include:

 Version                       | Kafka Distro  | Lensesio tools | Apache Kafka  | Connectors
-------------------------------| ------------- | ------------- | ------------- | --------------
lensesio/fast-data-dev:2.3.0   | LKD 2.3.0-L0  |       ✓       |    2.3.0      | 30+ connectors
lensesio/fast-data-dev:2.2.1   | LKD 2.2.1-L0  |       ✓       |    2.2.1      | 30+ connectors
lensesio/fast-data-dev:2.1.1   | LKD 2.1.1-L0  |       ✓       |    2.1.1      | 30+ connectors
lensesio/fast-data-dev:2.0.1   | LKD 2.0.1-L0  |       ✓       |    2.0.1      | 30+ connectors
landoop/fast-data-dev:1.1.1    | LKD 1.1.1-L0  |       ✓       |    1.1.1      | 30+ connectors
landoop/fast-data-dev:1.0.1    | LKD 1.0.1-L0  |       ✓       |    1.0.1      | 30+ connectors
landoop/fast-data-dev:cp3.3.0  | CP 3.3.0 OSS  |       ✓       |    0.11.0.0   | 30+ connectors
landoop/fast-data-dev:cp3.2.2  | CP 3.2.2 OSS  |       ✓       |    0.10.2.1   | 24+ connectors
landoop/fast-data-dev:cp3.1.2  | CP 3.1.2 OSS  |       ✓       |    0.10.1.1   | 20+ connectors
landoop/fast-data-dev:cp3.0.1  | CP 3.0.1 OSS  |       ✓       |    0.10.0.1   | 20+ connectors

*LKD stands for Lenses.io's Kafka Distribution. We build and package Apache Kafka with Kafka Connect
and Apache Zookeeper, Confluent Schema Registry and REST Proxy and a collection of third party
Kafka Connectors as well as our own Stream Reactor collection.

Please note the [BSL license](https://lensesio.com/bsl/) of the tools. To use them on a PROD
cluster with > 3 Kafka nodes, you should contact us.

### Building it

Fast-data-dev/kafka-lenses-dev require a recent version of docker which supports
multistage builds.

To build it just run:

    docker build -t lensesio/fast-data-dev .

Periodically pull from docker hub to refresh your cache.

If you have an older version installed, try the single-stage build at the expense
of the extra size:

    docker build -t lensesio/fast-data-dev -f Dockerfile-singlestage .


### Advanced Features and Settings

#### Custom Ports

To use custom ports for the various services, you can take advantage of the
`ZK_PORT`, `BROKER_PORT`, `REGISTRY_PORT`, `REST_PORT`, `CONNECT_PORT` and
`WEB_PORT` environment variables. One catch is that you can't swap ports; e.g
to assign 8082 (default REST Proxy port) to the brokers.

    docker run --rm -it \
               -p 3181:3181 -p 3040:3040 -p 7081:7081 \
               -p 7082:7082 -p 7083:7083 -p 7092:7092 \
               -e ZK_PORT=3181 -e WEB_PORT=3040 -e REGISTRY_PORT=8081 \
               -e REST_PORT=7082 -e CONNECT_PORT=7083 -e BROKER_PORT=7092 \
               -e ADV_HOST=127.0.0.1 \
               lensesio/fast-data-dev

A port of `0` will disable the service.

#### Execute kafka command line tools

Do you need to execute kafka related console tools? Whilst your Kafka containers is running,
try something like:

    docker run --rm -it --net=host lensesio/fast-data-dev kafka-topics --zookeeper localhost:2181 --list

Or enter the container to use any tool as you like:

    docker run --rm -it --net=host lensesio/fast-data-dev bash

#### View logs

You can view the logs from the web interface. If you prefer the command line,
every application stores its logs under `/var/log` inside the container.
If you have your container's ID, or name, you could do something like:

    docker exec -it <ID> cat /var/log/broker.log

#### Enable SSL on Broker

Do you want to test your application over an authenticated TLS connection to the
broker? We got you covered. Enable TLS via `-e ENABLE_SSL=1`:

    docker run --rm --net=host \
               -e ENABLE_SSL=1 \
               lensesio/fast-data-dev

When fast-data-dev spawns, it will create a self-signed CA. From that it will
create a truststore and two signed key-certificate pairs, one for the broker,
one for your client. You can access the truststore and the client's keystore
from our Web UI, under `/certs` (e.g http://localhost:3030/certs). The password
for both the keystores and the TLS key is `fastdata`.
The SSL port of the broker is `9093`, configurable via the `BROKER_SSL_PORT`
variable.

Here is a simple example of how the SSL functionality can be used. Let's spawn
a fast-data-dev to act as the server:

    docker run --rm --net=host -e ENABLE_SSL=1 -e RUNTESTS=0 lensesio/fast-data-dev

On a new console, run another instance of fast-data-dev only to get access to
Kafka command line utilities and use TLS to connect to the broker of the former
container:

    docker run --rm -it --net=host --entrypoint bash lensesio/fast-data-dev
    root@fast-data-dev / $ wget localhost:3030/certs/truststore.jks
    root@fast-data-dev / $ wget localhost:3030/certs/client.jks
    root@fast-data-dev / $ kafka-producer-perf-test --topic tls_test \
      --throughput 100000 --record-size 1000 --num-records 2000 \
      --producer-props bootstrap.servers="localhost:9093" security.protocol=SSL \
      ssl.keystore.location=client.jks ssl.keystore.password=fastdata \
      ssl.key.password=fastdata ssl.truststore.location=truststore.jks \
      ssl.truststore.password=fastdata

Since the plaintext port is also available, you can test both and find out
which is faster and by how much. ;)


### Advanced Connector settings

#### Explicitly Enable Connectors

The number of connectors present significantly affects Kafka Connect's
startup time, as well as its memory usage. You can enable connectors
explicitly using the `CONNECTORS` environment variable:

    docker run --rm -it --net=host \
               -e CONNECTORS=jdbc,elastic,hbase \
               lensesio/fast-data-dev

Please note that if you don't enable jdbc, some tests will fail.
This doesn't affect fast-data-dev's operation.

#### Explicitly Disable Connectors

Following the same logic as in the paragraph above, you can instead choose to
explicitly disable certain connectors using the `DISABLE` environment
variable. It takes a comma separated list of connector names you want to
disable:

    docker run --rm -it --net=host \
               -e DISABLE=elastic,hbase \
               lensesio/fast-data-dev

If you disable the jdbc connector, some tests will fail to run.

#### Enable additional connectors

If you have a custom connector you would like to use, you can mount it at folder
`/connectors`. `plugin.path` variable for Kafka Connect is set up to include
`/connectors/`, so it will use any single-jar connectors it will find inside this
directory and any multi-jar connectors it will find in subdirectories of this directory.

    docker run --rm -it --net=host \
               -v /path/to/my/connector/connector.jar:/connectors/connector.jar \
               -v /path/to/my/multijar-connector-directory:/connectors/multijar-connector-directory \
               lensesio/fast-data-dev

#### Build Kafka-Connect clusters

*Note:* This feature is deprecated.

If you already have your Kafka brokers and ZKs infrastructure in place and you need
to spin up a few Kafka-Connect clusters, check the [fast-data-connect-cluster](https://github.com/landoop/fast-data-connect-cluster),
a spinoff of fast-data-dev aimed at running many connect clusters concurrently.

In short, you can run a docker Kafka-Connect instance to join the connect-cluster with ID = `01` with:

    docker run -d --net=host \
               -e ID=01 \
               -e BS=broker1:9092,broker2:9092 \
               -e ZK=zk1:2181,zk2:2181 \
               -e SC=http://schema-registry:8081 \
               -e HOST=<IP OR FQDN>
               lensesio/fast-data-dev-connect-cluster

### FAQ

- Lensesio's Fast Data Web UI tools and integration test requires some time
  till they fully work. Especially the tests and Kafka Connect UI will need
  a few minutes.
  
  That is because the services (Kafka, Schema Registry, Kafka Connect, REST Proxy)
  have to start and initialize before the UIs can read data.
- What resources does this container need?
  
  An idle, fresh container will need about 3GiB of RAM. As at least 5 JVM
  applications will be working in it, your mileage will vary. In our
  experience Kafka Connect usually requires a lot of memory. It's heap size is
  set by default to 640MiB but you'll might need more than that.
- Fast-data-dev does not start properly, broker fails with:
  > [2016-08-23 15:54:36,772] FATAL [Kafka Server 0], Fatal error during
  > KafkaServer startup. Prepare to shutdown (kafka.server.KafkaServer)
  > java.net.UnknownHostException: [HOSTNAME]: [HOSTNAME]: unknown error
  
  JVM based apps tend to be a bit sensitive to hostname issues.
  Either run the image without `--net=host` and expose all ports
  (2181, 3030, 8081, 8082, 8083, 9092) to the same port at the host, or
  better yet make sure your hostname resolve to the localhost address
  (127.0.0.1). Usually to achieve this, you need to add your hostname (case
  sensitive) at `/etc/hosts` as the first name after 127.0.0.1. E.g:
  
      127.0.0.1 MyHost localhost

### Detailed configuration options

#### Web Only Mode

*Note:* Web only mode will be deprecated in the future.

This is a special mode only for Linux hosts, where *only* Lensesio's Web UIs
are started and kafka services are expected to be running on the local
machine. It must be run with `--net=host` flag, thus the Linux only
requisite:

    docker run --rm -it --net=host \
               -e WEB_ONLY=true \
               lensesio/fast-data-dev

This is useful if you already have a Kafka cluster and want just the additional Lensesio Fast Data web UI.
_Please note that we provide separate, lightweight docker images for each UI component
and we strongly encourage to use these over fast-data-dev._

#### Connect Heap Size

You can configure Connect's heap size via the environment variable
`CONNECT_HEAP`. The default is `640M`:

    docker run -e CONNECT_HEAP=3G -d lensesio/fast-data-dev

#### Basic Auth (password)

We have included a web server to serve Lensesio UIs and proxy the schema registry
and kafa REST proxy services, in order to share your docker over the web.
If you want some basic protection, pass the `PASSWORD` variable and the web
server will be protected by user `kafka` with your password. If you want to
setup the username too, set the `USER` variable.

     docker run --rm -it -p 3030:3030 \
                -e PASSWORD=password \
                lensesio/fast-data-dev

#### Disable tests

By default this docker runs a set of coyote tests, to ensure that your container
and development environment is all set up. You can disable running the `coyote` tests
using the flag:

    -e RUNTESTS=0

#### Run Kafka as root

In the recent versions of fast-data-dev, we switched to running Kafka as user
`nobody` instead of `root` since it was a bad practice. The old behaviour may
still be desirable, for example on our
[HDFS connector tests](http://coyote.lensesio.com/connect/kafka-connect-hdfs/),
Connect worker needs to run as the root user in order to be able to write to the
HDFS. To switch to the old behaviour, use:

    -e RUN_AS_ROOT=1

#### JMX Metrics

JMX metrics are enabled by default. If you want to disable them for some
reason (e.g you need the ports for other purposes), use the `DISABLE_JMX`
environment variable:

    docker run --rm -it --net=host \
               -e DISABLE_JMX=1 \
               lensesio/fast-data-dev

JMX ports are hardcoded to `9581` for the broker, `9582` for schema registry,
`9583` for REST proxy and `9584` for connect distributed. Zookeeper is exposed
at `9585`.

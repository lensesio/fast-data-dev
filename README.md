# Lenses for Kafka with fast-data-dev #
[![docker](https://img.shields.io/docker/pulls/landoop/kafka-lenses-dev.svg?style=flat)](https://hub.docker.com/r/landoop/kafka-lenses-dev/)
[![](https://images.microbadger.com/badges/image/landoop/kafka-lenses-dev.svg)](http://microbadger.com/images/landoop/kafka-lenses-dev) [![Join the chat at https://gitter.im/Landoop/support](https://badges.gitter.im/Landoop/support.svg)](https://gitter.im/Landoop/support?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Landoop’s [Lenses](https://www.landoop.com/kafka-lenses/) docker image with [fast-data-dev](https://hub.docker.com/r/landoop/fast-data-dev/) technology for fast evaluation!

Besides [Lenses](https://www.landoop.com/kafka-lenses/) we include a full fledged [Kafka](https://kafka.apache.org/) installation ([Confluent OSS](https://www.confluent.io/), with Schema Registry and Kafka Connect), [Lenses SQL Engine](https://www.landoop.com/kafka/kafka-sql/), Landoop’s open-source connector collection [Stream Reactor](https://www.landoop.com/kafka/connectors/) and data generators to experiment with.

[Get your free license now](https://www.landoop.com/downloads/lenses/) and discover how easy streaming can get!

### Quick Run

Once you get your license, run our image with:

    docker run -p 3030:3030 -e LICENSE_URL="[YOUR_LICENSE_URL]" --name=lenses landoop/kafka-lenses-dev

Once the services are loaded (it usually takes 30-45 seconds), visit http://localhost:3030 and login with `admin` / `admin`.
If you are on macOS, depending on how you installed docker, you may have to visit http://192.168.99.100:3030 instead.

Once logged in, you should be greeted by a screen like below.

![lenses screenshot](https://storage.googleapis.com/wch/lenses-1.0.0.png)

When finished, press CTRL+C to turn it off. You can either remove the test environment:

    docker rm lenses

Or use it at a later time, continuing from where you left of:

    docker start -a lenses

Please read the advanced run section, for information on more advanced use cases, like accessing from external kafka clients.


### What is Lenses

Lenses for Apache Kafka is _the_ management platform for streaming data.

It upgrades your Kafka cluster with:

- A powerful interface: live views of your data, topics, schema, connectors, ACLs management and more.
- A scalable SQL engine to implement, test and deploy business logic fast.
- Vital enterprise capabilities such as audits, monitoring and alerts.

It is hard to cover the whole surface of Lenses capabilities in a few lines, if you want to learn more please visit our [website](https://www.landoop.com).


### Advanced run

_Kafka-lense-dev_ is build on our well accepted [fast-data-dev](https://hub.docker.com/r/landoop/fast-data-dev/)


    docker run --rm --net=host -e ADV_HOST=<IP> landoop/fast-data-dev


Create a VM with 6GB RAM using Docker Machine:

```
docker-machine create --driver virtualbox --virtualbox-memory 6000 landoop
```

Run `docker-machine ls` to verify that the Docker Machine is running correctly. The command's output should be similar to:

```
$ docker-machine ls
NAME        ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
landoop     *        virtualbox   Running   tcp://192.168.99.100:2376           v17.03.1-ce
```

Configure your terminal to be able to use the new Docker Machine named landoop:

```
eval $(docker-machine env landoop)
```

And run the Kafka Development Environment. Define ports, advertise the hostname and use extra parameters:

```
docker run --rm -p 2181:2181 -p 3030:3030 -p 8081-8083:8081-8083 \
           -p 9581-9585:9581-9585 -p 9092:9092 -e ADV_HOST=192.168.99.100 \
           landoop/fast-data-dev:latest
```

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
               -e RUNNING_SAMPLEDATA=1 landoop/fast-data-dev

Alternatively just export the ports you need. E.g:

    docker run -d -p 2181:2181 -p 3030:3030 -p 8081-8083:8081-8083 \
               -p 9581-9585:9581-9585 -p 9092:9092 -e ADV_HOST=[VM_EXTERNAL_IP] \
               -e RUNNING_SAMPLEDATA=1 landoop/fast-data-dev

Enjoy Kafka, Schema Registry, Connect, Landoop UIs and Stream Reactor.

### Customize execution

You can further customize the execution of the container with additional flags:

 optional_parameters            | usage
------------------------------- | ------------------------------------------------------------------------------------------------------------
 `WEB_ONLY=1      `             | Run in combination with `--net=host` and docker will connect to the kafka services running on the local host
 `CONNECT_HEAP=3G`              | Configure the heap size allocated to Kafka Connect
 `PASSWORD=password`            | Protect you kafka resources when running publicly with username `kafka` with the password you set
 `USER=username`                | Run in combination with `PASSWORD` to specify the username to use on basic auth
 `RUNTESTS=0`                   | Disable the (coyote) integration tests from running when container starts
 `FORWARDLOGS=0`                | Disable running 5 file source connectors that bring application logs into Kafka topics
 `RUN_AS_ROOT=1`                | Run kafka as `root` user - useful to i.e. test HDFS connector
 `DISABLE_JMX=1`                | Disable JMX - enabled by default on ports 9581 - 9585
 `TOPIC_DELETE=0`               | Configure whether you can delete topics. By default topics can be deleted.
 `<SERVICE>_PORT=<PORT>`        | Custom port `<PORT>` for service, where `<SERVICE>` one of `ZK`, `BROKER`, `BROKER_SSL`, `REGISTRY`, `REST`, `CONNECT`
 `ENABLE_SSL=1`                 | Generate a CA, key-certificate pairs and enable a SSL port on the broker
 `SSL_EXTRA_HOSTS=IP1,host2`    | If SSL is enabled, extra hostnames and IP addresses to include to the broker certificate
 `DISABLE=<CONNECTOR>[,<CON2>]` | Disable one or more connectors. E.g `hbase`, `elastic` (Stream Reactor version), `elasticsearch` (Confluent version)
 `DEBUG=1`                      | Print stdout and stderr of all processes to container's stdout. Useful for debugging early container exits.
 `SAMPLEDATA=0`                 | Do not create `sea_vessel_position_reports`, `nyc_yellow_taxi_trip_data`, `reddit_posts` topics with sample Avro records.
 `RUNNING_SAMPLEDATA=1`         | In the sample topics send a continuous (yet low) flow of messages, so you can develop against live data.

And execute the docker image if needed in `daemon` mode:

    docker run -e CONNECT_HEAP=3G -d landoop/fast-data-dev


#### Execute kafka command line tools

Do you need to execute kafka related console tools? Whilst your Kafka containers is running,
try something like:

    docker run --rm -it --net=host landoop/fast-data-dev kafka-topics --zookeeper localhost:2181 --list

Or enter the container to use any tool as you like:

    docker run --rm -it --net=host landoop/fast-data-dev bash

#### View logs

Every application stores its logs under `/var/log` inside the container.
If you have your container's ID, or name, you could do something like:

    docker exec -it <ID> cat /var/log/broker.log

#### Enable SSL on Broker

Do you want to test your application over an authenticated TLS connection to the
broker? We got you covered. Enable TLS via `-e ENABLE_SSL=1`:

    docker run --rm --net=host \
               -e ENABLE_SSL=1 \
               landoop/fast-data-dev

When fast-data-dev spawns, it will create a self-signed CA. From that it will
create a truststore and two signed key-certificate pairs, one for the broker,
one for your client. You can access the truststore and the client's keystore
from our Web UI, under `/certs` (e.g http://localhost:3030/certs). The password
for both the keystores and the TLS key is `fastdata`.
The SSL port of the broker is `9093`, configurable via the `BROKER_SSL_PORT`
variable.

Here is a simple example of how the SSL functionality can be used. Let's spawn
a fast-data-dev to act as the server:

    docker run --rm --net=host -e ENABLE_SSL=1 -e RUNTESTS=0 landoop/fast-data-dev

On a new console, run another instance of fast-data-dev only to get access to
Kafka command line utilities and use TLS to connect to the broker of the former
container:

    docker run --rm -it --net=host --entrypoint bash landoop/fast-data-dev
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


#### Connect Heap Size

You can configure Connect's heap size via the environment variable
`CONNECT_HEAP`. The default is `1G`:

    docker run -e CONNECT_HEAP=5G -d landoop/fast-data-dev


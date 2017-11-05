# Lenses for Kafka with fast-data-dev #
[![docker](https://img.shields.io/docker/pulls/landoop/kafka-lenses-dev.svg?style=flat)](https://hub.docker.com/r/landoop/kafka-lenses-dev/)
[![](https://images.microbadger.com/badges/image/landoop/kafka-lenses-dev.svg)](http://microbadger.com/images/landoop/kafka-lenses-dev) [![Join the chat at https://gitter.im/Landoop/support](https://badges.gitter.im/Landoop/support.svg)](https://gitter.im/Landoop/support?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Landoop’s [Lenses](https://www.landoop.com/kafka-lenses/) docker image with [fast-data-dev](https://hub.docker.com/r/landoop/fast-data-dev/) technology for fast evaluation!

Besides [Lenses](https://www.landoop.com/kafka-lenses/) we include a full fledged [Kafka](https://kafka.apache.org/) installation ([Confluent OSS](https://www.confluent.io/), with Schema Registry and Kafka Connect), [Lenses SQL Engine](https://www.landoop.com/kafka/kafka-sql/), Landoop’s open-source connector collection [Stream Reactor](https://www.landoop.com/kafka/connectors/) and data generators to experiment with.

[Get your free license now](https://www.landoop.com/downloads/lenses/) and discover how easy streaming can get!

### Quick Run

Once you get your license, run our image with:

    docker run -p 3030:3030 -e LICENSE_URL="[YOUR_LICENSE_URL]" \
               --name=lenses landoop/kafka-lenses-dev

Once the services are loaded (it usually takes 30-45 seconds), visit http://localhost:3030 and login with `admin` / `admin`. If you are on macOS, depending on how you installed docker, you may have to visit http://192.168.99.100:3030 instead.

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


### Requirements

Apart for docker, the only requirement is you have at least 4GB of memory for docker. For Linux machines this is the available free memory in your system. For macOS and Windows this is the amount of memory you assign to docker’s configuration plus some little extra for the docker VMs operating system. Our recommendation is to have at least 5GB of free memory, so that your system's performance won’t suffer. Operating systems tend to get slower when the free RAM approaches zero.

### Advanced run

_Kafka-lenses-dev_ is build on our well accepted [fast-data-dev](https://hub.docker.com/r/landoop/fast-data-dev/) image, which provides a Kafka development environment in one docker image. As such it supports most options of [fast-data-dev](https://github.com/Landoop/fast-data-dev/blob/master/README.md) with the main differences being that we:

1. Include Lenses instead of our Web UIs for Kafka.
2. By default we have the data generators running. You may turn them off by setting the environment variable `SAMPLEDATA=0`.
3. We don't run the [coyote](https://github.com/landoop/coyote) test suite on start.

Let's go quickly over some advanced use cases.

#### Access Kafka from other Clients

Due to the way docker and the kafka broker works, accessing kafka from your own consumer or producer may be tricky. The Kafka Broker advertises a —usually autodetected— address that must be accessible from your client. To complicate things, docker when run on macOS or Windows runs inside a virtual machine, adding an extra networking layer.

If you run docker on macOS or Windows, you may need to find the address of the VM running docker. On macOS it usually is `192.168.99.100` and export it as the advertised address for the broker. At the same time you should give the kafka-lenses-dev image access to the VM's network:

    docker run -p 3030:3030 -e LICENSE_URL="[YOUR_LICENSE_URL]" \
               -e ADV_HOST="192.168.99.100" --net=host --name=lenses \
               landoop/kafka-lenses-dev

If you run on Linux you don't need the `ADV_HOST` but you can do something cool with it. If you set as the `ADV_HOST` your machine’s IP address you will be able to access Kafka from all clients in the network. If you decide to run kafka-lenses-dev in the cloud, you could access Kafka from your local machine. Just remember to provide the public IP of your server!

#### The license file

Developer licenses are free. You can get one —or more— from our [website](https://www.landoop.com). The license will expire in six months unless you renew it —for free. You may start your Lenses instance with a different license file. Your setup will not be affected.

There are three ways to provide the license file. The first we already saw, provide the license url via `LICENSE_URL`:

    -e LICENSE_URL="[LICENSE_URL]"

If you instead choose to save the license file locally, you can either provide it as a file:

    -v /path/to/license.json:/license.conf

Or as an environment variable:

    -e LICENSE="$(cat /path/to/license.json)"

#### Kafka and the command line

You can access the various Kafka command-line tools, such as the console producer and consumer from a terminal in the container:

    docker exec -it lenses bash

Or directly:

    docker exec -it kafka-topics --zookeeper localhost:2181 --list

If you enter the container, you will discover that we even provide bash auto-completion for some of the tools.

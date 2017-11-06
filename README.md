# Lenses for Kafka with fast-data-dev #
[![docker](https://img.shields.io/docker/pulls/landoop/kafka-lenses-dev.svg?style=flat)](https://hub.docker.com/r/landoop/kafka-lenses-dev/)
[![](https://images.microbadger.com/badges/image/landoop/kafka-lenses-dev.svg)](http://microbadger.com/images/landoop/kafka-lenses-dev) [![Join the chat at https://gitter.im/Landoop/support](https://badges.gitter.im/Landoop/support.svg)](https://gitter.im/Landoop/support?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Landoop’s [Lenses](https://www.landoop.com/kafka-lenses/) docker image with [fast-data-dev](https://hub.docker.com/r/landoop/fast-data-dev/) technology for fast evaluation!

Besides [Lenses](https://www.landoop.com/kafka-lenses/) we include a full fledged [Kafka](https://kafka.apache.org/) installation ([Confluent OSS](https://www.confluent.io/), with Schema Registry and Kafka Connect), [Lenses SQL Engine](https://www.landoop.com/kafka/kafka-sql/), Landoop’s open-source connector collection [Stream Reactor](https://www.landoop.com/kafka/connectors/) and data generators to experiment with.

[Get your free license now](https://www.landoop.com/downloads/lenses/) and discover how easy streaming can get!

### Quick Run

Once you get your license, run our image with:

    docker run -p 3030:3030 -e LICENSE_URL="[CHECK_YOUR_EMAIL_FOR_PERSONAL_ID]" \
               --name=lenses landoop/kafka-lenses-dev

Once the services are loaded (it usually takes 30-45 seconds), visit http://localhost:3030 and login with `admin` / `admin`. If you are on macOS, depending on how you installed docker, you may have to visit http://192.168.99.100:3030 instead.

Once logged in, you should be greeted by a screen like below.

![lenses screenshot](https://storage.googleapis.com/wch/lenses-1.0.0.png)

When finished, press CTRL+C to turn it off. You can either remove the test environment:

    docker rm lenses

Or use it at a later time, continuing from where you left of:

    docker start -a lenses

Please read the advanced run section for information on more advanced use cases, like accessing from external kafka clients.


### What is Lenses

Lenses for Apache Kafka is _the_ management platform for streaming data.

It upgrades your Kafka cluster with:

- A powerful interface: live views of your data, topics, schema, connectors, ACLs management and more.
- A scalable SQL engine to implement, test and deploy business logic fast.
- Vital enterprise capabilities such as audits, monitoring and alerts.

### Requirements

Apart from docker, the only requirement is you have at least 4GB of memory available to docker. For Linux machines this is the available free memory in your system. For macOS and Windows this is the amount of memory you assign to docker’s configuration plus some little extra for the docker Virtual Machines’s operating system. Our recommendation is to have at least 5GB of free memory, so that your system's performance won’t suffer. Operating systems tend to get slower when the free RAM approaches zero.

## Quick Start

It is hard to cover the whole surface of Lenses capabilities in a few lines, to learn more please visit our [quickstart documentation](https://www.landoop.com/docs/lenses/lenses/development-environment/latest/).

Hope you will enjoy our product,
The Lenses team.

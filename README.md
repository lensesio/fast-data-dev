# Lenses.io docker for Apache Kafka #

[![slack](https://img.shields.io/badge/Slack-community-red)](https://launchpass.com/lensesio)
[![docker](https://img.shields.io/docker/pulls/lensesio/box.svg?style=flat)](https://hub.docker.com/r/lensesio/box/)
[![](https://images.microbadger.com/badges/image/lensesio/box.svg)](http://microbadger.com/images/lensesio/box)

A docker image for [Apache Kafka and Data Engineers](https://lenses.io/box/).

Includes:

- Apache Kafka v2.5.1
- Kafka Connect and open source collection of [Kafka Connect](https://lenses.io/connect/) connectors
- KStreams via SQL (Lenses SQL)
- Elasticsearch v6.8.7
- Schema Registry

and synthetic generated data for quick experimentation.

### Quick Run

Just run:

    docker run -e ADV_HOST=127.0.0.1 -p 9092:9092 -p 3030:3030 \
               -p 8081:8081 --name=lenses lensesio/box:latest

Then visit `http://localhost:3030` and login with `admin` / `admin`
 
> Notes: If using an old version of Docker you may have to set ADV_HOST to 192.168.99.100
and visit http://192.168.99.100:3030 instead

Once logged in, you should be greeted by a screen like below.

![lenses screenshot](https://help.lenses.io/using-lenses/basics/images/lensesio-dashboard.png)

When finished, press CTRL+C to turn it off. You can either remove the test environment:

    docker rm lenses

Or use it at a later time, continuing from where you left of:

    docker start -a lenses

Please read the advanced section for more configuration options and use cases.

### What is Lenses

Lenses is for the Data Engineer working with  Apache Kafka and streaming data and offers:

- Observability and visibility into events, topics, data pipelines, schemas, acls, quotas, connectors.
- Monitoring, insights and notifications for end-to-end data pipelines.
- A data-centric security model, for secure data policies around sensitive data.
- Integrations for auditing, compliance, authentication and data container systems.

### Requirements

Docker installed, and at least 4GB of memory available to docker.

### Configuration options

For advanced configuration options, refer to [quickstart documentation](https://docs.lenses.io/dev/lenses-box/).

We hope that Data Engineers will enjoy the productivity of this docker,

The Lenses.io team

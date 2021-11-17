# Lenses.io docker for Apache Kafka #

[![slack](https://img.shields.io/badge/Slack-community-red)](https://launchpass.com/lensesio)
[![docker](https://img.shields.io/docker/pulls/lensesio/box.svg?style=flat)](https://hub.docker.com/r/lensesio/box/)
[![](https://images.microbadger.com/badges/image/lensesio/box.svg)](http://microbadger.com/images/lensesio/box)

A docker image for [Apache Kafka and Data Engineers](https://lenses.io/box/).

Includes:

- Apache Kafka v2.5.1
- Kafka Connect and open source collection of [Kafka Connect](https://lenses.io/connect/) connectors
- Schema Registry
- KStreams via SQL ([Lenses SQL](https://lenses.io/product/sql/))
- Elasticsearch v6.8.7
- Supervisor to control the services

and synthetic generated data for quick experimentation.

[Get your free license now](https://lenses.io/box/) and discover how easy streaming can get!

### Quick Run

Just run:

```
    docker run -e ADV_HOST=127.0.0.1 -e EULA="[CHECK_YOUR_EMAIL_FOR_PERSONAL_ID]" \
               -p 3030:3030 -p 9092:9092 -p 2181:2181 -p 8081:8081 --name=lenses lensesio/box:latest
```

Once the services are loaded (it usually takes 30-45 seconds), visit
http://localhost:3030 and login with `admin` / `admin` for full access or
`log` / `viewer` for limited access to certain topics.  If you are on
macOS, depending on how you installed docker, you may have to set ADV_HOST to
192.168.99.100 and visit http://192.168.99.100:3030 instead.

Once logged in, you should be greeted by a screen like below.

![lenses screenshot](https://help.lenses.io/using-lenses/basics/images/lensesio-dashboard.png)

When finished, press CTRL+C to turn it off. You can either remove the test environment:

    docker rm lenses

Or use it at a later time, continuing from where you left of:

    docker start -a lenses

Please read the [advanced section](https://docs.lenses.io/4.2/tools/box/#advanced-options) for more configuration options and use cases, 
or take a look at the [examples](examples/) folder.


### What is Lenses

Lenses is for the Data Engineer working with  Apache Kafka and streaming data and offers:

- Observability and visibility into events, topics, data pipelines, schemas, acls, quotas, connectors.
- Monitoring, insights and notifications for end-to-end data pipelines.
- A data-centric security model, for secure data policies around sensitive data.
- Integrations for auditing, compliance, authentication and data container systems.

### Requirements

Docker installed, and at least 4GB of memory available to docker. 

For Linux machines this is the available free memory in your system. For macOS and Windows this is the amount of memory you assign to docker’s configuration plus some little extra for the docker Virtual Machines’s operating system. Our recommendation is to have at least 5GB of free memory, so that your system's performance won’t suffer. Operating systems tend to get slower when the free RAM approaches zero.

### Configuration options

For advanced configuration options, refer to [quickstart documentation](https://docs.lenses.io/dev/lenses-box/).

We hope that Data Engineers will enjoy the productivity of this docker,

The Lenses.io team
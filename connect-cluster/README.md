# kafka-connect-cluster #

[![Join the chat at https://gitter.im/Landoop/fast-data-dev](https://badges.gitter.im/Landoop/fast-data-dev.svg)](https://gitter.im/Landoop/fast-data-dev?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

A docker image for setting up Kafka Connect clusters.

---

This part of fast-data-dev is targeted to more advanced users and is a special
case since it doesn't set-up a Kafka cluster, instead it expects to find a Kafka
Cluster with Schema Registry up and running.

The developer can then use this docker image to setup a connect-distributed
cluster by just spawning a couple containers.

    docker run -d --net=host \
           -e ID=01 \
           -e BS=broker1:9092,broker2:9092 \
           -e ZK=zk1:2181,zk2:2181 \
           -e SR=http://schema-registry:8081 \
           -e HOST=<IP OR FQDN>
           landoop/fast-data-dev-connect-cluster

For an example take a look in the `docker-compose.yml`.

Things to look out for in configuration options:

1. It is **important** to give a full URL (including schema —`http://`) for schema
registry.
2. `ID` should be unique to the Connect cluster you setup, for current and old
instances. This is because Connect stores data in Brokers and Schema Registry.
Thus even if you destroyed a Connect cluster, its data remain in your Kafka
setup.
3. `HOST` should be set to an IP address or domain name that other connect
   instances and clients can use to reach the current instance. We chose not
   to try to autodetect this IP because such a feat would fail more often than
   not. Good choices are your local network ip (e.g `10.240.0.2`) if you work
   inside a local network, your public ip (if you have one and want to use it)
   or a domain name that is resolvable by all the hosts you will use to talk
   to Connect.

If you don't want to run with `--net=host` you have to expose Connect's port
which at default settings is `8083`.
There a `PORT` option, that allows you to set Connect's port explicitly
if you can't use the default `8083`. Please remember that it is important to
expose Connect's port on the same port at the host. This is a choice we had to
make for simplicity's sake.

    docker run -d \
           -e ID=01 \
           -e BS=broker1:9092,broker2:9092 \
           -e ZK=zk1:2181,zk2:2181 \
           -e SR=http://schema-registry:8081 \
           -e HOST=<IP OR FQDN>
           -e PORT=8085
           -p 8085:8085
           landoop/fast-data-dev-connect-cluster

## Advanced issues

The container does not exit with CTRL+C. This is because we chose to pass
control directly to Connect, so you check your logs via `docker logs`.
You can stop it or kill it from another terminal.

Whilst the `PORT` variable sets the rest.port, the `HOST` variable sets the
advertised host. This is the hostname that Connect will send to other Connect
instances. By default Connect listens to all interfaces, so you don't have
to worry as long as other instances can reach each instance via the advertised
host.

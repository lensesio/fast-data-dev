Lenses Box \- Power of Lenses & Kafka Cluster in one container

Lenses Box is a docker image which contains Lenses and a full installation of Kafka with all its relevant components.
The image packs Landoop’s Stream Reactor Connector collection as well. It’s all pre-setup and the only requirement is having Docker installed.
It contains Lenses, Kafka Broker, Schema Registry, Kafka Connect, 25+ Kafka Connectors with SQL support, CLI tools.

########################
#  Where to find help  #
########################

## Online Documentation
##
The best place to find help is via visiting https://docs.lenses.io/dev/lenses-box/index.html ,
because it is updated with the latest changes and has more information and examples available.

## Local Documentation
##
Documentation in this image:
  man 1 lenses
  man 5 lenses
  man 5 lkd
  man 1 lenses-cli
  man 5 lenses.conf
  man 5 lenses.security.conf

###################################################
#  Viewing logs and configurations from browser   #
###################################################

## Viewing logs
##
Logs can be accessed via http://lenses-box-host:port/fdd/logs/
For example, if you are serving the container via localhost with the default 3030 port, the logs can be accessed via:
  http://localhost:3030/fdd/logs/

## Viewing configurations
##
Configurations can be accessed via http://lenses-box-host:port/fdd/config/
Example with lenses-box-host=localhost and port=3030
  http://localhost:3030/fdd/config/

###################
#  SERVICES PORTS #
###################

## Default Ports
##
Zookeeper                   : 2181        Default JMX: 9584
Web Server                  : 3030        -
Schema Registry             : 8081        Default JMX: 9582
Kafka Connect Distributed   : 8083        Default JMX: 9584
Landoop Lenses              : 9991        -
Kafka Broker                : 9092        Default JMX: 9581

## Publishing ports to host
##
In order to access the above services externally, you must first publish those ports to host,
  Docler example:
    -p 3030:3030      # Webserver
    -p 9092:9092      # Kafka Broker
    ...
    -p 9582:9582      # JMX for Schema Registry
    ...

## Viewing Service Ports for not default entries
##
If you have altered the default entries, please visit fast data dev via http://lenses-box-host:port/fdd/
Example with lenses-box-host=localhost and port=3030
  http://localhost:3030/fdd/

#######################################
#  Configuration files and templates  #
#######################################

Configuration templates with examples:
  /opt/lenses/lenses.conf.sample      # Core configuration file
  /opt/lenses/security.conf.sample    # Security configuration file
  /opt/lenses/logback.xml             # Default log configuration file
  /opt/lenses/logback-debug.xml       # Debug log configuration file

Within lenses.conf.samplle & security.conf.sample you will find many examples which will help you to configure
and run lenses the way you want.

The logback*.xml files are used by lenses to determinate the log verbosity

## Lenses.conf configuration file
##
The configuration file used by lenses lies at
  /run/lenses/lenses.conf

## Security.conf configuration file
##
The security configuration file used by lenses lies at
  /run/lenses/security.conf

## Log configuration file
##
The log configuration file lies at
  /run/lenses/logback.xml

## Change log verbosity
##
To change log verbosity, modify
  /run/lenses/logback.xml and wait about 30 sec for changes to take effect
You can also use the pre-configured logback-debug.xml for debug purposes
  cp /opt/lenses/logback-debug.xml /run/lenses/logback.xml


##########################
#  Viewing logs locally  #
##########################

All log files are under
  /var/log

To view Lenses log, type
  less /var/log/lenses.log
  or tail -f /var/log/lenses.log

###############
#  Structure  #
###############

Structure of the image:
  /usr/local/share/
  /opt/landoop/
  /opt/lenses/
  /opt/caddy/
  /data/
  /run/lenses/
  /run/broker/
  /run/connect/
  /run/schema-registry/
  /run/zookeeper/
  /run/caddy/

########################
#  Services Management #
########################

Services in this image are managed via supervisord

To view currently status of all active services type:

  supervisorctl status

List of services by type:
  Core Services:
    broker
    caddy
    lenses
    connect-distributed
    schema-registry
    zookeeper

  Supplementary Services:
    delayed-message
    financial-tweets
    lenses-processor
    logs-to-kafka
    nullsink
    running-*

To stop or start a services listed from the above command, type:
  supervisorctl stop/start/restart service-name

Supervisord service files

  /etc/supervisord.conf
  /etc/supervisord.d/*.conf

On container start up the above files are actually copied from, therefore if you want to make modifications,
please edit the appropriate file there.

  /usr/local/share/landoop/etc/supervidor.d
  /usr/local/share/landoop/etc/supervisord.templates.d

The supervidord.templates.d hosts the core services which were listed above.

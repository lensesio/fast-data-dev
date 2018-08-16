# Lenses Box with Mongo

An example of the Lenses Dev Box for a usage with mongodb connector only and all the rest connectors disabled.


## Usage

Add in `environment` variables in `docker-compose.yml` your license. Like this:

```
EULA=https://dl.lenses.stream/d/?id=<YOUR-LICENSE-KEY>
```

In order to create a connector add the following config:

```
name=mongo-sink
connector.class=com.datamountaineer.streamreactor.connect.mongodb.sink.MongoSinkConnector
topics=reddit_posts
connect.mongo.db=landoop
connect.mongo.connection=mongodb://mongo:27017
connect.mongo.batch.size=10
connect.mongo.kcql=INSERT INTO orders SELECT * FROM reddit_posts
```

**NOTE:** The config above assumes that you run with sample data which creates also some test topics like `reddit_posts`. You can run with
`SAMPLE_DATA=0` but you need to change the name of the topic to one which you want to use in connector config.
# Lenses Box with Mongo

An example of a setup with Lenses Box, MongoDB and MongoDB Express (UI), for
usage with the MongoDB Stream Reactor connector. We explicitly enable only the
mongo connector, in order to use less memory and startup faster.

## Usage

Edit `docker-compose.yml` to add your developer license link to the `EULA`
_environment variable_. Like this:

    - EULA=https://dl.lenses.stream/d/?id=<YOUR-LICENSE-KEY>

Then just run _docker-compose_. After a minute or so, Lenses should be available
at <http://localhost:3030>.

    docker-compose up

In order to create a MongoDB connector, you may visit
the [connectors tab in Lenses](http://localhost:3030/#/connect) and use the
following config:

```
name=mongo-sink
connector.class=com.datamountaineer.streamreactor.connect.mongodb.sink.MongoSinkConnector
topics=reddit_posts
connect.mongo.db=landoop
connect.mongo.connection=mongodb://mongo:27017
connect.mongo.batch.size=10
connect.mongo.kcql=INSERT INTO posts SELECT author, body AS post, subreddit FROM reddit_posts
```

> **NOTE:** The config above assumes that you run with sample data which creates
> also some test topics like `reddit_posts`. You can run with `SAMPLEDATA=0` but
> you need to change the name of the topic to one which you want to use in
> connector config.

Now you can visit the [Mongo Express UI](http://localhost:8081/db/landoop/posts)
to view your records.

## landoop/fast-data-dev

It should be straightforward to adjust the example for `landoop/fast-data-dev`,
just change the image name in `docker-compose.yml` and
use [Kafka Connect UI](http://localhost:3030/) to create the connector.

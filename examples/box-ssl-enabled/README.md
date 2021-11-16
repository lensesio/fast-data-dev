# Lenses Box with SSL Enabled

Example of enabling Lenses with SSL.

## Usage

To configure the broker to use SSL modify the variable `ENABLE_SSL="true"`, which creates the CA and key-cert pairs and makes the broker listen to SSL://127.0.0.1:9093.

Then, we need to configure lenses to connect to the new url: `LENSES_KAFKA_BROKERS="SSL://127.0.0.1:9093"`.

A more personalized configuration can mean changing the IP. For that, configure `SSL_EXTRA_HOSTS` with an extra IP.

To test this configuration just run:

```bash
docker run -e ADV_HOST=127.0.0.1 \
       -e EULA="https://licenses.lenses.io/d/?id=<PERSONAL_ID>" \
       -e ENABLE_SSL="true" \
       -e LENSES_KAFKA_BROKERS="SSL://localhost:9093" \
       -e LENSES_KAFKA_SETTINGS_CLIENT_SECURITY_PROTOCOL="SSL" \
       -e LENSES_KAFKA_SETTINGS_CLIENT_SSL_PROTOCOL="TLS" \
       -e LENSES_KAFKA_SETTINGS_CLIENT_SSL_TRUSTSTORE_LOCATION="/var/www/certs/truststore.jks" \
       -e LENSES_KAFKA_SETTINGS_CLIENT_SSL_TRUSTSTORE_PASSWORD="fastdata" \
       -e LENSES_KAFKA_SETTINGS_CLIENT_SSL_KEYSTORE_LOCATION="/var/www/certs/client.jks" \
       -e LENSES_KAFKA_SETTINGS_CLIENT_SSL_KEYSTORE_PASSWORD="fastdata" \
       --rm -p 3030:3030 -p 9093:9093 -p 9092:9092 -p 8081:8081 --name=lenses lensesio/box
```

Or run _docker-compose_ inside this folder.

    docker-compose up


After a minute or so, Lenses should be available at <http://localhost:3030>.
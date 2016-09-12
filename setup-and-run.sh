#!/usr/bin/env bash

for port in 2181 3030 8081 8082 8083 9092 29393; do
    if ! /usr/local/bin/checkport -port $port; then
        echo "Could not successfully bind to port $port. Maybe some other service"
        echo "in your system is using it? Please free the port and try again."
        echo "Exiting."
        exit 1
    fi
done


if [[ ! -z "${ADV_HOST}" ]]; then
    echo -e "\e[92mSetting advertised host to \e[96m${ADV_HOST}\e[34m\e[92m.\e[34m".
    echo -e "\nadvertised.listeners=PLAINTEXT://${ADV_HOST}:9092" \
         >> /opt/confluent-3.0.1/etc/kafka/server.properties
    echo -e "\nrest.advertised.host.name=${ADV_HOST}" \
         >> /opt/confluent-3.0.1/etc/kafka/connect-distributed.properties
    sed -e 's#localhost#'"${ADV_HOST}"'#g' -i /usr/share/landoop/kafka-tests.yml
fi

PRINT_HOST="${ADV_HOST:-localhost}"
echo -e "\e[92mStarting services.\e[39m"
echo -e "\e[34mYou may visit \e[96mhttp://${PRINT_HOST}:3030\e[34m in about a minute.\e[39m"

exec /usr/bin/supervisord -c /etc/supervisord.conf

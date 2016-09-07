#!/usr/bin/env bash

for port in 2181 3030 8081 8082 8083 9092 29393; do
    if ! /usr/local/bin/checkport -port $port; then
        echo "Could not succesfully bind to port $port. Maybe some other service"
        echo "in your system is using it? Please free the port and try again."
        echo "Exiting."
        exit 1
    fi
done

echo -e "\e[92mStarting services.\e[39m"
echo -e "\e[34mYou may visit \e[96mhttp://localhost:3030\e[34m in about a minute.\e[39m"

exec /usr/bin/supervisord -c /etc/supervisord.conf

#!/usr/bin/env bash

USER=${USER:-admin}
PASSWORD=${PASSWORD:-admin}

if [[ "${LENSES_PORT}" == "0" ]]; then
    echo "Lenses is disabled. Skipping policy."
    exit 0
fi

lenses-cli \
    --user "${USER}" --pass "${PASSWORD}" --host "http://${GENERATOR_LENSES}" \
    policy create \
    --impact HIGH \
    --name "Credit Card" \
    --redaction Last-4 \
    --fields CreditCardId,cc,creditcard \
    --category PII

lenses-cli \
    --user "${USER}" --pass "${PASSWORD}" --host "http://${GENERATOR_LENSES}" \
    groups create /usr/local/share/landoop/sample-data/group_logviewer.yaml
lenses-cli \
    --user "${USER}" --pass "${PASSWORD}" --host "http://${GENERATOR_LENSES}" \
    users create /usr/local/share/landoop/sample-data/user_logviewer.yaml

# Add data generators as application to Lenses
TOKEN=$(curl -X POST -d '{"user":"'"${USER}"'",  "password":"'"${PASSWORD}"'"}' "http://${GENERATOR_LENSES}/api/login" -H "Content-Type:application/json")
while IFS= read -r; do
    # This double while loop may not be the most clear implementation, but it
    # works for now and it's in a part of the Box that is not critical
    while IFS='|' read -r _APP_NAME _APP_OWNER _APP_TAGS _APP_VERSION _APP_TYPE _APP_DEPLOYMENT _APP_DESC _APP_OUTPUT; do
        curl --silent --compressed --header "X-Kafka-Lenses-Token:${TOKEN}" -H "Content-Type: application/json" "http://${GENERATOR_LENSES}/api/v1/apps/external" -XPOST -d @- <<EOF
{
  "name":"${_APP_NAME}",
  "metadata":
    {
      "owner": "${_APP_OWNER}",
      "tags": [${_APP_TAGS}],
      "version":"${_APP_VERSION}",
      "appType":"${_APP_TYPE}",
      "deployment":"${_APP_DEPLOYMENT}",
      "description":"${_APP_DESC}"
    },
    "input": [],
    "output": [${_APP_OUTPUT}]
}
EOF
    done
done <<EOF
# This comment line need to be here for the code to work :)
ais-receiver|Marios|"demo","ais","gps","avro"|1.0|loop-generator|supervisord unit|AIS sample loop-data generator|{"name":"sea_vessel_position_reports"}
tweets-scraper|Marios|"demo","csv","text"|1.0|loop-generator|supervisord unit|Financial tweets sample loop-data generator|{"name":"financial_tweets"}
trips-feed|Marios|"demo","math","avro"|1.0|loop-generator|supervisord unit|NYC Taxi Trip Data dataset loop generators|{"name":"nyc_yellow_taxi_trip_data"}
telecom-crm|Marios|"demo","table","stream","avro"|1.0|loop-generator|supervisord unit|Telecom Italia data usage sample loop generator. Try do some simple calculations with this dataset and SQL.|{"name":"telecom_italia_grid"},{"name":"telecom_italia_data"}
dc-monitoring|Marios|"demo","monitoring","json"|1.0|loop-generator|supervisord unit|Backblaze's S.M.A.R.T. dataset sample loop generator. Can you find the average temperature of a certain hard disk model via SQL?|{"name":"backblaze_smart"}
payments-processor|Stefan|"demo","payments","joins","table","stream","avro"|1.0|random-generator|supervisord unit|A random generator with a topic of credit card data (use as a table) and a stream of transactions (use as a stream)|{"name":"cc_data"},{"name":"cc_payments"}
EOF

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

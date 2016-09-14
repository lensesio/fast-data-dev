#!/usr/bin/env bash

cd /tmp
cat <<EOF > /var/www/coyote-tests/results
{
  "passed": 0,
  "failed": 0
}
EOF

coyote -c /usr/share/landoop/kafka-tests.yml -out /var/www/coyote-tests/index.html

EXITCODE=$?

PASSED="$(grep -A1 '"label": "passed"' /var/www/coyote-tests/index.html | grep value | sed -re 's/.*"value": ([0-9]*),/\1/')"
FAILED="$(grep -A1 '"label": "failed"' /var/www/coyote-tests/index.html | grep value | sed -re 's/.*"value": ([0-9]*),/\1/')"

cat <<EOF > /var/www/coyote-tests/results
{
  "passed": ${PASSED},
  "failed": ${FAILED}
}
EOF

exit $EXITCODE

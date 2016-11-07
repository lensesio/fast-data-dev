#!/usr/bin/env bash
RUNTESTS="${RUNTESTS:-1}"

if [[ "$RUNTESTS" == "0" ]]; then
    echo "Skipping tests due to \$RUNTESTS = 0."
    cat <<EOF > /var/www/coyote-tests/results
{
  "passed": -1,
  "failed": 0
}
EOF
    exit 0
fi

cd /tmp
cat <<EOF > /var/www/coyote-tests/results
{
  "passed": 0,
  "failed": 0
}
EOF

coyote -c /usr/share/landoop/kafka-tests.yml -out /var/www/coyote-tests/index.html

EXITCODE=$?

TOTALTESTS="$(grep -oE '"TotalTests":[0-9]{1,5},' /var/www/coyote-tests/index.html | sed -r -e 's/.*:([0-9]*),/\1/')"
PASSED="$(expr $TOTALTESTS - $EXITCODE)"
#PASSED="$(grep -A1 '"label": "passed"' /var/www/coyote-tests/index.html | grep value | sed -re 's/.*"value": ([0-9]*),/\1/')"
FAILED="$EXITCODE"
#FAILED="$(grep -A1 '"label": "failed"' /var/www/coyote-tests/index.html | grep value | sed -re 's/.*"value": ([0-9]*),/\1/')"

cat <<EOF > /var/www/coyote-tests/results
{
  "passed": ${PASSED},
  "failed": ${FAILED}
}
EOF

exit $EXITCODE

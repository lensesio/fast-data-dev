#!/usr/bin/env bash
# If WEB_ONLY mode, this is set to 0 in the setup-and-run.sh if not set explicitly.
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

cat <<EOF > /var/www/coyote-tests/results
{
  "passed": 0,
  "failed": 0
}
EOF

/opt/landoop/tools/bin/coyote -c /opt/landoop/tools/share/coyote/examples/simple-integration-tests.yml -out /var/www/coyote-tests/index.html

EXITCODE=$?

TOTALTESTS="$(grep -oE '"TotalTests":[0-9]{1,5},' /var/www/coyote-tests/index.html | sed -r -e 's/.*:([0-9]*),/\1/')"
PASSED="$(( TOTALTESTS - EXITCODE ))"
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

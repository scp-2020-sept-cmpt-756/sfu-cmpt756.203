#!/usr/bin/env bash
# Run Gatling from container
set -o nounset
set -o errexit

if [[ $# -ne 2 ]]
then
  echo "Usage: ${0} USER_COUNT SIM_NAME"
  exit 1
fi

tmpf=$(mktemp)
export CLUSTER_IP=`tools/getip.sh kubectl istio-system svc/istio-ingressgateway`
USERS=${1} SIM_NAME=${2} /opt/gatling/bin/gatling.sh -s proj756.${2} > ${tmpf} &
echo
echo "Control-C to end output when you have seen enough."
echo "To stop the Gatling job, enter"
echo "   $ kill -9 $!"
echo "The Gatling job will continue running until it is stopped via kill -9 or"
echo "the container is exited."
echo
tail -f ${tmpf}

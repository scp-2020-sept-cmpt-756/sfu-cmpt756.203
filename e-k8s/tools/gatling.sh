#!/usr/bin/env bash
# Run Gatling from container
set -o nounset
set -o errexit

if [[ $# -ne 2 ]]
then
  echo "Usage: ${0} USER_COUNT SIM_NAME"
  exit 1
fi

export CLUSTER_IP=`tools/getip.sh kubectl istio-system svc/istio-ingressgateway`
USERS=${1} SIM_NAME=${2} /opt/gatling/bin/gatling.sh -s proj756.${2}

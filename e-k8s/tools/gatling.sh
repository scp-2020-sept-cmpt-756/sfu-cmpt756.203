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
cd tools/gatling
USERS=${1} SIM_NAME=${2} make -e -f Makefile.mak run
# Alternative that was not as good
#USERS=${1} SIM_NAME=${2} make -e -f k8s.mak run-gatling 2>&1 | head -15 &

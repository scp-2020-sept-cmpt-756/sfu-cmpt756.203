#!/usr/bin/env bash
# Wait for a condition to become false on a single pod in namespace 'istio-system'
set -o nounset
set -o errexit
if [[ $# -ne 5 ]]
then
  echo "Must pass five parameters"
  exit 1
fi
while [ "$(kubectl get -n istio-system pods -l ${1} -o jsonpath=${2})" != "${3}" ]
do
    echo "${4} not yet ${5}. Sleeping 1 s"
    sleep 1
done
echo "${4} is ${5}"

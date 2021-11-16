#!/usr/bin/env bash
# Start the CMPT 756 environment
set -o nounset
set -o errexit
if [[ $# -eq 1 ]]
then
  VER=${1}
else
  VER=v1.0beta2-amd64
fi
REGISTRY=ghcr.io
USERID=tedkirkpatrick
docker container run -it --rm \
  -v ${HOME}/.aws:/root/.aws \
  -v ${HOME}/.azure:/root/.azure \
  -v ${HOME}/.ssh:/root/.ssh \
  -v ${HOME}/.kube:/root/.kube \
  -v ${HOME}/.config:/root/.config \
  -v ${PWD}/gatling/results:/opt/gatling/results \
  -v ${PWD}/gatling:/opt/gatling/user-files \
  -v ${PWD}/gatling/target:/opt/gatling/target \
  -v ${PWD}:/home/k8s \
  -e TZ=Canada/Pacific \
  ${REGISTRY}/${USERID}/cmpt-756-tools:${VER}

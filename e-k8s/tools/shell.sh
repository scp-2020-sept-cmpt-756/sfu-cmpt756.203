#!/usr/bin/env bash
# Start the CMPT 756 environment
REGISTRY=ghcr.io
USERID=tedkirkpatrick
VER=v1.0
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

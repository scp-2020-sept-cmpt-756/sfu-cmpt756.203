#!/usr/bin/env bash
set -o nounset
set -o errexit

for c in `docker container ls --format '{{.Names}}' --filter 'label=gatling'`
do
  docker container kill ${c}
done 

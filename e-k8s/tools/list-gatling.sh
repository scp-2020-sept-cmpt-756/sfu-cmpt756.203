#!/usr/bin/env bash
set -o nounset
set -o errexit

printf "%20s  %5s %20s\n" Name Users Script
for c in `docker container ls --format '{{.Names}}' --filter 'label=gatling'`
do
  # BUG in Bash (at least Darwin version) truncates output when left-justifying fields below
  printf "%20s  %5d %20s\n" $c $(docker container exec -t ${c} bash -c 'echo $USERS $SIM_NAME')
done 

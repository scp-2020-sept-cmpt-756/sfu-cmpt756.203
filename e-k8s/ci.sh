#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail
set -o xtrace


# instantiate k8s and docker.mak by supplying your (ghcr.io) container registry id
sed 's/ZZ-REG-ID/overcoil/' k8s-tpl.mak > k8s.mak
sed 's/ZZ-REG-ID/overcoil/' docker-tpl.mak > docker.mak

# setup the image repository
sed 's/ZZ-REG-ID/overcoil/' cluster/s1-tpl.yaml > cluster/s1.yaml
sed 's/ZZ-REG-ID/overcoil/' cluster/s2-tpl.yaml > cluster/s2.yaml
sed 's/ZZ-REG-ID/overcoil/' cluster/db-tpl.yaml > cluster/db1.yaml

# switch to us-west-2 for a standard AWS account; also remove the session token
sed 's/us-east-1/us-west-2/' cluster/db1.yaml > cluster/db2.yaml
sed 's/AWS_SESSION_TOKEN: your-session-token//' cluster/db2.yaml > cluster/db3.yaml
rm cluster/db[12].yaml

# the access key & secret token will be injected via Github Actions

#!/usr/bin/env bash
# Most clusters return an IP address in 'ip' but Amazon EKS returns a hostname in 'hostname'
# Following path selects both; for clusters we have tried, exactly one will be returned
# If we find some cluster that returns both 'ip' and 'hostname', this script can be
# modified to select only one
#
# This simple script is a workaround so that the caller
# does not have to see the single-quotes around the JSON field names.
# The single quotes are required by the JSONPath:
# https://kubernetes.io/docs/reference/kubectl/jsonpath/
# Parameters:
# 1: path to kubectl
# 2: namespace
# 3: the resource to query (typically an svc)
set -o nounset
set -o errexit
${1} get -n ${2} ${3} -o jsonpath="{.status.loadBalancer.ingress[0]['ip','hostname']}"

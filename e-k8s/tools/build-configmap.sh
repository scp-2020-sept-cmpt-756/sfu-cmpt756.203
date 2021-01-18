#!/usr/bin/env bash
# Build ConfigMap definition from a text file and print result on stdout
#
# The output is typically piped into `kubectl apply -f -`
#
# This script takes a header that defines and names the resource.
# The script appends the text file to that header. The appended file
# has four spaces prefixing every line so that it fits the
# YAML indentation requirements.
#
# $1: File to be incorporated into ConfigMap
#   In the resulting CM, each line will be prefixed by 4 spaces so
#   that the YAML parser considers it part of the object
#   defined by the header.
#   All trailing spaces and newlines are preserved.
# $2: File specifying YAML header to precede the data
set -o nounset
set -o errexit
sed -e 's|^|    |' < ${1} | cat ${2} -

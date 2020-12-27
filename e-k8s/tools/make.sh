#!/usr/bin/env bash
# Simple tool to ensure that templates are regenerated before a make
# ${1}: Makefile (not -tpl version) to run
# ${2}: Target in makefil
set -o nounset
make -f k8s-tpl.mak templates
make -f ${1}.mak -e ${2}

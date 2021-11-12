#!/usr/bin/env bash
set -o nounset
set -o errexit
pgrep -f '.*proj756.*' || true

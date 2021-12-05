#!/usr/bin/env bash
#
# Adjust directory permissions to accomodate CSIL's low-permission Docker
#
# Docker in CSIL run as 'nobody'; this script creates the required directories (which are mapped into the
# Gatling container) and crucially, sets the permissions, to allow the container's Scala assets to be built/saved

for c in resources results target target/test-classes target/test-classes/proj756 target/test-classes/computerdatabase
do
  mkdir gatling/${c}
  chmod 777 gatling/${c}
done


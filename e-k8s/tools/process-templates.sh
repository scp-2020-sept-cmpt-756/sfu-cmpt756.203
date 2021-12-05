#!/usr/bin/env bash
#
# Instantiate templates into configuration files
# Most of the work is done in sub-script `call-sed.sh`.
#
# Step 0: Check that necessary tools are in command path
#
function check_command () {
  which ${1} >> /dev/null
  if [[ $? -ne 0 ]]
  then
    echo "Warning: ${1} is not in the search path"
  fi
}
check_command 'kubectl'
check_command 'istioctl'
check_command 'helm'
check_command 'curl'
# AWS command is required for all vendors, to control DynamoDB
check_command 'aws'
#
# Step 1: Strip comments from file listing variables
#
grep -v '^#' ./cluster/tpl-vars.txt > ./cluster/tpl-nocomments.txt
#
# Step 2: Convert the files
# The trailing '' is to compensate for the case where ZZ-AWS-SESSION-TOKEN is empty
# because the user is running DynamoDB under a regular AWS ID.
#
find . -name '*-tpl.*' -exec ./tools/call-sed.sh '{}' $(cut -f 2 -d= ./cluster/tpl-nocomments.txt) '' \;
#
# Step 3: Cleanup
#
/bin/rm -f ./cluster/tpl-nocomments.txt

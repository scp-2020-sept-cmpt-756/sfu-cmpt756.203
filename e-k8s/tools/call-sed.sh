#!/usr/bin/env bash
# Process the template variables for a single file.
# The first argument is the name of the file to process. It must include `-tpl` 
# The remaining arguments must exactly match the order of variable names
# in the `sed` expression below.
#
if [[ $# -lt 9 ]]
then
  echo "call-sed.sh must have at least nine arguments"
  exit 1
fi
#
# Create output file name
#
out=${1/-tpl/}
#
# Replace all the variables
# The official AWS docs (https://docs.aws.amazon.com/IAM/latest/APIReference/API_AccessKey.html) state that Access Key IDs are pure alphanumeric.
# They do not restrict the Secret Access Key in any way but various sites on the Web suggest that it is only alphanumeric+slash+plus
# So it should be delimitable by '|'
sed -e "s|ZZ-CR-ID|${2}|g" -e "s|ZZ-REG-ID|${3}|g" -e "s|ZZ-JAVA-HOME|${4}|g" -e "s|ZZ-GAT-DIR|${5}|g" -e "s|ZZ-AWS-REGION|${6}|g" -e "s|ZZ-AWS-ACCESS-KEY-ID|${7}|g" -e "s|ZZ-AWS-SECRET-ACCESS-KEY|${8}|g" -e "s|ZZ-AWS-SESSION-TOKEN|${9}|g" ${1} > ${out}
# If this is the AWS credentials and there is no session token, delete the line containing AWS_SESSION_TOKEN
if [[ ( "${out/*awscred.yaml/awscred.yaml}" == 'awscred.yaml' ) && ( "${9}" == "" ) ]]
then
  sed -i '' -e '/AWS_SESSION_TOKEN/d' ${out}
fi
